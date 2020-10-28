# frozen_string_literal: true

module ViewComponent
  class Compiler
    def initialize(component_class)
      @component_class = component_class
    end

    def compiled?
      CompileCache.compiled?(component_class)
    end

    def compile(raise_errors: false)
      return if compiled?

      if template_errors.present?
        raise ViewComponent::TemplateError.new(template_errors) if raise_errors
        return false
      end

      if component_class.instance_methods(false).include?(:before_render_check)
        ActiveSupport::Deprecation.warn(
          "`before_render_check` will be removed in v3.0.0. Use `before_render` instead."
        )
      end

      # Remove any existing singleton methods,
      # as Ruby warns when redefining a method.
      component_class.remove_possible_singleton_method(:collection_parameter)
      component_class.remove_possible_singleton_method(:collection_counter_parameter)
      component_class.remove_possible_singleton_method(:counter_argument_present?)

      component_class.define_singleton_method(:collection_parameter) do
        if provided_collection_parameter
          provided_collection_parameter
        else
          name.demodulize.underscore.chomp("_component").to_sym
        end
      end

      component_class.define_singleton_method(:collection_counter_parameter) do
        "#{collection_parameter}_counter".to_sym
      end

      component_class.define_singleton_method(:counter_argument_present?) do
        instance_method(:initialize).parameters.map(&:second).include?(collection_counter_parameter)
      end

      component_class.validate_collection_parameter! if raise_errors

      templates.each do |template|
        # Remove existing compiled template methods,
        # as Ruby warns when redefining a method.
        method_name = call_method_name(template[:variant])
        component_class.send(:undef_method, method_name.to_sym) if component_class.instance_methods.include?(method_name.to_sym)

        component_class.class_eval <<-RUBY, template[:path], -1
          def #{method_name}
            @output_buffer = self.class.template_buffer_instance
            #{compiled_template(template[:path])}
          end
        RUBY
      end

      define_render_template_for

      CompileCache.register(component_class)
    end

    private

    attr_reader :component_class

    def define_render_template_for
      component_class.send(:undef_method, :render_template_for) if component_class.instance_methods.include?(:render_template_for)

      variant_elsifs = variants.compact.uniq.map do |variant|
        "elsif variant.to_sym == :#{variant}\n    #{call_method_name(variant)}"
      end.join("\n")

      component_class.class_eval <<-RUBY
        def render_template_for(variant = nil)
          if variant.nil?
            call
          #{variant_elsifs}
          else
            call
          end
        end
      RUBY

    end

    def template_errors
      @_template_errors ||= begin
        errors = []

        if (templates + inline_calls).empty?
          errors << "Could not find a template file or inline render method for #{component_class}."
        end

        if templates.count { |template| template[:variant].nil? } > 1
          errors << "More than one template found for #{component_class}. There can only be one default template file per component."
        end

        invalid_variants = templates
          .group_by { |template| template[:variant] }
          .map { |variant, grouped| variant if grouped.length > 1 }
          .compact
          .sort

        unless invalid_variants.empty?
          errors << "More than one template found for #{'variant'.pluralize(invalid_variants.count)} #{invalid_variants.map { |v| "'#{v}'" }.to_sentence} in #{component_class}. There can only be one template file per variant."
        end

        if templates.find { |template| template[:variant].nil? } && inline_calls_defined_on_self.include?(:call)
          errors << "Template file and inline render method found for #{component_class}. There can only be a template file or inline render method per component."
        end

        duplicate_template_file_and_inline_variant_calls =
          templates.pluck(:variant) & variants_from_inline_calls(inline_calls_defined_on_self)

        unless duplicate_template_file_and_inline_variant_calls.empty?
          count = duplicate_template_file_and_inline_variant_calls.count

          errors << "Template #{'file'.pluralize(count)} and inline render #{'method'.pluralize(count)} found for #{'variant'.pluralize(count)} #{duplicate_template_file_and_inline_variant_calls.map { |v| "'#{v}'" }.to_sentence} in #{component_class}. There can only be a template file or inline render method per variant."
        end

        errors
      end
    end

    def templates
      @templates ||= matching_views_in_source_location.each_with_object([]) do |path, memo|
        pieces = File.basename(path).split(".")

        memo << {
          path: path,
          variant: pieces.second.split("+").second&.to_sym,
          handler: pieces.last
        }
      end
    end

    def matching_views_in_source_location
      source_location = component_class.source_location
      return [] unless source_location

      location_without_extension = source_location.chomp(File.extname(source_location))

      extensions = ActionView::Template.template_handler_extensions.join(",")

      # view files in the same directory as the component
      sidecar_files = Dir["#{location_without_extension}.*{#{extensions}}"]

      # view files in a directory named like the component
      directory = File.dirname(source_location)
      filename = File.basename(source_location, ".rb")
      component_name = component_class.name.demodulize.underscore

      sidecar_directory_files = Dir["#{directory}/#{component_name}/#{filename}.*{#{extensions}}"]

      (sidecar_files - [source_location] + sidecar_directory_files).uniq
    end

    def inline_calls
      @inline_calls ||= begin
        # Fetch only ViewComponent ancestor classes to limit the scope of
        # finding inline calls
        view_component_ancestors =
          component_class.ancestors.take_while { |ancestor| ancestor != ViewComponent::Base } - component_class.included_modules

        view_component_ancestors.flat_map { |ancestor| ancestor.instance_methods(false).grep(/^call/) }.uniq
      end
    end

    def inline_calls_defined_on_self
      @inline_calls_defined_on_self ||= component_class.instance_methods(false).grep(/^call/)
    end

    def variants
      @_variants = (
        templates.map { |template| template[:variant] } + variants_from_inline_calls(inline_calls)
      ).compact.uniq
    end

    def variants_from_inline_calls(calls)
      calls.reject { |call| call == :call }.map do |variant_call|
        variant_call.to_s.sub("call_", "").to_sym
      end
    end

    # :nocov:
    def compiled_template(file_path)
      handler = ActionView::Template.handler_for_extension(File.extname(file_path).gsub(".", ""))
      template = File.read(file_path)

      if handler.method(:call).parameters.length > 1
        handler.call(component_class, template)
      else
        handler.call(OpenStruct.new(source: template, identifier: component_class.identifier, type: component_class.type))
      end
    end
    # :nocov:

    def call_method_name(variant)
      if variant.present? && variants.include?(variant)
        "call_#{variant}"
      else
        "call"
      end
    end
  end
end
