module ViewComponent
  class Config < ActiveSupport::InheritableOptions
    def initialize
      self.merge!({
                    generate: {},
                    preview_controller: false,
                    preview_route: false,
                    show_previews_source: false,
                    instrumentation_enabled: false,
                    render_monkey_patch_enabled: true,
                    show_previews: Rails.env.development? || Rails.env.test?,
                    use_global_output_buffer: false,
                    preview_paths: [("#{Rails.root}/test/components/previews" if defined?(Rails.root) && Dir.exist?("#{Rails.root}/test/components/previews"))].compact
                  })

      warn_deprecated_config_options
    end

    def preview_path
      self.preview_paths
    end

    def preview_path=(new_value)
      ViewComponent::Deprecation.warn("`preview_path` will be removed in v3.0.0. Use `preview_paths` instead.")
      self.preview_paths = new_value
    end

    def self.default
      new
    end
  end
end
