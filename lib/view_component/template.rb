# frozen_string_literal: true

module ViewComponent
  class Template
    DEFAULT_FORMAT = :html
    private_constant :DEFAULT_FORMAT

    DataWithSource = Struct.new(:format, :identifier, :short_identifier, :type, keyword_init: true)

    attr_reader :details, :path

    delegate :virtual_path, to: :@component
    delegate :format, :variant, to: :@details

    def initialize(component:, details:, lineno: nil, path: nil)
      @component = component
      @details = details
      @lineno = lineno
      @path = path
    end

    class File < Template
      def initialize(component:, details:, path:)
        @strip_annotation_line = false

        # Rails 8.1 added a newline to compiled ERB output (rails/rails#53731).
        # Use -1 to compensate for correct line numbers in stack traces.
        # However, negative line numbers cause segfaults when Ruby's coverage
        # is enabled (bugs.ruby-lang.org/issues/19363). In that case, strip the
        # annotation line from compiled source instead.
        lineno =
          if Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR > 0 && details.handler == :erb
            if coverage_running? && ActionView::Base.annotate_rendered_view_with_filenames
              @strip_annotation_line = true
              0
            else
              -1
            end
          else
            0
          end

        super(
          component: component,
          details: details,
          path: path,
          lineno: lineno
        )
      end

      def type
        :file
      end

      # Load file each time we look up #source in case the file has been modified
      def source
        ::File.read(@path)
      end

      private

      def compiled_source
        result = super
        # Strip the annotation line to maintain correct line numbers when coverage
        # is running (avoids segfault from negative lineno)
        result = result.sub(/\A[^\n]*\n/, "") if @strip_annotation_line
        result
      end
    end

    class Inline < Template
      attr_reader :source

      def initialize(component:, inline_template:)
        details = ActionView::TemplateDetails.new(nil, inline_template.language.to_sym, nil, nil)

        # Rails 8.1 added a newline to compiled ERB output (rails/rails#53731).
        # Subtract 1 to compensate for correct line numbers in stack traces.
        # Inline templates start at line 2+ (defined inside a class), so this
        # won't result in negative line numbers that cause segfaults with coverage.
        lineno =
          if Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR > 0 && details.handler == :erb
            inline_template.lineno - 1
          else
            inline_template.lineno
          end

        super(
          component: component,
          details: details,
          path: inline_template.path,
          lineno: lineno,
        )

        @source = inline_template.source.dup
      end

      def type
        :inline
      end
    end

    class InlineCall < Template
      def initialize(component:, method_name:, defined_on_self:)
        variant = method_name.to_s.include?("call_") ? method_name.to_s.sub("call_", "").to_sym : nil
        details = ActionView::TemplateDetails.new(nil, nil, nil, variant)

        super(component: component, details: details)

        @call_method_name = method_name
        @defined_on_self = defined_on_self
      end

      def type
        :inline_call
      end

      def compile_to_component
        @component.define_method(safe_method_name, @component.instance_method(@call_method_name))
      end

      def safe_method_name_call
        m = safe_method_name
        proc do
          __vc_maybe_escape_html(send(m)) do
            Kernel.warn("WARNING: The #{self.class} component rendered HTML-unsafe output. " \
                          "The output will be automatically escaped, but you may want to investigate.")
          end
        end
      end

      def defined_on_self?
        @defined_on_self
      end
    end

    def compile_to_component
      @component.silence_redefinition_of_method(call_method_name)

      # rubocop:disable Style/EvalWithLocation
      @component.class_eval <<~RUBY, @path, @lineno
        def #{call_method_name}
          #{compiled_source}
        end
      RUBY
      # rubocop:enable Style/EvalWithLocation

      @component.define_method(safe_method_name, @component.instance_method(@call_method_name))
    end

    def coverage_running?
      defined?(Coverage) && Coverage.running?
    end

    def safe_method_name_call
      m = safe_method_name
      proc { send(m) }
    end

    def requires_compiled_superclass?
      inline_call? && !defined_on_self?
    end

    def inline_call?
      type == :inline_call
    end

    def default_format?
      format.nil? || format == DEFAULT_FORMAT
    end
    alias_method :html?, :default_format?

    def call_method_name
      @call_method_name ||=
        ["call", (normalized_variant_name if variant.present?), (format unless default_format?)]
          .compact.join("_").to_sym
    end

    def safe_method_name
      "_#{call_method_name}_#{@component.name.underscore.gsub("/", "__")}"
    end

    def normalized_variant_name
      variant.to_s.gsub("-", "__")
    end

    private

    def compiled_source
      handler = details.handler_class
      this_source = source
      this_source.rstrip! if @component.strip_trailing_whitespace?

      short_identifier = defined?(Rails.root) ? @path.sub("#{Rails.root}/", "") : @path
      format = self.format || DEFAULT_FORMAT
      type = ActionView::Template::Types[format]

      handler.call(DataWithSource.new(format:, identifier: @path, short_identifier:, type:), this_source)
    end
  end
end
