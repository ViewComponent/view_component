# frozen_string_literal: true

module ViewComponent
  class TemplateAstBuilder
    def self.build(template_string, engine_name)
      case engine_name.to_sym
      when :erb
        compile_erb(template_string)
      else
        compile_template_with_engine(template_string, engine_name)
      end
    end

    def self.compile_erb(template)
      require "erb"

      ERB::Compiler.new("-").compile(template).first
    rescue
      nil
    end
    private_class_method :compile_erb

    def self.compile_template_with_engine(template_string, engine_name)
      engine_class = load_template_engine(engine_name)
      return nil unless engine_class

      engine_class.new.call(template_string)
    rescue
      nil
    end
    private_class_method :compile_template_with_engine

    def self.load_template_engine(engine_name)
      engine_class = template_engine_class(engine_name)
      return engine_class if engine_class

      require engine_name.to_s
      template_engine_class(engine_name)
    rescue LoadError
      nil
    end
    private_class_method :load_template_engine

    def self.template_engine_class(engine_name)
      engine_module_name = engine_name.to_s.tr("-", "_").split("_").map!(&:capitalize).join
      Object.const_get("#{engine_module_name}::Engine")
    rescue NameError
      nil
    end
    private_class_method :template_engine_class
  end
end
