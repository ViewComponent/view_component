# frozen_string_literal: true

module ViewComponent
  # Keeps track of which templates have already been compiled
  # This isn't part of the public API
  module CompileCache
    # The cache is a frozen, Ractor-shareable Set stored in a module instance
    # variable, so it can be read from non-main Ractors. Writes, which only
    # happen in the main Ractor while compiling or reloading, replace it with an
    # updated copy under a lock.
    @cache = Ractor.make_shareable(Set.new) # audition:disable class-level-state
    LOCK = Mutex.new # audition:disable mutable-constants
    private_constant :LOCK

    class << self
      attr_reader :cache

      def cache=(set)
        update { set }
      end

      def register(klass)
        update { |cache| cache | [klass] }
      end

      def compiled?(klass)
        @cache.include?(klass)
      end

      def invalidate_class!(klass)
        update { |cache| cache - [klass] }
      end

      def invalidate!
        update { Set.new }
      end

      # Invalidates the cache when a template or a translation file is added,
      # changed, or removed. Changes to Ruby files reload the application instead.
      def template_watcher(file_watcher)
        extensions = ActionView::Template::Handlers.extensions.map(&:to_s) + %w[yml yaml]
        directories = ActiveSupport::Dependencies.autoload_paths.index_with(extensions)

        file_watcher.new([], directories) { invalidate! }
      end

      private

      def update
        LOCK.synchronize { @cache = Ractor.make_shareable(yield(@cache)) } # audition:disable class-level-state
      end
    end
  end
end
