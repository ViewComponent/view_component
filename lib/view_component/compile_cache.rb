# frozen_string_literal: true

module ViewComponent
  # Keeps track of which templates have already been compiled
  # This isn't part of the public API
  module CompileCache
    mattr_accessor :cache, instance_reader: false, instance_accessor: false do
      Set.new
    end

    mattr_accessor :sidecar_files_by_component, instance_reader: false, instance_accessor: false do
      {}
    end

    module_function

    def register(klass)
      cache << klass
    end

    def compiled?(klass)
      cache.include? klass
    end

    def sidecar_files_for(klass, extensions)
      sidecar_files = sidecar_files_by_component[klass] ||= {}
      sidecar_files[extensions] ||= yield
    end

    def invalidate_class!(klass)
      cache.delete(klass)
      sidecar_files_by_component.delete(klass)
    end

    def invalidate!
      cache.clear
      sidecar_files_by_component.clear
    end

    # Invalidates the cache when a template or a translation file is added,
    # changed, or removed. Changes to Ruby files reload the application instead.
    def template_watcher(file_watcher)
      extensions = ActionView::Template::Handlers.extensions.map(&:to_s) + %w[yml yaml]
      directories = ActiveSupport::Dependencies.autoload_paths.map(&:to_s).index_with(extensions)

      file_watcher.new([], directories) { invalidate! }
    end
  end
end
