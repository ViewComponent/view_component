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

    def initialize(component)
      @component = component
      @redefinition_lock = Mutex.new
      @variants_rendering_templates = Set.new
    end

    def compiled?
      CompileCache.compiled?(component)
    end

    def compile(raise_errors: false, force: false)
      return if (compiled? && !force) || component == ViewComponent::Base

      gather_templates

      if self.class.mode == DEVELOPMENT_MODE && templates.none? { !(_1.inline_call? && !_1.defined_on_self?) }
        component.superclass.compile(raise_errors: raise_errors)
      end

      return if gather_template_errors(raise_errors).any?

      if raise_errors
        component.validate_initialization_parameters!
        component.validate_collection_parameter!
      end

      define_render_template_for

      component.register_default_slots
      component.build_i18n_backend

      CompileCache.register(component)
    end

    # TODO this should probably take format into account
    def renders_template_for_variant?(variant)
      @variants_rendering_templates.include?(variant)
    end

    private

    attr_reader :component, :templates

    def define_render_template_for
      templates.each { _1.compile_to_component(@redefinition_lock) }

      body =
        if template = templates.find { _1.inline? }
          template.safe_method_name
        else
          branches = []

          templates.each do |template|
            conditional =
              if template.inline_call?
                "variant&.to_sym == #{template.variant.inspect}"
              else
                [
                  template.html? ? "(format == :html || format.nil?)" : "format == #{template.format.inspect}",
                  template.variant.nil? ? "variant.nil?" : "variant&.to_sym == #{template.variant.inspect}"
                ].join(" && ")
              end

            branches << [conditional, template.safe_method_name]
          end

          # Just use default method name if no conditional branches or if there is a single
          # conditional branch that just calls the default method_name
          if branches.length == 1
            branches[0].last
          else
            out = +""

            branches.each do |conditional, method_body|
              out << "#{(!out.present?) ? "if" : "elsif"} #{conditional}\n  #{method_body}\n"
            end

            out << "else\n  #{templates.find { _1.variant.nil? && _1.html? }.safe_method_name}\nend"

            out
          end
        end

      @redefinition_lock.synchronize do
        component.silence_redefinition_of_method(:render_template_for)
        component.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def render_template_for(variant = nil, format = nil)
          #{body}
        end
        RUBY
      end
    end

    def gather_template_errors(raise_errors)
      errors = []

      errors << "Couldn't find a template file or inline render method for #{component}." if templates.empty?

      # We currently allow components to have both an inline call method and a template for a variant, with the
      # inline call method overriding the template. We should aim to change this in v4 to instead
      # raise an error.
      templates.select { !_1.inline_call? }.
        map { |template| [template.variant, template.format] }.
        tally.
        select { |_, count| count > 1 }.
        each do |tally|
        variant, this_format = tally[0]

        variant_string = " for variant `#{variant}`" if variant.present?

        errors << "More than one #{this_format.upcase} template found#{variant_string} for #{component}. "
      end

      if (
        templates.any? { _1.variant.nil? && !_1.inline_call? } &&
        templates.any? { _1.variant.nil? && _1.inline_call? && _1.defined_on_self? }
      )
        errors <<
          "Template file and inline render method found for #{component}. " \
          "There can only be a template file or inline render method per component."
      end

      duplicate_template_file_and_inline_call_variants =
        templates.select { !_1.inline_call? }.map(&:variant) &
        templates.select { _1.inline_call? && _1.defined_on_self? }.map(&:variant)

      unless duplicate_template_file_and_inline_call_variants.empty?
        count = duplicate_template_file_and_inline_call_variants.count

        errors <<
          "Template #{"file".pluralize(count)} and inline render #{"method".pluralize(count)} " \
          "found for #{"variant".pluralize(count)} " \
          "#{duplicate_template_file_and_inline_call_variants.map { |v| "'#{v}'" }.to_sentence} " \
          "in #{component}. There can only be a template file or inline render method per variant."
      end

      variant_pairs =
        templates.select { _1.variant.present? }.map { [_1.variant, _1.normalized_variant_name] }.uniq { _1.first }

      colliding_normalized_variants =
        variant_pairs.map(&:last).tally.select { |_, count| count > 1 }.keys.
        map do |normalized_variant_name|
          variant_pairs.
            select { |variant_pair| variant_pair.last == normalized_variant_name }.
            map { |variant_pair| variant_pair.first }
        end

      colliding_normalized_variants.each do |variants|
        errors << "Colliding templates #{variants.sort.map { |v| "'#{v}'" }.to_sentence} found in #{component}."
      end

      raise TemplateError.new(errors) if errors.any? && raise_errors

      errors
    end

    def gather_templates
      @templates ||=
        begin
          templates = component.sidecar_files(
            ActionView::Template.template_handler_extensions
          ).map do |path|
            pieces = File.basename(path).split(".")

            out = Template.new(
              component: component,
              type: :file,
              path: path,
              lineno: 0,
              source: nil,
              extension: pieces.last,
              this_format: pieces[1..-2].join(".").split("+").first&.to_sym,
              variant: pieces[1..-2].join(".").split("+").second&.to_sym
            )

            @variants_rendering_templates << out.variant

            out
          end

          inline_calls =
            (
              component.ancestors.take_while { |ancestor| ancestor != ViewComponent::Base } - component.included_modules
            ).flat_map { |ancestor| ancestor.instance_methods(false).grep(/^call(_|$)/) }.uniq

          inline_calls.each do |method_name|
            templates << Template.new(
              component: component,
              type: :inline_call,
              path: nil,
              lineno: nil,
              source: nil,
              extension: nil,
              this_format: :html,
              variant: method_name.to_s.include?("call_") ? method_name.to_s.sub("call_", "").to_sym : nil,
              method_name: method_name,
              defined_on_self: component.instance_methods(false).include?(method_name)
            )
          end

          if component.inline_template.present?
            templates << Template.new(
              component: component,
              type: :inline,
              path: component.inline_template.path,
              lineno: component.inline_template.lineno,
              source: component.inline_template.source.dup,
              extension: component.inline_template.language,
              this_format: nil,
              variant: nil
            )
          end

          templates
        end
    end

    class Template
      attr_reader :variant, :type, :call_method_name

      def initialize(
        component:,
        path:,
        source:,
        extension:,
        this_format:,
        lineno:,
        variant:,
        type:,
        method_name: nil,
        defined_on_self: true
      )
        @component, @path, @source, @extension, @this_format, @lineno, @variant, @type, @defined_on_self =
          component, path, source, extension, this_format, lineno, variant&.to_sym, type, defined_on_self
        @source_originally_nil = @source.nil?

        @call_method_name =
          if @method_name
            @method_name
          else
            out = +"call"
            out << "_#{normalized_variant_name}" if @variant.present?
            out << "_#{@this_format}" if @this_format.present? && @this_format != :html
            out
          end
      end

      def compile_to_component(redefinition_lock)
        if !inline_call?
          redefinition_lock.synchronize do
            @component.silence_redefinition_of_method(call_method_name)

            # rubocop:disable Style/EvalWithLocation
            @component.class_eval <<-RUBY, @path, @lineno
            def #{call_method_name}
              #{compiled_source}
            end
            RUBY
            # rubocop:enable Style/EvalWithLocation
          end
        end

        @component.define_method(safe_method_name, @component.instance_method(call_method_name))
      end

      def inline_call?
        @type == :inline_call
      end

      def inline?
        @type == :inline
      end

      def html?
        @this_format == :html
      end

      def format
        @this_format
      end

      def safe_method_name
        "_#{call_method_name}_#{@component.name.underscore.gsub("/", "__")}"
      end

      def normalized_variant_name
        @variant.to_s.gsub("-", "__").gsub(".", "___")
      end

      def defined_on_self?
        @defined_on_self
      end

      private

      def source
        if @source_originally_nil
          # Load file each time we look up #source in case the file has been modified
          File.read(@path)
        else
          @source
        end
      end

      def compiled_source
        handler = ActionView::Template.handler_for_extension(@extension)
        this_source = source
        this_source.rstrip! if @component.strip_trailing_whitespace?

        short_identifier = defined?(Rails.root) ? @path.sub("#{Rails.root}/", "") : @path
        type = ActionView::Template::Types[@this_format]

        if handler.method(:call).parameters.length > 1
          handler.call(
            OpenStruct.new(
              format: @this_format,
              identifier: @path,
              short_identifier: short_identifier,
              type: type
            ),
            this_source
          )
        # :nocov:
        else
          handler.call(
            OpenStruct.new(
              source: this_source,
              identifier: @path,
              type: type
            )
          )
        end
        # :nocov:
      end
    end
  end
end
