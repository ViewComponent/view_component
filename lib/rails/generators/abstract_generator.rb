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
      File.join(destination_directory, "#{destination_file_name}.html.#{engine_name}")
    end

    def destination_directory
      if options["sidecar"]
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
      ViewComponent::Base.view_component_path
    end

    def stimulus_controller
      if options["stimulus"]
        File.join(destination_directory, destination_file_name).
          sub("#{component_path}/", "").
          gsub("_", "-").
          gsub("/", "--")
      end
    end
  end
end
