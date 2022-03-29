# frozen_string_literal: true

module ViewComponent
  class Config < ActiveSupport::InheritableOptions
    DEFAULTS = -> {
      {
        generate: ActiveSupport::OrderedOptions.new(false),
        preview_controller: "ViewComponentsController",
        preview_route: "/rails/view_components",
        show_previews_source: false,
        instrumentation_enabled: false,
        render_monkey_patch_enabled: true,
        view_component_path: "app/components",
        component_parent_class: nil,
        show_previews: Rails.env.development? || Rails.env.test?,
        use_global_output_buffer: false,
        preview_paths: default_preview_paths
      }
    }
    def initialize
      self.merge!(DEFAULTS.call)
    end

    def preview_path
      self.preview_paths
    end

    def preview_path=(new_value)
      ViewComponent::Deprecation.warn("`preview_path` will be removed in v3.0.0. Use `preview_paths` instead.")
      self.preview_paths = [new_value]
    end

    class << self
      alias default new

      def default_preview_paths
        return [] unless defined?(Rails.root) && Dir.exist?("#{Rails.root}/test/components/previews")

        ["#{Rails.root}/test/components/previews"]
      end
    end
  end
end
