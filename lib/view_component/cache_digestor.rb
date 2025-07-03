# # frozen_string_literal: true

require "view_component/templat_dependency_extractor"

module ViewComponent
  class CacheDigestor
    def initialize(component:)
      @component = component
    end

    def digest
      template = @component.current_template
      if template.nil? && template == :inline_call
        []
      else
        template_string = template.source
        ViewComponent::TemplateDependencyExtractor.new(template_string, template.details.handler).extract
      end
    end
  end
end
