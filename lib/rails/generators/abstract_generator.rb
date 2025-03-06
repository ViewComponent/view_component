# frozen_string_literal: true

module ViewComponent
  module AbstractGenerator
    def copy_view_file
      template "component.html.#{engine_name}", destination unless options["inline"]
    end

    private

    def destination
      File.join(destination_directory, "#{destination_file_name}.html.#{engine_name}")
    end

    def destination_directory
      if sidecar?
        File.join(component_path, class_path, destination_file_name)
      else
        File.join(component_path, class_path)
      end
    end

    def destination_file_name
      "#{file_name}_component"
    end

    def file_name
      @_file_name ||= super.sub(/_component\z/i, "")
    end

    def component_path
      # FIXME: Doesn't yet handle multiple component paths
      Rails.application.config.view_component.generate.view_component_paths!.first
    end

    def stimulus_controller
      if stimulus?
        File.join(destination_directory, destination_file_name)
          .sub("#{component_path}/", "")
          .tr("_", "-")
          .gsub("/", "--")
      end
    end

    def sidecar?
      options["sidecar"] || Rails.application.config.view_component.generate.sidecar
    end

    def stimulus?
      options["stimulus"] || Rails.application.config.view_component.generate.stimulus_controller
    end

    def typescript?
      options["typescript"] || Rails.application.config.view_component.generate.typescript
    end
  end
end
