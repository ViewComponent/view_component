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
          template_string = template.send(:source)
          ViewComponent::TemplateDependencyExtractor.new(template_string, template.extension.to_sym).extract
        else
          # A digest cant be built for inline calls as there is no template to parse
          []
        end
      end
    end

    def gather_templates
      @templates ||=
        begin
          templates = @component.sidecar_files(
            ActionView::Template.template_handler_extensions
          ).map do |path|
            # Extract format and variant from template filename
            this_format, variant =
              File
                .basename(path)     # "variants_component.html+mini.watch.erb"
                .split(".")[1..-2]  # ["html+mini", "watch"]
                .join(".")          # "html+mini.watch"
                .split("+")         # ["html", "mini.watch"]
                .map(&:to_sym)      # [:html, :"mini.watch"]

            out = Template.new(
              component: @component,
              type: :file,
              path: path,
              lineno: 0,
              extension: path.split(".").last,
              this_format: this_format.to_s.split(".").last&.to_sym, # strip locale from this_format, see #2113
              variant: variant
            )

            out
          end

          component_instance_methods_on_self = @component.instance_methods(false)

          (
            @component.ancestors.take_while { |ancestor| ancestor != ViewComponent::Base } - @component.included_modules
          ).flat_map { |ancestor| ancestor.instance_methods(false).grep(/^call(_|$)/) }
            .uniq
            .each do |method_name|
              templates << Template.new(
                component: @component,
                type: :inline_call,
                this_format: ViewComponent::Base::VC_INTERNAL_DEFAULT_FORMAT,
                variant: method_name.to_s.include?("call_") ? method_name.to_s.sub("call_", "").to_sym : nil,
                method_name: method_name,
                defined_on_self: component_instance_methods_on_self.include?(method_name)
              )
            end

          if @component.inline_template.present?
            templates << Template.new(
              component: @component,
              type: :inline,
              path: @component.inline_template.path,
              lineno: @component.inline_template.lineno,
              source: @component.inline_template.source.dup,
              extension: @component.inline_template.language
            )
          end

          templates
        end
    end

  end
end
