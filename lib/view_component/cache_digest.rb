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

    ANALYSES = :view_component_cache_digest_analyses
    private_constant :ANALYSES

    # A render call whose first argument starts with a constant, such as
    # `render FooComponent.new` or `render(Foo::Bar.with_collection(...))`.
    CONSTANT_RENDER = /\brender(?:_to_string)?[\s(]*(?:::)?[A-Z]/

    # Rails' escape hatch for dependencies static analysis can't see.
    EXPLICIT_DEPENDENCY = /#\s*Template Dependency:\s*(\S+)/

    # A constant path made only of constants, such as `Foo` or `::Foo::Bar`,
    # rather than one hanging off an expression, such as `self.class::Bar`.
    CONSTANT_NAME = /\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/

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

      # Compile a template to Ruby with its own handler, so ERB, Haml, Slim and
      # any other template language can be analyzed the same way. Reuses the
      # Ruby compiled at boot, when there is some.
      #
      # @return [String] Ruby source
      def compiled_source(template)
        source = template.source
        Thread.current[COMPILED_SOURCES]&.dig(template.handler, source) || template.handler.call(template, source)
      end

      # Find the components Ruby source references and the partials it
      # renders.
      #
      # Every constant that names a component counts, not only one passed
      # straight to `render`: a component can also be rendered from a method
      # that builds it, from a local variable, or from a slot declared with its
      # class. A component referenced without being rendered only makes the
      # digest change more often than it needs to.
      #
      # Action View's render parser only sees the calls that don't render a
      # component, so it can't infer partials from them.
      #
      # @param source [String] Ruby source
      # @param name [String] virtual path the source is being digested under
      # @return [Array(Array<String>, Array<String>)] synthetic virtual paths of
      #   components and partial virtual paths
      def renders_in(source, name)
        components, other_calls = analyzing(:renders_in, source) do
          program = Prism.parse(source).value
          [component_paths(referenced_components(program)), partition_render_calls(program).last]
        end

        [components, partials_rendered_by(other_calls, name)]
      end

      # Find the components Ruby source renders, along with the partials Action
      # View infers from them.
      #
      # Action View reads `render FooComponent.new` as a dynamic render of a
      # partial named after the last method, inferring `news/new`. Partials also
      # rendered some other way aren't returned.
      #
      # @param source [String] Ruby source
      # @param name [String] virtual path the source is being digested under
      # @return [Array(Array<String>, Array<String>)] synthetic virtual paths of
      #   components and inferred partial virtual paths
      def component_renders_in(source, name)
        components, other_calls = partition_render_calls(Prism.parse(source).value)
        return [[], []] if components.empty?

        [
          component_paths(components.values),
          partials_rendered_by(components.keys, name) - partials_rendered_by(other_calls, name)
        ]
      end

      # Find the components a component's slots render, from the class each
      # slot was declared with: `renders_one :header, HeaderComponent` or
      # `renders_many :items, "ItemComponent"`. Read from the slot definitions
      # rather than from source, since a class named by a string, or by a name
      # relative to the component, resolves against the component at runtime.
      #
      # @param component [Class]
      # @return [Array<String>] synthetic virtual paths of components
      def slot_renders_of(component)
        definitions = component.registered_slots.values.flat_map { |slot| slot[:renderable_hash]&.values || [slot] }

        component_paths(definitions.filter_map { |slot| slot_component(component, slot) })
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

      # Analyze each component and each source once while the block runs.
      #
      # A digest tree reaches a component once for every component that renders
      # it, and every component reads the same superclasses and included
      # modules, so a tree would otherwise analyze the same source many times.
      # Nothing on disk changes while one tree is built. Kept in a thread local
      # for the same reason as `retaining_compiled_sources`.
      #
      # @private
      def analyzing_once
        return yield if Thread.current[ANALYSES]

        begin
          Thread.current[ANALYSES] = {}
          yield
        ensure
          Thread.current[ANALYSES] = nil
        end
      end

      # The block's result, computed once per key inside `analyzing_once`.
      #
      # @private
      def analyzing(*key)
        analyses = Thread.current[ANALYSES]
        return yield unless analyses

        analyses.fetch(key) { analyses[key] = yield }
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

        analyzing_once do
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
      end

      private

      # Receiverless `render` and `render_to_string` calls, split into those
      # that render a component and the rest.
      #
      # @return [Array(Hash{Prism::CallNode => Class}, Array<Prism::CallNode>)]
      def partition_render_calls(program)
        components = {}
        other_calls = []

        each_node(program) do |node|
          next unless node.is_a?(Prism::CallNode) && node.receiver.nil? && RENDER_METHODS.include?(node.name)

          if (component = rendered_component(node))
            components[node] = component
          else
            other_calls << node
          end
        end

        [components, other_calls]
      end

      # The components the constants in a program name, in source order. Every
      # namespace of a constant path is tried too, so `FooComponent::SIZES`
      # counts `FooComponent`.
      #
      # @return [Array<Class>]
      def referenced_components(program)
        names = []

        each_node(program) do |node|
          next unless node.is_a?(Prism::ConstantReadNode) || node.is_a?(Prism::ConstantPathNode)

          name = node.slice
          names << name if CONSTANT_NAME.match?(name)
        end

        names.uniq.filter_map { |name| constantize_component(name) }.uniq
      end

      # Visit every node of a Prism tree, in source order.
      def each_node(program)
        nodes = [program]
        while (node = nodes.pop)
          yield node
          nodes.concat(node.compact_child_nodes.reverse!)
        end
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

      def component_paths(components)
        components.uniq.filter_map { |component| registered_path_for(component) }
      end

      # The component a slot renders, resolving a class name the way the slot
      # does when it's set. A name that doesn't resolve is left to fail there.
      def slot_component(component, slot)
        renderable = slot[:renderable]
        name = slot[:renderable_class_name]
        renderable ||= component.const_get(name) if name && component.const_defined?(name)

        renderable if renderable.is_a?(Class) && renderable < ViewComponent::Base
      end

      # Partials Action View's render parser finds in the given calls,
      # normalized to the form its trackers report. The calls are parsed
      # together, so the parser runs once rather than once per call. Blocks are
      # left out, as any renders inside them are calls of their own.
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
