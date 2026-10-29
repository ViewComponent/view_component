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

    # Sidecar files can't change while the application eager loads: share
    # directory listings and look up each component's files once within the
    # block. Fiber storage keeps the cache from surviving boot.
    def with_sidecar_files_cache
      Fiber[:__vc_sidecar_files] = {}
      Fiber[:__vc_sidecar_directories] = {}
      yield
    ensure
      Fiber[:__vc_sidecar_files] = nil
      Fiber[:__vc_sidecar_directories] = nil
    end

    def sidecar_files_for(klass, extensions)
      sidecar_files_by_component = Fiber[:__vc_sidecar_files]
      return yield unless sidecar_files_by_component

      sidecar_files = sidecar_files_by_component[klass] ||= {}
      sidecar_files[extensions] ||= yield.freeze
    end

    def sidecar_files_matching(pattern)
      directories = Fiber[:__vc_sidecar_directories]
      return Dir[pattern] unless directories

      filename = File.basename(pattern)
      prefix = filename.delete_suffix(".*")
      return Dir[pattern] if prefix.match?(/[*?{}\[\]\\]/)

      directory = File.dirname(pattern)
      # Index the shared directory by component name instead of scanning all
      # its entries again for every component and extension.
      entries = directories[directory] ||= Dir.glob("#{directory}/*", File::FNM_DOTMATCH)
        .group_by { |path| File.basename(path).split(".", 2).first }
      candidates = entries.fetch(prefix.split(".", 2).first, [])
      candidates.select { |path| File.fnmatch?(filename, File.basename(path)) }
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
