# frozen_string_literal: true

module ViewComponent
  class Metal
    undef :p

    def self.tag_elements
      @@tag_elements ||= ActionView::Helpers::TagHelper::TagBuilder.instance_methods(false)
    end

    def render_in(view_context)
      raise ArgumentError, "#{self.class} does not support passing a block" if block_given?
      @view_context = view_context
      @view_context.with_output_buffer { call }.to_s
    end

    def plain(string)
      @view_context.concat(string)
    end

    def method_missing(method, ...)
      if self.class.tag_elements.include?(method)
        @view_context.concat @view_context.tag.__send__(method, ...)
      elsif @view_context.respond_to?(method, false)
        @view_context.__send__(method, ...)
      else
        super
      end
    end

    def respond_to_missing?(method, include_all = false)
      return true if super
      return true if self.class.tag_elements.include?(method)
      @view_context.respond_to?(method, false)
    end
  end
end
