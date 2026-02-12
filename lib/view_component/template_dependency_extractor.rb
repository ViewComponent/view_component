# frozen_string_literal: true

begin
  require "action_view/render_parser"
rescue LoadError
end

require_relative "template_ast_builder"
require_relative "prism_render_dependency_extractor"

module ViewComponent
  class TemplateDependencyExtractor
    def initialize(template_string, engine)
      @template_string = template_string
      @engine = engine
      @dependencies = Set.new
    end

    def extract
      engine = @engine.to_sym
      ruby_source = TemplateAstBuilder.build(@template_string, engine)

      if ruby_source.nil?
        return extract_erb_fallback if engine == :erb

        return []
      end

      extract_from_ruby(ruby_source)
      @dependencies.to_a
    end

    private

    def extract_from_ruby(ruby_code)
      return unless ruby_code.include?("render")

      PrismRenderDependencyExtractor.new(ruby_code).extract.each { @dependencies << _1 }

      extract_render_paths(ruby_code).each do |render_path|
        @dependencies << render_path.gsub(%r{/_}, "/")
      end
    end

    def extract_render_paths(ruby_code)
      if defined?(ActionView::RenderParser::Default)
        ActionView::RenderParser::Default.new("view_component/template", ruby_code).render_calls
      else
        extract_render_paths_fallback(ruby_code)
      end
    end

    PARTIAL_RENDER = /partial:\s*["']([^"']+)["']/
    LAYOUT_RENDER = /layout:\s*["']([^"']+)["']/
    DIRECT_RENDER = /render\s*\(?\s*["']([^"']+)["']/
    private_constant :PARTIAL_RENDER, :LAYOUT_RENDER, :DIRECT_RENDER

    def extract_render_paths_fallback(ruby_code)
      matches = []

      if (partial_match = ruby_code.match(PARTIAL_RENDER))
        matches << partial_match[1]
      end

      if (layout_match = ruby_code.match(LAYOUT_RENDER))
        matches << layout_match[1]
      end

      if (direct_match = ruby_code.match(DIRECT_RENDER))
        matches << direct_match[1]
      end

      matches
    end

    ERB_RUBY_TAG = /<%(=|-|#)?(.*?)%>/m
    private_constant :ERB_RUBY_TAG

    def extract_erb_fallback
      @template_string.scan(ERB_RUBY_TAG) do |(_, tag_ruby)|
        extract_from_ruby(tag_ruby)
      end

      @dependencies.to_a
    end
  end
end
