# frozen_string_literal: true

module ViewComponent
  class TemplateAstBuilder
    def self.build(template_string, engine_name)
      case engine_name.to_sym
      when :erb
        compile_erb(template_string)
      when :slim
        return nil unless load_slim?

        Slim::Engine.new.call(template_string)
      when :haml
        return nil unless load_haml?

        Haml::Engine.new.call(template_string)
      end
    end

    def self.compile_erb(template)
      require "erb"

      ERB::Compiler.new("-").compile(template).first
    rescue
      nil
    end
    private_class_method :compile_erb

    def self.load_slim?
      return true if defined?(Slim::Engine)

      require "slim"
      true
    rescue LoadError
      false
    end
    private_class_method :load_slim?

    def self.load_haml?
      return true if defined?(Haml::Engine)

      require "haml"
      true
    rescue LoadError
      false
    end
    private_class_method :load_haml?
  end
end
