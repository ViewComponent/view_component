# frozen_string_literal: true

module ViewComponent
  # Keeps track of which templates have already been compiled
  # This isn't part of the public API
  module CompileCache
    # The cache is a frozen, Ractor-shareable Set stored in a module instance
    # variable, so it can be read from non-main Ractors. Writes replace it with
    # an updated copy under a lock.
    @cache = Ractor.make_shareable(Set.new)
    LOCK = Mutex.new
    private_constant :LOCK

    class << self
      attr_reader :cache

      def cache=(set)
        LOCK.synchronize { @cache = Ractor.make_shareable(set) }
      end

      def register(klass)
        LOCK.synchronize { @cache = Ractor.make_shareable(@cache | [klass]) }
      end

      def compiled?(klass)
        @cache.include?(klass)
      end

      def invalidate_class!(klass)
        LOCK.synchronize { @cache = Ractor.make_shareable(@cache - [klass]) }
      end

      def invalidate!
        LOCK.synchronize { @cache = Ractor.make_shareable(Set.new) }
      end

      # Invalidates the cache when a template or a translation file is added,
      # changed, or removed. Changes to Ruby files reload the application instead.
      def template_watcher(file_watcher)
        extensions = ActionView::Template::Handlers.extensions.map(&:to_s) + %w[yml yaml]
        directories = ActiveSupport::Dependencies.autoload_paths.index_with(extensions)

        file_watcher.new([], directories) { invalidate! }
      end
    end
  end
end
