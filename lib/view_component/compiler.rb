# frozen_string_literal: true

require "concurrent-ruby"

module ViewComponent
  class Compiler
    # Compiler development mode. Can be either:
    # * true (a blocking mode which ensures thread safety when redefining the `call` method for components,
    #                default in Rails development and test mode)
    # * false(a non-blocking mode, default in Rails production mode)
    class_attribute :development_mode, default: false

    def initialize(component)
      @component = component
      @redefinition_lock = Mutex.new
      @rendered_templates = Set.new
    end

    def compiled?
      CompileCache.compiled?(@component)
    end

    def compile(raise_errors: false, force: false)
      return if (compiled? && !force)
      return if @component == ViewComponent::Base

      gather_templates

      if self.class.development_mode && @templates.any?(&:requires_compiled_superclass?)
        @component.superclass.compile(raise_errors: raise_errors)
      end

      return if gather_template_errors(raise_errors).any?

      if raise_errors
        @component.validate_initialization_parameters!
        @component.validate_collection_parameter!
      end

      define_render_template_for

      @component.register_default_slots
      @component.build_i18n_backend

      CompileCache.register(@component)
    end

    def renders_template_for?(variant, format)
      @rendered_templates.include?([variant, format])
    end

    private

    attr_reader :templates

    def define_render_template_for
      @templates.each { _1.compile_to_component(@redefinition_lock) }

      method_body =
        if (template = @templates.find(&:inline?))
          template.safe_method_name
        else
          branches = []

          @templates.each do |template|
            conditional =
              if template.inline_call?
                "variant&.to_sym == #{template.variant.inspect}"
              else
                [
                  template.default_format? ? "(format == #{ViewComponent::Base::DEFAULT_FORMAT.inspect} || format.nil?)" : "format == #{template.format.inspect}",
                  template.variant.nil? ? "variant.nil?" : "variant&.to_sym == #{template.variant.inspect}"
                ].join(" && ")
              end

            branches << [conditional, template.safe_method_name]
          end

          if branches.one?
            branches.last.last
          else
            out = branches.each_with_object(+"") do |(conditional, branch_body), memo|
              memo << "#{(!memo.present?) ? "if" : "elsif"} #{conditional}\n  #{branch_body}\n"
            end
            out << "else\n  #{templates.find { _1.variant.nil? && _1.default_format? }.safe_method_name}\nend"
          end
        end

      @redefinition_lock.synchronize do
        @component.silence_redefinition_of_method(:render_template_for)
        @component.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def render_template_for(variant = nil, format = nil)
          #{method_body}
        end
        RUBY
      end
    end

    def gather_template_errors(raise_errors)
      errors = []

      errors << "Couldn't find a template file or inline render method for #{@component}." if @templates.empty?

      # We currently allow components to have both an inline call method and a template for a variant, with the
      # inline call method overriding the template. We should aim to change this in v4 to instead
      # raise an error.
      @templates.select { !_1.inline_call? }
        .map { |template| [template.variant, template.format] }
        .tally
        .select { |_, count| count > 1 }
        .each do |tally|
        variant, this_format = tally.first

        variant_string = " for variant `#{variant}`" if variant.present?

        errors << "More than one #{this_format.upcase} template found#{variant_string} for #{@component}. "
      end

      if @templates.any? { _1.variant.nil? && !_1.inline_call? } &&
          @templates.any? { _1.variant.nil? && _1.inline_call? && _1.defined_on_self? }

        errors <<
          "Template file and inline render method found for #{@component}. " \
          "There can only be a template file or inline render method per component."
      end

      duplicate_template_file_and_inline_call_variants =
        @templates.select { !_1.inline_call? }.map(&:variant) &
        @templates.select { _1.inline_call? && _1.defined_on_self? }.map(&:variant)

      unless duplicate_template_file_and_inline_call_variants.empty?
        count = duplicate_template_file_and_inline_call_variants.count

        errors <<
          "Template #{"file".pluralize(count)} and inline render #{"method".pluralize(count)} " \
          "found for #{"variant".pluralize(count)} " \
          "#{duplicate_template_file_and_inline_call_variants.map { |v| "'#{v}'" }.to_sentence} " \
          "in #{@component}. There can only be a template file or inline render method per variant."
      end

      variant_pairs =
        @templates.select { _1.variant.present? }.map { [_1.variant, _1.normalized_variant_name] }.uniq(&:first)

      colliding_normalized_variants =
        variant_pairs.map(&:last).tally.select { |_, count| count > 1 }.keys
          .map do |normalized_variant_name|
          variant_pairs
            .select { |variant_pair| variant_pair.last == normalized_variant_name }
            .map { |variant_pair| variant_pair.first }
        end

      colliding_normalized_variants.each do |variants|
        errors << "Colliding templates #{variants.sort.map { |v| "'#{v}'" }.to_sentence} found in #{@component}."
      end

      raise TemplateError.new(errors) if errors.any? && raise_errors

      errors
    end

    def gather_templates
      @templates ||=
        begin
          templates = @component.sidecar_files(
            ActionView::Template.template_handler_extensions
          ).map do |path|
            pieces = File.basename(path).split(".")

            out = Template.new(
              component: @component,
              type: :file,
              path: path,
              lineno: 0,
              extension: pieces.last,
              this_format: pieces[1..-2].join(".").split("+").first&.to_sym,
              variant: pieces[1..-2].join(".").split("+").second&.to_sym
            )

            @rendered_templates << [out.variant, out.this_format]

            out
          end

          (
            @component.ancestors.take_while { |ancestor| ancestor != ViewComponent::Base } - @component.included_modules
          ).flat_map { |ancestor| ancestor.instance_methods(false).grep(/^call(_|$)/) }
            .uniq
            .each do |method_name|
              templates << Template.new(
                component: @component,
                type: :inline_call,
                this_format: ViewComponent::Base::DEFAULT_FORMAT,
                variant: method_name.to_s.include?("call_") ? method_name.to_s.sub("call_", "").to_sym : nil,
                method_name: method_name,
                defined_on_self: @component.instance_methods(false).include?(method_name)
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
