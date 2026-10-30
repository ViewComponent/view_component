# frozen_string_literal: true

module ViewComponent
  module AbstractGenerator
    def self.included(generator)
      generator.class_option :skip_suffix, type: :boolean, default: false
    end

    def initialize(...)
      super
      generate = ViewComponent::Base.config.generate
      defaults = {
        "sidecar" => generate.sidecar,
        "stimulus" => generate.stimulus_controller,
        "typescript" => generate.typescript
      }.slice(*self.class.class_options.keys.map(&:to_s))
      # Resolve defaults once so hooks inherit explicit false values as well.
      self.options = options.class.new(defaults.merge(options)).freeze
    end

    def copy_view_file
      template("component.html.#{engine_name}", destination) unless options["inline"] || options["call"]
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
      "#{file_name}#{"_component" unless options[:skip_suffix]}"
    end

    def component_class_name
      "#{class_name}#{"Component" unless options[:skip_suffix]}"
    end

    def file_name
      @_file_name ||= super.sub(/_component\z/i, "")
    end

    def component_path
      ViewComponent::Base.config.generate.path
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
      options["sidecar"]
    end

    def stimulus?
      options["stimulus"]
    end

    def typescript?
      options["typescript"]
    end
  end
end
