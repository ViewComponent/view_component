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
      if !File.exist?(ViewComponent::Base.config.view_component_path)
        warning_text = "The folder '#{ViewComponent::Base.config.view_component_path}' does not exist and it will be created now.\nPlease note that you will need to restart your Rails server before Rails can load your new component."
        puts "\e[33m#{warning_text}\e[0m"
      end
      ViewComponent::Base.config.view_component_path
    end

    def stimulus_controller
      if options["stimulus"]
        File.join(destination_directory, destination_file_name)
          .sub("#{component_path}/", "")
          .tr("_", "-")
          .gsub("/", "--")
      end
    end

    def sidecar?
      options["sidecar"] || ViewComponent::Base.config.generate.sidecar
    end
  end
end
