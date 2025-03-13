# frozen_string_literal: true

module ViewComponent
  class Template
    DataWithSource = Struct.new(:format, :identifier, :short_identifier, :type, keyword_init: true)
    DataNoSource = Struct.new(:source, :identifier, :type, keyword_init: true)

    attr_reader :variant, :this_format, :type

    def initialize(
      component:,
      type:,
      this_format: nil,
      variant: nil,
      lineno: nil,
      path: nil,
      extension: nil,
      source: nil,
      method_name: nil,
      defined_on_self: true
    )
      @component = component
      @type = type
      @this_format = this_format
      @variant = variant&.to_sym
      @lineno = lineno
      @path = path
      @extension = extension
      @source = source
      @method_name = method_name
      @defined_on_self = defined_on_self

      @source_originally_nil = @source.nil?

      @call_method_name =
        if @method_name
          @method_name
        else
          out = +"call"
          out << "_#{normalized_variant_name}" if @variant.present?
          out << "_#{@this_format}" if @this_format.present? && @this_format != ViewComponent::Base::VC_INTERNAL_DEFAULT_FORMAT
          out
        end
    end

    def compile_to_component
      if !inline_call?
        @component.silence_redefinition_of_method(@call_method_name)

        # rubocop:disable Style/EvalWithLocation
        @component.class_eval <<-RUBY, @path, @lineno
        def #{@call_method_name}
          #{compiled_source}
        end
        RUBY
        # rubocop:enable Style/EvalWithLocation
      end

      @component.define_method(safe_method_name, @component.instance_method(@call_method_name))
    end

    def safe_method_name_call
      return safe_method_name unless inline_call?

      "maybe_escape_html(#{safe_method_name}) " \
      "{ Kernel.warn(\"WARNING: The #{@component} component rendered HTML-unsafe output. " \
      "The output will be automatically escaped, but you may want to investigate.\") } "
    end

    def requires_compiled_superclass?
      inline_call? && !defined_on_self?
    end

    def inline_call?
      @type == :inline_call
    end

    def inline?
      @type == :inline
    end

    def default_format?
      @this_format == ViewComponent::Base::VC_INTERNAL_DEFAULT_FORMAT
    end

    def format
      @this_format
    end

    def safe_method_name
      "_#{@call_method_name}_#{@component.name.underscore.gsub("/", "__")}"
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
          DataWithSource.new(format: @this_format, identifier: @path, short_identifier: short_identifier, type: type),
          this_source
        )
      # :nocov:
      # TODO: Remove in v4
      else
        handler.call(DataNoSource.new(source: this_source, identifier: @path, type: type))
      end
      # :nocov:
    end
  end
end
