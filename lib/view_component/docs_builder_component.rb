# frozen_string_literal: true

module ViewComponent
  class DocsBuilderComponent < Base
    class Section < Struct.new(:heading, :methods, :show_types, keyword_init: true)
      def initialize(heading: nil, methods: [], show_types: true)
        methods.sort_by! { |method| method[:name] }
        super
      end
    end

    class MethodDoc < ViewComponent::Base
      def initialize(method, section: Section.new(show_types: true))
        @method = method
        @section = section
      end

      def show_types?
        @section.show_types
      end

      def deprecated?
        @method.tag(:deprecated).present?
      end

      def suffix
        " (Deprecated)" if deprecated?
      end

      def types
        " → [#{@method.tag(:return).types.join(",")}]" if @method.tag(:return)&.types && show_types?
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
          #{separator}#{signature_or_name}#{types}#{suffix}

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
