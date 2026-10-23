# frozen_string_literal: true

require "active_support/dependencies/autoload"
require "action_view/digestor"
require "action_view/render_parser"
require "prism"

module ViewComponent
  # Integrates ViewComponents into Rails' template digest tree.
  #
  # Rails computes a digest for every template from its source and the templates
  # it renders. That digest is mixed into the key of every `<% cache %>` block in
  # the template, so editing a partial busts the caches of everything that
  # renders it.
  #
  # Components are invisible to that mechanism for two reasons:
  #
  # 1. **Discovery** — `ActionView::DependencyTracker` doesn't recognize
  #    `render SomeComponent.new(...)` as a dependency.
  # 2. **Resolution** — component templates live outside the view paths, and a
  #    component's rendered output depends on its Ruby class and sidecar files,
  #    not just its template.
  #
  # This module fixes both, reusing Rails' own `ActionView::Digestor` rather than
  # reimplementing static analysis. Every discovered component is tracked
  # automatically, independently of output caching.
  #
  # @private
  module CacheDigest
    extend ActiveSupport::Autoload

    autoload :DependencyTracking
    autoload :DigestorLookup
    autoload :Resolver

    # Prefix for the synthetic virtual paths components are digested under.
    #
    # Namespaced under `view_component/` so it can't collide with an
    # application partial.
    VIRTUAL_PATH_PREFIX = "view_component/cache_digest"

    RENDER_METHODS = %i[render render_to_string].freeze

    COMPILED_SOURCES = :view_component_cache_digest_compiled_sources
    private_constant :COMPILED_SOURCES

    # A render call whose first argument starts with a constant, such as
    # `render FooComponent.new` or `render(Foo::Bar.with_collection(...))`.
    CONSTANT_RENDER = /\brender(?:_to_string)?[\s(]*(?:::)?[A-Z]/

    # Rails' escape hatch for dependencies static analysis can't see.
    EXPLICIT_DEPENDENCY = /#\s*Template Dependency:\s*(\S+)/
    class << self
      # Virtual paths of components, mapped to their class names.
      #
      # Class *names* rather than class objects so the registry survives
      # autoloader reloads without pinning stale constants in memory.
      #
      # @return [Hash{String => String}]
      def registry
        @registry ||= {}
      end

      # @private
      def register(component)
        return unless component.virtual_path && component.name
        return if registry[component.virtual_path] == component.name

        registry[component.virtual_path] = component.name

        # Components register as they load, and under lazy loading that happens
        # after Action View has already digested and memoized some templates.
        # Those digests were computed without this component's dependencies and
        # would otherwise be served for the rest of the process, making the
        # digest a function of load order rather than of source.
        expire_digests
      end

      # The synthetic virtual path a component is digested under.
      #
      # @return [String, nil]
      def virtual_path_for(component)
        return unless component.respond_to?(:virtual_path) && component.virtual_path

        "#{VIRTUAL_PATH_PREFIX}/#{component.virtual_path}"
      end

      # Resolve a synthetic virtual path back to the component that owns it.
      #
      # @return [Class, nil]
      def component_for(virtual_path)
        return unless virtual_path.start_with?("#{VIRTUAL_PATH_PREFIX}/")

        name = registry[virtual_path.delete_prefix("#{VIRTUAL_PATH_PREFIX}/")]
        return unless name

        constantize_component(name)
      end

      # Find renders of components in a template.
      #
      # @return [Array<String>] synthetic virtual paths
      def dependencies_in(template)
        component_paths_in(compiled_source(template))
      end

      # Compile a template to Ruby with its own handler, so ERB, Haml, Slim and
      # any other template language can be analyzed the same way.
      #
      # Templates without a constant rendered are skipped, as compiling and
      # parsing them can't find a component.
      #
      # @return [String] Ruby source
      def compiled_source(template, source = template.source)
        return "" unless CONSTANT_RENDER.match?(source)

        template.handler.call(template, source)
      end

      # Find renders of components in Ruby source.
      #
      # @param source [String] Ruby source
      # @return [Array<String>] synthetic virtual paths
      def component_paths_in(source)
        render_calls_in(source).filter_map { |call| registered_path_for(rendered_component(call)) }.uniq
      end

      # Find renders of components in Ruby source, along with the partials
      # Action View infers from them.
      #
      # Action View reads `render FooComponent.new` as a dynamic render of a
      # partial named after the last method, inferring `news/new`. Partials also
      # rendered some other way aren't returned.
      #
      # @param source [String] Ruby source
      # @param name [String] virtual path the source is being digested under
      # @return [Array(Array<String>, Array<String>)] synthetic virtual paths
      #   and inferred partial virtual paths
      def component_renders_in(source, name)
        components = {}
        other_calls = []
        render_calls_in(source).each do |call|
          if (component = rendered_component(call))
            components[call] = component
          else
            other_calls << call
          end
        end
        return [[], []] if components.empty?

        [
          components.values.uniq.filter_map { |component| registered_path_for(component) },
          inferred_partials(components.keys, name) - inferred_partials(other_calls, name)
        ]
      end

      # Find everything a template renders: components, as the synthetic
      # virtual paths they're digested under, and partials, as Action View's
      # trackers would report them. The template is compiled and parsed once,
      # and Action View's render parser only sees the calls that don't render
      # a component, so it can't infer partials from them.
      #
      # @param template [ActionView::Template]
      # @param name [String] virtual path the template is being digested under
      # @return [Array<String>] virtual paths
      def template_dependencies_in(template, name)
        source = template.source
        return [] unless source.include?("render")

        components = []
        other_calls = []
        compiled_source = Thread.current[COMPILED_SOURCES]&.dig(template.handler, source) ||
          template.handler.call(template, source)
        render_calls_in(compiled_source).each do |call|
          if (component = rendered_component(call))
            components << component
          else
            other_calls << call
          end
        end

        components.uniq.filter_map { |component| registered_path_for(component) } |
          partials_rendered_by(other_calls, name)
      end

      # Scan a component's Ruby source for partials referenced by string path,
      # such as `render "posts/byline"` inside a `#call` method.
      #
      # Uses Rails' own render parser — the same one `RubyTracker` runs over
      # compiled templates — rather than a second implementation of the same
      # analysis. Its results are then narrowed to paths that appear verbatim in
      # the source, which keeps string literals and discards the speculative
      # `things/_thing` entries the parser infers from dynamic renders like
      # `render @thing` or `render FooComponent.new`. Those would resolve to
      # nothing and only add log noise; components rendered from Ruby are
      # already found precisely by `component_paths_in`.
      #
      # @param source [String] Ruby source
      # @param name [String] virtual path the source is being digested under
      # @return [Array<String>] partial virtual paths
      def partial_paths_in(source, name)
        return [] unless source.is_a?(String) && source.include?("render")

        RENDER_PARSER.new(name, source).render_calls.uniq.select do |path|
          source.include?(path) || source.include?(path.sub(%r{(\A|/)_}, '\1'))
        end
      end

      # Action View has shipped its render parser as a class (Rails 7.1, and
      # again on main) and as a module holding a `Default` implementation
      # chosen from Prism or Ripper (Rails 7.2 through 8.1).
      #
      # @param parser [Class, Module] `ActionView::RenderParser`
      # @return [Class]
      def resolve_render_parser(parser)
        parser.is_a?(Class) ? parser : parser::Default
      end

      # Resolve `# Template Dependency: SomeComponent` declarations.
      #
      # Rails' escape hatch takes a template path, but the path a component is
      # digested under is an internal detail. Naming the class instead keeps
      # that detail out of application code, so `SomeComponent` is translated
      # to the path the Digestor can resolve.
      #
      # @return [Array<Array(String, String)>] pairs of declared name and
      #   synthetic virtual path
      def explicit_component_dependencies(source)
        return [] unless source.is_a?(String) && source.include?("Template Dependency:")

        source.scan(EXPLICIT_DEPENDENCY).flatten.uniq.filter_map do |declared|
          next unless /\A(?:::)?[A-Z]/.match?(declared)

          component = constantize_component(declared)
          virtual_path = registered_path_for(component)
          [declared, virtual_path] if virtual_path
        end
      end

      # Compute the digest of a component using Rails' digest tree.
      #
      # @param component [Class] a component class
      # @param finder [ActionView::LookupContext]
      # @param format [Symbol]
      # @return [String]
      def digest(component, finder: default_finder, format: :html)
        register(component)
        virtual_path = virtual_path_for(component)
        return "" unless virtual_path

        ActionView::Digestor.digest(name: virtual_path, format: format, finder: finder)
      end

      # A lookup context for digesting components outside a request, where no
      # view context (and therefore no finder) exists.
      #
      # @return [ActionView::LookupContext]
      def default_finder
        # Not memoized across reloads: view paths change when the app reloads.
        ActionView::LookupContext.new(ActionController::Base.view_paths)
      end

      # Wire the tracker and resolver into Action View.
      #
      # Installed during engine initialization. Both steps are idempotent.
      #
      # @private
      def install!
        DependencyTracking.install!
        DigestorLookup.install!
      end

      # Keep the Ruby that templates compile to while the block runs, so
      # `precompute!` can analyze templates components just compiled without
      # compiling them again. Kept in a thread local rather than on the module,
      # which isn't writable from other Ractors.
      #
      # @private
      def retaining_compiled_sources
        Thread.current[COMPILED_SOURCES] = {}
        yield
      ensure
        Thread.current[COMPILED_SOURCES] = nil
      end

      # @private
      def compiled(handler, source, compiled_source)
        sources = Thread.current[COMPILED_SOURCES]
        (sources[handler] ||= {})[source] = compiled_source if sources
      end

      # Compute component digests at boot, so requests read them from memory
      # instead of reading and scanning source files.
      #
      # Only safe when templates are cached at boot: the precomputed sources are
      # never refreshed.
      #
      # @param components [Array<Class>]
      # @return [void]
      # @private
      def precompute!(components)
        # Register everything first: a registration expires every memoized
        # digest, so registering midway would discard digests already warmed.
        components.each { |component| register(component) }

        components.each do |component|
          component.__vc_cache_digest_source = Resolver.instance.source_for(component).freeze
        end

        # Warms the same digest cache requests read, since a lookup context's
        # cache is shared by every context with the same details.
        components.each do |component|
          component.__vc_template_formats.each do |format|
            finder = ActionView::LookupContext.new(ActionController::Base.view_paths, formats: [format])
            component.cache_digest(finder: finder, format: format)
          end
        end
      end

      private

      # Every receiverless `render` and `render_to_string` call, in source order.
      #
      # @return [Array<Prism::CallNode>]
      def render_calls_in(source)
        return [] unless source.is_a?(String) && source.include?("render")

        calls = []
        nodes = [Prism.parse(source).value]
        while (node = nodes.pop)
          if node.is_a?(Prism::CallNode) && node.receiver.nil? && RENDER_METHODS.include?(node.name)
            calls << node
          end
          nodes.concat(node.compact_child_nodes)
        end

        calls.sort_by { |call| call.location.start_offset }
      end

      # The component a render call renders, from the constant at the root of
      # its first argument: `FooComponent`, `FooComponent.new(...)`,
      # `FooComponent.with_collection(...)`, and so on.
      #
      # @return [Class, nil]
      def rendered_component(call)
        node = call.arguments&.arguments&.first
        node = node.receiver while node.is_a?(Prism::CallNode) && node.receiver

        case node
        when Prism::ConstantReadNode, Prism::ConstantPathNode
          constantize_component(node.slice)
        end
      end

      # Partials Action View's render parser finds in the given calls,
      # normalized to the form its trackers report. The calls are parsed
      # together, so the parser runs once rather than once per call.
      def inferred_partials(calls, name)
        return [] if calls.empty?

        RENDER_PARSER.new(name, calls.map(&:slice).join("\n")).render_calls
          .map { |path| path.gsub(%r{/_}, "/") }
          .uniq
      end

      # Partials Action View's render parser finds in the given calls. Blocks
      # are left out, as any renders inside them are calls of their own.
      def partials_rendered_by(calls, name)
        return [] if calls.empty?

        source = calls.map { |call| "#{call.name}(#{call.arguments&.slice})" }.join("\n")
        RENDER_PARSER.new(name, source).render_calls
          .map { |path| path.gsub(%r{/_}, "/") }
          .uniq
      end

      # Record the actual class name rather than trying to reverse a virtual
      # path, which may contain acronyms or be overridden by the component.
      def registered_path_for(component)
        return unless component

        register(component)
        virtual_path_for(component)
      end

      # Drop Action View's memoized template digests, leaving its resolver
      # caches alone: no template changed, only the set of dependencies the
      # Digestor can see.
      def expire_digests
        ActionView::LookupContext::DetailsKey.digest_caches.each(&:clear)
      end

      # Resolve a constant name to any ViewComponent.
      #
      # Returns nil for anything else, including constants that don't exist.
      # Autoloading here is safe: the template is about to render this constant
      # anyway.
      def constantize_component(constant_name)
        component = constant_name.safe_constantize
        return unless component.is_a?(Class) && component < ViewComponent::Base

        component
      end
    end

    # Resolved once at load time rather than memoized, so no class-level state
    # is written after boot.
    RENDER_PARSER = resolve_render_parser(ActionView::RenderParser)
  end
end
