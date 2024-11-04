# frozen_string_literal: true

module ViewComponent
  class Template
    DataWithSource = Struct.new(:format, :identifier, :short_identifier, :type, keyword_init: true)
    DataNoSource = Struct.new(:source, :identifier, :type, keyword_init: true)

    attr_reader :variant, :this_format

    def initialize(
      component:,
      this_format: nil,
      variant: nil,
      lineno: nil,
      path: nil,
      extension: nil,
      method_name: nil,
      defined_on_self: true
    )
      @component = component
      @this_format = this_format
      @variant = variant&.to_sym
      @lineno = lineno
      @path = path
      @extension = extension
      @method_name = method_name
      @defined_on_self = defined_on_self

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

    class File < Template
      def initialize(component:, path:)
        # Extract format and variant from template filename
        this_format, variant =
          ::File
            .basename(path)     # "variants_component.html+mini.watch.erb"
            .split(".")[1..-2]  # ["html+mini", "watch"]
            .join(".")          # "html+mini.watch"
            .split("+")         # ["html", "mini.watch"]
            .map(&:to_sym)      # [:html, :"mini.watch"]

        super(
          component: component,
          path: path,
          lineno: 0,
          extension: path.split(".").last,
          this_format: this_format.to_s.split(".").last&.to_sym, # strip locale from this_format, see #2113
          variant: variant
        )
      end

      def type
        :file
      end

      # Load file each time we look up #source in case the file has been modified
      def source
        ::File.read(@path)
      end
    end

    class Inline < Template
      attr_reader :source

      def initialize(component:, inline_template:)
        super(
          component: component,
          path: inline_template.path,
          lineno: inline_template.lineno,
          extension: inline_template.language
        )

        @source = inline_template.source.dup
      end

      def type
        :inline
      end
    end

    class InlineCall < Template
      def initialize(component:, method_name:, defined_on_self:)
        super(
          component: component,
          this_format: ViewComponent::Base::VC_INTERNAL_DEFAULT_FORMAT,
          variant: method_name.to_s.include?("call_") ? method_name.to_s.sub("call_", "").to_sym : nil,
          method_name: method_name,
          defined_on_self: defined_on_self
        )
      end

      def type
        :inline_call
      end

      def compile_to_component
        @component.define_method(safe_method_name, @component.instance_method(@call_method_name))
      end
    end

    def compile_to_component
      @component.silence_redefinition_of_method(@call_method_name)

      # rubocop:disable Style/EvalWithLocation
      @component.class_eval <<-RUBY, @path, @lineno
      def #{@call_method_name}
        #{compiled_source}
      end
      RUBY
      # rubocop:enable Style/EvalWithLocation

      @component.define_method(safe_method_name, @component.instance_method(@call_method_name))
    end

    def safe_method_name_call
      return safe_method_name unless inline_call?

      "maybe_escape_html(#{safe_method_name}) " \
      "{ Kernel.warn('WARNING: The #{@component} component rendered HTML-unsafe output. " \
      "The output will be automatically escaped, but you may want to investigate.') } "
    end

    def requires_compiled_superclass?
      inline_call? && !defined_on_self?
    end

    def inline_call?
      type == :inline_call
    end

    def inline?
      type == :inline
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
