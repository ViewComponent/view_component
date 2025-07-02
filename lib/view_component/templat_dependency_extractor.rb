
# frozen_string_literal: true

require_relative 'template_ast_builder'
require_relative 'prism_render_dependency_extractor'

module ViewComponent
  class TemplateDependencyExtractor
    def initialize(template_string, engine)
      @template_string = template_string
      @engine = engine
      @dependencies = []
    end

    def extract
      ast = TemplateAstBuilder.build(@template_string, @engine)
      walk(ast.split(';'))
      @dependencies.uniq
    end

    private

    def walk(node)
      return unless node.is_a?(Array)

      node.each { extract_from_ruby(_1) if _1.is_a?(String) }
    end

    def extract_from_ruby(ruby_code)
      return unless ruby_code.include?("render")

      @dependencies.concat PrismRenderDependencyExtractor.new(ruby_code).extract
      extract_partial_or_layout(ruby_code)
    end

    def extract_partial_or_layout(code)
      partial_match = code.match(/partial:\s*["']([^"']+)["']/)
      layout_match  = code.match(/layout:\s*["']([^"']+)["']/)
      direct_render = code.match(/render\s*\(?\s*["']([^"']+)["']/)

      @dependencies << partial_match[1] if partial_match
      @dependencies << layout_match[1] if layout_match
      @dependencies << direct_render[1] if direct_render
    end
  end
end
