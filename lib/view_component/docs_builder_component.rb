# frozen_string_literal: true

module ViewComponent
  class DocsBuilderComponent < Base
    class Section < Struct.new(:heading, :methods, :error_klasses, :show_types, keyword_init: true)
      def initialize(heading: nil, methods: [], error_klasses: [], show_types: true)
        methods.sort_by! { |method| method[:name] }
        error_klasses.sort!
        super
      end
    end

    class ErrorKlassDoc < ViewComponent::Base
      def initialize(error_klass, _show_types)
        @error_klass = error_klass
      end

      def klass_name
        @error_klass.gsub("ViewComponent::", "").gsub("::MESSAGE", "")
      end

      def error_message
        ViewComponent.const_get(@error_klass)
      end

      def call
        <<~DOCS.chomp
          `#{klass_name}`

          #{error_message}
        DOCS
      end
    end

    class MethodDoc < ViewComponent::Base
      def initialize(method, show_types = true)
        @method = method
        @show_types = show_types
      end

      def deprecated?
        @method.tag(:deprecated).present?
      end

      def suffix
        " (Deprecated)" if deprecated?
      end

      def types
        " → [#{@method.tag(:return).types.join(",")}]" if @method.tag(:return)&.types && @show_types
      end

      def signature_or_name
        @method.signature ? @method.signature.gsub("def ", "") : @method.name
      end

      def separator
        @method.sep
      end

      def docstring
        @method.docstring
      end

      def deprecation_text
        @method.tag(:deprecated)&.text
      end

      def docstring_and_deprecation_text
        <<~DOCS.strip
          #{docstring}

          #{"_#{deprecation_text}_" if deprecated?}
        DOCS
      end

      def call
        <<~DOCS.chomp
          `#{separator}#{signature_or_name}`#{types}#{suffix}

          #{docstring_and_deprecation_text}
        DOCS
      end
    end

    # { heading: String, public_only: Boolean, show_types: Boolean}
    def initialize(sections: [])
      @sections = sections
    end

    # deprecation
    # return
    # only public methods
    # sig with types or name
  end
end
