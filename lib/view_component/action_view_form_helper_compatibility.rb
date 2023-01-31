# frozen_string_literal: true

module ViewComponent
  module ActionViewFormHelperCompatibility
    def self.included(base)
      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      attr_accessor :__vc_render_stack

      def render_in(view_context, &block)
        self.__vc_render_stack = view_context.__vc_render_stack || []
        self.__vc_render_stack.push(self)

        super
      ensure
        self.__vc_render_stack.pop
      end
    end
  end
end
