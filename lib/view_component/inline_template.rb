# frozen_string_literal: true

module ViewComponent # :nodoc:
  module InlineTemplate
    extend ActiveSupport::Concern
    Template = Struct.new(:source, :language, :path, :lineno)

    class_methods do
      def method_missing(method, *args)
        return super if !method.end_with?("_template")

        if defined?(@__vc_inline_template_defined) && @__vc_inline_template_defined
          raise MultipleInlineTemplatesError
        end

        if args.size != 1
          raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 1)"
        end

        ext = method.to_s.gsub("_template", "")
        template = args.first

        @__vc_inline_template_language = ext

        caller = caller_locations(1..1)[0]
        @__vc_inline_template = Template.new(
          template,
          ext,
          caller.absolute_path || caller.path,
          caller.lineno
        )

        @__vc_inline_template_defined = true
      end

      def respond_to_missing?(method, include_all = false)
        method.end_with?("_template") || super
      end

      def __vc_inline_template
        @__vc_inline_template if defined?(@__vc_inline_template)
      end

      def __vc_inline_template_language
        @__vc_inline_template_language if defined?(@__vc_inline_template_language)
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@__vc_inline_template_language, __vc_inline_template_language)
      end
    end
  end
end
