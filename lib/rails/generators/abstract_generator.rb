# frozen_string_literal: true

module ViewComponent
  module AbstractGenerator
    def copy_view_file
      unless options["inline"]
        template "component.html.#{engine_name}", destination
      end
    end

    private

    def destination
      if options["sidecar"]
        File.join(component_path, class_path, "#{file_name}_component", "#{file_name}_component.html.#{engine_name}")
      else
        File.join(component_path, class_path, "#{file_name}_component.html.#{engine_name}")
      end
    end

    def file_name
      @_file_name ||= super.sub(/_component\z/i, "")
    end

    def component_path
      Rails.application.config.view_component.view_component_path || "app/components"
    end
  end
end
