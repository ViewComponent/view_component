# frozen_string_literal: true

require "action_view/dependency_tracker"

module ViewComponent
  module CacheDigest
    # Teaches `ActionView::DependencyTracker` to see components.
    #
    # Prepended to the tracker's singleton class rather than to a specific
    # tracker implementation (`ERBTracker`, `RubyTracker`, or the trackers
    # registered by the Haml and Slim gems). `find_dependencies` is the single
    # seam every tracker flows through, so hooking it here works regardless of
    # which handler a template uses and doesn't depend on tracker internals.
    #
    # @private
    module DependencyTracking
      # Templates are memoized during a digest, so a template reached along
      # many edges of the tree is scanned once.
      def find_dependencies(name, template, view_paths = nil)
        CacheDigest.memoize([:dependencies, name, template, view_paths]) do
          dependencies = super
          source = template.source

          # Synthetic templates already declare every dependency found in their
          # sources, as paths.
          next dependencies if name.start_with?("#{CacheDigest::VIRTUAL_PATH_PREFIX}/")

          # `# Template Dependency: SomeComponent` names a class, which Rails
          # would resolve as a template path and never find. Swap it for the path
          # the component is digested under, so the declaration resolves instead
          # of becoming a missing node.
          CacheDigest.explicit_component_dependencies(source).each do |declared, virtual_path|
            dependencies = dependencies - [declared] + [virtual_path]
          end

          next dependencies unless CacheDigest.template_dependencies?(source, template.handler)

          # ERB's regex tracker guesses different paths than the Ruby parser,
          # especially for namespaced components. Ask the registered tracker
          # about isolated render calls without reentering this extension.
          if template.handler.is_a?(ActionView::Template::Handlers::ERB)
            tracker = lambda do |calls|
              isolated = ActionView::Template.new(
                calls.map { |call| "<% #{call} %>" }.join("\n"),
                template.identifier,
                template.handler,
                locals: [],
                virtual_path: name
              )
              super(name, isolated, view_paths)
            end
          end

          component_paths, inferred_partials =
            CacheDigest.template_renders_in(CacheDigest.compiled_source(template), name, view_paths: view_paths, &tracker)
          # Older ERB trackers omit the underscore on unqualified partial paths.
          inferred_partials |= inferred_partials.map { |path| path.delete_prefix("_") }
          declared = source.scan(CacheDigest::EXPLICIT_DEPENDENCY).flatten

          (dependencies - (inferred_partials - declared) + component_paths).uniq
        end
      end

      # @private
      def self.install!
        tracker = ActionView::DependencyTracker.singleton_class
        return if tracker.include?(self)

        tracker.prepend(self)
      end
    end
  end
end
