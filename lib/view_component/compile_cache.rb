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

    # Sidecar files can't change while the application eager loads: within the
    # block, each component's are looked up once. Fiber storage rather than
    # module state, so the cache is gone once boot is done.
    def with_sidecar_files_cache
      Fiber[:__vc_sidecar_files] = {}
      yield
    ensure
      Fiber[:__vc_sidecar_files] = nil
    end

    def sidecar_files_for(klass, extensions)
      sidecar_files_by_component = Fiber[:__vc_sidecar_files]
      return yield unless sidecar_files_by_component

      sidecar_files = sidecar_files_by_component[klass] ||= {}
      sidecar_files[extensions] ||= yield.freeze
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
