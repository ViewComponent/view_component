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

      def digest(finder:, **)
        CacheDigest.memoizing do
          previous = CacheDigest.memo[:pruned]
          loop do
            pruned = CacheDigest.memo[:pruned] = {}
            digest = super

            # A component that registered while the tree was built expired the
            # digests the pruned nodes stood in for, so this one, and the
            # digests computed for them since, are missing their dependencies.
            break digest if pruned.all? { |name, cached| finder.digest_cache[name].equal?(cached) }

            finder.digest_cache.clear
          end
        ensure
          CacheDigest.memo[:pruned] = previous
        end
      end

      # A dependency whose digest is cached already becomes a leaf:
      # `Node#dependency_digest` reads the cache and never walks its children.
      # Without this, every component digested at boot rebuilds the tree of
      # everything it renders, which for components rendering a shared helper
      # module is most of the application.
      def tree(name, finder, partial = false, seen = {})
        pruned = CacheDigest.memo&.fetch(:pruned, nil)
        cached = finder.digest_cache[name] if pruned && partial
        return super unless cached

        path = ActionView::TemplatePath.parse(name)
        template = find_template(finder, path.name, [path.prefix], partial, [])
        return super unless template

        pruned[name] = cached
        seen[template.identifier] ||= ActionView::Digestor::Node.create(name, name.gsub(%r{/_}, "/"), template, partial)
      end

      private

      def find_template(finder, name, prefixes, partial, keys)
        key = [:template, name, prefixes.first, partial, finder.formats, finder.view_paths]
        template = CacheDigest.memoize(key) do
          Resolver.instance.find_templates(
            name, prefixes.first, partial, {formats: finder.formats}, view_paths: finder.view_paths
          ).first
        end

        template || super
      end
    end
  end
end
