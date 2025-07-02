# # frozen_string_literal: true

require 'view_component/templat_dependency_extractor'

module ViewComponent
  class CacheDigestor
    def initialize(component:)
    @component= component.class
    end

    def digest
      gather_templates
      @templates.map do |template|
        if template.type == :file
          template_string = template.source
          ViewComponent::TemplateDependencyExtractor.new(template_string, template.extension.to_sym).extract
        else
          # A digest cant be built for inline calls as there is no template to parse
          []
        end
      end
    end

    def gather_templates
      @templates = @component.compiler.send(:gather_templates) 
    end
  end
end
