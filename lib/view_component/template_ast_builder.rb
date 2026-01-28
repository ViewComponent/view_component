# frozen_string_literal: true

require "erb"

begin
  require "temple"
rescue LoadError
  # Optional dependency: only needed for template AST extraction.
end

begin
  require "slim"
rescue LoadError
  # Optional dependency: only needed when parsing Slim templates.
end

begin
  require "haml"
rescue LoadError
  # Optional dependency: only needed when parsing Haml templates.
end

module ViewComponent
  class TemplateAstBuilder
    if defined?(Temple) && defined?(Haml)
      class HamlTempleWrapper < Temple::Engine
        def call(template)
          engine = Haml::Engine.new(template, format: :xhtml)
          html = engine.render
          [:multi, [:static, html]]
        end
      end
    end

    if defined?(Temple)
      class ErbTempleWrapper < Temple::Engine
        def call(template)
          Temple::ERB::Engine.new.call(template)
        end
      end
    end

    ENGINE_MAP = {}.tap do |map|
      map[:slim] = -> { Slim::Engine.new } if defined?(Slim)
      map[:haml] = -> { HamlTempleWrapper.new } if defined?(HamlTempleWrapper)
      map[:erb] = -> { ErbTempleWrapper.new } if defined?(ErbTempleWrapper)
    end.freeze

    def self.build(template_string, engine_name)
      engine = ENGINE_MAP.fetch(engine_name.to_sym) do
        return nil
      end.call

      engine.call(template_string)
    end
  end
end
