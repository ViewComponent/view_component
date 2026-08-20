# frozen_string_literal: true

require "active_support/dependencies/autoload"
require "action_view/digestor"
require "action_view/render_parser"

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
  # reimplementing static analysis. Components opt in individually by including
  # `ViewComponent::ExperimentallyCacheable`; until at least one component does,
  # every hook here short-circuits.
  #
  # @private
  module CacheDigest
    extend ActiveSupport::Autoload

    autoload :DependencyTracking
    autoload :Resolver

    # Prefix for the synthetic virtual paths components are digested under.
    #
    # Namespaced under `view_component/` so it can't collide with an
    # application partial.
    VIRTUAL_PATH_PREFIX = "view_component/cache_digest"

    # Matches `render FooComponent`, `render(Foo::BarComponent.new(...))`,
    # `render FooComponent.with_collection(...)`, etc.
    #
    # Deliberately a plain source scan rather than a tracker-specific hook: it
    # behaves identically for the ERB tracker, the Prism-based Ruby tracker, and
    # third-party Haml/Slim trackers.
    RENDER_CALL = /
      \brender(?:_to_string)?\b   # render or render_to_string
      \s*\(?\s*                   # optional opening paren
      (?<const>
        (?:::)?[A-Z]\w*           # a constant
        (?:::[A-Z]\w*)*           # optionally namespaced
      )
    /x

    # Rails' escape hatch for dependencies static analysis can't see.
    EXPLICIT_DEPENDENCY = /#\s*Template Dependency:\s*(\S+)/
    class << self
      # Virtual paths of components that have opted into caching, mapped to
      # their class names.
      #
      # Class *names* rather than class objects so the registry survives
      # autoloader reloads without pinning stale constants in memory.
      #
      # @return [Hash{String => String}]
      def registry
        @registry ||= {}
      end

      # @return [Boolean] whether any component has opted in.
      def enabled?
        !registry.empty?
      end

      # @private
      def register(component)
        return unless component.virtual_path && component.name

        registry[component.virtual_path] = component.name
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

      # Scan a template's source for renders of cacheable components.
      #
      # Called for every template Rails digests, so it exits early when the
      # feature is unused.
      #
      # @return [Array<String>] synthetic virtual paths
      def dependencies_in(template)
        return [] unless enabled?

        component_paths_in(template.source)
      end

      # Scan arbitrary source (a template or a component's Ruby file) for
      # renders of cacheable components.
      #
      # @return [Array<String>] synthetic virtual paths
      def component_paths_in(source)
        return [] unless source.is_a?(String) && source.include?("render")

        source.scan(RENDER_CALL).flatten.uniq.filter_map do |constant_name|
          component = constantize_component(constant_name)
          virtual_path_for(component) if component
        end
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
      rescue
        # Never let digest computation break rendering.
        []
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
          [declared, virtual_path_for(component)] if component
        end
      end

      # Compute the digest of a component using Rails' digest tree.
      #
      # @param component [Class] a component that includes `ExperimentallyCacheable`
      # @param finder [ActionView::LookupContext]
      # @param format [Symbol]
      # @return [String]
      def digest(component, finder: default_finder, format: :html)
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
      # Called each time a component includes `ExperimentallyCacheable`. Both
      # steps below are individually idempotent, so no "already installed" flag
      # is kept. Both hooks short-circuit while the registry is empty, so
      # applications that never opt in are unaffected.
      #
      # @private
      def install!
        DependencyTracking.install!

        ActiveSupport.on_load(:action_controller_base) do
          resolver = ViewComponent::CacheDigest::Resolver.instance

          append_view_path(resolver) unless view_paths.include?(resolver)
        end
      end

      private

      # Resolve a constant name to a component that opted into caching.
      #
      # Returns nil for anything else, including constants that don't exist.
      # Autoloading here is safe: the template is about to render this constant
      # anyway.
      def constantize_component(constant_name)
        component = constant_name.safe_constantize
        return unless component.is_a?(Class)
        return unless component.respond_to?(:__vc_cacheable?) && component.__vc_cacheable?

        component
      rescue
        # Never let digest computation break rendering.
        nil
      end
    end

    # Resolved once at load time rather than memoized, so no class-level state
    # is written after boot.
    RENDER_PARSER = resolve_render_parser(ActionView::RenderParser)
  end
end
