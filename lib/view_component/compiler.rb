# frozen_string_literal: true

require "concurrent-ruby"

module ViewComponent
  class Compiler
    # Compiler mode. Can be either:
    # * development (a blocking mode which ensures thread safety when redefining the `call` method for components,
    #                default in Rails development and test mode)
    # * production (a non-blocking mode, default in Rails production mode)
    DEVELOPMENT_MODE = :development
    PRODUCTION_MODE = :production

    class_attribute :mode, default: PRODUCTION_MODE

    def initialize(component_class)
      @component_class = component_class
      @redefinition_lock = Mutex.new
    end

    def compiled?
      CompileCache.compiled?(component_class)
    end

    def development?
      self.class.mode == DEVELOPMENT_MODE
    end

    def compile(raise_errors: false, force: false)
      return if compiled? && !force
      return if component_class == ViewComponent::Base

      if RUBY_VERSION < "2.7.0"
        ViewComponent::Deprecation.warn("Support for Ruby versions < 2.7.0 will be removed in v3.0.0.")
      end

      component_class.superclass.compile(raise_errors: raise_errors) if should_compile_superclass?
      subclass_instance_methods = component_class.instance_methods(false)

      if subclass_instance_methods.include?(:with_content) && raise_errors
        raise ViewComponent::ComponentError.new(
          "#{component_class} implements a reserved method, `#with_content`.\n\n" \
          "To fix this issue, change the name of the method."
        )
      end

      if template_errors.present?
        raise ViewComponent::TemplateError.new(template_errors) if raise_errors

        return false
      end

      if subclass_instance_methods.include?(:before_render_check)
        ViewComponent::Deprecation.warn(
          "`#before_render_check` will be removed in v3.0.0.\n\n" \
          "To fix this issue, use `#before_render` instead."
        )
      end

      if raise_errors
        component_class.validate_initialization_parameters!
        component_class.validate_collection_parameter!
      end

      templates.each do |template|
        # Remove existing compiled template methods,
        # as Ruby warns when redefining a method.
        method_name = call_method_name(template[:variant])

        redefinition_lock.synchronize do
          component_class.silence_redefinition_of_method(method_name)
          # rubocop:disable Style/EvalWithLocation
          component_class.class_eval <<-RUBY, template[:path], 0
          def #{method_name}
            #{compiled_template(template[:path])}
          end
          RUBY
          # rubocop:enable Style/EvalWithLocation
        end
      end

      define_render_template_for

      component_class.build_i18n_backend

      CompileCache.register(component_class)
    end

    private

    attr_reader :component_class, :redefinition_lock

    def define_render_template_for
      variant_elsifs = variants.compact.uniq.map do |variant|
        "elsif variant.to_sym == :#{variant}\n    #{call_method_name(variant)}"
      end.join("\n")

      body = <<-RUBY
        if variant.nil?
          call
        #{variant_elsifs}
        else
          call
        end
      RUBY

      redefinition_lock.synchronize do
        component_class.silence_redefinition_of_method(:render_template_for)
        component_class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def render_template_for(variant = nil)
          #{body}
        end
        RUBY
      end
    end

    def template_errors
      @__vc_template_errors ||=
        begin
          errors = []

          if (templates + inline_calls).empty?
            errors << "Couldn't find a template file or inline render method for #{component_class}."
          end

          if templates.count { |template| template[:variant].nil? } > 1
            errors <<
              "More than one template found for #{component_class}. " \
              "There can only be one default template file per component."
          end

          invalid_variants =
            templates
              .group_by { |template| template[:variant] }
              .map { |variant, grouped| variant if grouped.length > 1 }
              .compact
              .sort

          unless invalid_variants.empty?
            errors <<
              "More than one template found for #{"variant".pluralize(invalid_variants.count)} " \
              "#{invalid_variants.map { |v| "'#{v}'" }.to_sentence} in #{component_class}. " \
              "There can only be one template file per variant."
          end

          if templates.find { |template| template[:variant].nil? } && inline_calls_defined_on_self.include?(:call)
            errors <<
              "Template file and inline render method found for #{component_class}. " \
              "There can only be a template file or inline render method per component."
          end

          duplicate_template_file_and_inline_variant_calls =
            templates.pluck(:variant) & variants_from_inline_calls(inline_calls_defined_on_self)

          unless duplicate_template_file_and_inline_variant_calls.empty?
            count = duplicate_template_file_and_inline_variant_calls.count

            errors <<
              "Template #{"file".pluralize(count)} and inline render #{"method".pluralize(count)} " \
              "found for #{"variant".pluralize(count)} " \
              "#{duplicate_template_file_and_inline_variant_calls.map { |v| "'#{v}'" }.to_sentence} " \
              "in #{component_class}. " \
              "There can only be a template file or inline render method per variant."
          end

          errors
        end
    end

    def templates
      @templates ||=
        begin
          extensions = ActionView::Template.template_handler_extensions

          component_class.sidecar_files(extensions).each_with_object([]) do |path, memo|
            pieces = File.basename(path).split(".")
            memo << {
              path: path,
              variant: pieces.second.split("+").second&.to_sym,
              handler: pieces.last
            }
          end
        end
    end

    def inline_calls
      @inline_calls ||=
        begin
          # Fetch only ViewComponent ancestor classes to limit the scope of
          # finding inline calls
          view_component_ancestors =
            (
              component_class.ancestors.take_while { |ancestor| ancestor != ViewComponent::Base } -
              component_class.included_modules
            )

          view_component_ancestors.flat_map { |ancestor| ancestor.instance_methods(false).grep(/^call/) }.uniq
        end
    end

    def inline_calls_defined_on_self
      @inline_calls_defined_on_self ||= component_class.instance_methods(false).grep(/^call/)
    end

    def variants
      @__vc_variants = (
        templates.map { |template| template[:variant] } + variants_from_inline_calls(inline_calls)
      ).compact.uniq
    end

    def variants_from_inline_calls(calls)
      calls.reject { |call| call == :call }.map do |variant_call|
        variant_call.to_s.sub("call_", "").to_sym
      end
    end

    def compiled_template(file_path)
      handler = ActionView::Template.handler_for_extension(File.extname(file_path).delete("."))
      template = File.read(file_path)
      template.rstrip! if component_class.strip_trailing_whitespace?

      if handler.method(:call).parameters.length > 1
        handler.call(component_class, template)
      else
        handler.call(
          OpenStruct.new(
            source: template,
            identifier: component_class.identifier,
            type: component_class.type
          )
        )
      end
    end

    def call_method_name(variant)
      if variant.present? && variants.include?(variant)
        "call_#{variant}"
      else
        "call"
      end
    end

    def should_compile_superclass?
      development? &&
        templates.empty? &&
        !(
          component_class.instance_methods(false).include?(:call) ||
            component_class.private_instance_methods(false).include?(:call)
        )
    end
  end
end
