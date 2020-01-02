# frozen_string_literal: true

module ActionView
  module Component # :nodoc:
    module ContentFor
      def content_for(attr, content = nil, options = {}, &block)
        unless respond_to?(attr)
          raise StandardError.new "Called content_for with unknown attribute '#{attr}'"
        end

        if block_given?
          options = content if content
          content = view_context.capture(&block)
        end

        existing_content = send(attr)
        if existing_content && !options[:flush]
          content = existing_content + content
        end

        set_attribute(attr, content)
        nil
      end

      private

      def set_attribute(attr, value)
        setter_name = "#{attr}=".to_sym
        instance_variable_name = "@#{attr}".to_sym
        if respond_to? setter_name
          send(setter_name, value)
        else
          instance_variable_set(instance_variable_name, value)
        end
      end
    end
  end
end
