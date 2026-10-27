# frozen_string_literal: true

require "action_view/digestor"

module ViewComponent
  module CacheDigest
    # Lets `ActionView::Digestor` find the synthetic templates `Resolver` builds.
    #
    # Prepended to the Digestor's singleton class rather than appending
    # `Resolver` to the application's view paths, so the resolver is only ever
    # consulted while digesting. Code that walks `view_paths` and expects every
    # entry to be a file system resolver is unaffected.
    #
    # @private
    module DigestorLookup
      # @private
      def self.install!
        digestor = ActionView::Digestor.singleton_class
        return if digestor.include?(self)

        digestor.prepend(self)
      end

      # Build the node for each template once, rather than once for every
      # template that depends on it. A node's children depend only on its
      # template, so a node built under one root is the node any other root
      # would build. Precomputing digests at boot builds a tree for every
      # component, and most components render much of the same tree.
      def tree(name, finder, partial = false, seen = {})
        CacheDigest.analyzing_once do
          CacheDigest.analyzing(:tree, name, partial, finder.details_key) { super }
        end
      end

      private

      def find_template(finder, name, prefixes, partial, keys)
        Resolver.instance.find_templates(name, prefixes.first, partial, {formats: finder.formats}).first || super
      end
    end
  end
end
