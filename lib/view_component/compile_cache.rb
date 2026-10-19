# frozen_string_literal: true

module ViewComponent
  # Keeps track of which templates have already been compiled
  # This isn't part of the public API
  module CompileCache
    mattr_accessor :cache, instance_reader: false, instance_accessor: false do
      Set.new
    end

    module_function

    def register(klass)
      cache << klass
    end

    def compiled?(klass)
      cache.include? klass
    end

    def invalidate_class!(klass)
      cache.delete(klass)
    end

    def invalidate!
      cache.clear
    end

    # Invalidates the cache when a template or a translation file is added,
    # changed, or removed. Changes to Ruby files reload the application instead.
    def template_watcher(file_watcher)
      extensions = ActionView::Template::Handlers.extensions.map(&:to_s) + %w[yml yaml]
      directories = ActiveSupport::Dependencies.autoload_paths.index_with(extensions)

      file_watcher.new([], directories) { invalidate! }
    end

    # Like Rails' own template cache expiry, only watches templates when they
    # aren't cached at boot. With template caching on, as in production, no
    # hook runs per request, so requests never read ActionView's caching
    # class variable, which non-main Ractors can't access.
    def watch_templates(app)
      return if ActionView::Base.cache_template_loading

      watcher = nil

      app.executor.to_run :before do
        watcher ||= CompileCache.template_watcher(app.config.file_watcher)
        watcher.execute_if_updated
      end
    end
  end
end
