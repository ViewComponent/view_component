
# frozen_string_literal: true

require 'temple'
require 'slim'
require 'haml'
require 'erb'

module ViewComponent
  class TemplateAstBuilder
    class HamlTempleWrapper < Temple::Engine
      def call(template)
        engine = Haml::Engine.new(template, format: :xhtml)
        html = engine.render
        [:multi, [:static, html]]
      end
    end

    class ErbTempleWrapper < Temple::Engine
      def call(template)
        Temple::ERB::Engine.new.call(template)
      end
    end

    ENGINE_MAP = {
      slim: -> { Slim::Engine.new },
      haml: -> { HamlTempleWrapper.new },
      erb:  -> { ErbTempleWrapper.new }
    }

    def self.build(template_string, engine_name)
      engine = ENGINE_MAP.fetch(engine_name.to_sym) do
        raise ArgumentError, "Unsupported engine: #{engine_name.inspect}"
      end.call

      engine.call(template_string)
    end
  end
end
