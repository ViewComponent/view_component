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
      def find_dependencies(name, template, view_paths = nil)
        dependencies = super
        source = template.source

        # `# Template Dependency: SomeComponent` names a class, which Rails
        # would resolve as a template path and never find. Swap it for the path
        # the component is digested under, so the declaration resolves instead
        # of becoming a missing node.
        CacheDigest.explicit_component_dependencies(source).each do |declared, virtual_path|
          dependencies = dependencies - [declared] + [virtual_path]
        end

        dependencies + CacheDigest.dependencies_in(template)
      rescue => error
        # Falling back to the dependencies Rails found on its own means the
        # component simply isn't tracked, which is the pre-existing behavior.
        CacheDigest.handle_error(error, "tracking component dependencies in #{name}")
        super
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
