# frozen_string_literal: true

require "actionview_precompiler"

require_relative "template_ast_builder"

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

      extract_component_class_renders(ruby_code).each { @dependencies << _1 }

      extract_render_paths(ruby_code).each do |render_path|
        @dependencies << render_path.gsub(%r{/_}, "/")
      end
    end

    COMPONENT_RENDER = /(?:render|render_to_string)\s*\(?\s*([A-Z]\w*(?:::[A-Z]\w*)*)\.new\b/
    private_constant :COMPONENT_RENDER

    def extract_component_class_renders(ruby_code)
      ruby_code.scan(COMPONENT_RENDER).flatten
    end

    def extract_render_paths(ruby_code)
      render_calls = ActionviewPrecompiler::RenderParser.new(ruby_code).render_calls
      render_calls.map do |call|
        call.respond_to?(:virtual_path) ? call.virtual_path : call
      end
    rescue ActionviewPrecompiler::PrismASTParser::CompilationError
      require "actionview_precompiler/ast_parser/ripper"

      ActionviewPrecompiler::RenderParser.new(ruby_code, parser: ActionviewPrecompiler::RipperASTParser).render_calls.map do |call|
        call.respond_to?(:virtual_path) ? call.virtual_path : call
      end
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
