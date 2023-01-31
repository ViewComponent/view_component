# frozen_string_literal: true

module ViewComponent
  module FormHelperCompatibility
    def self.included(base)
      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      attr_accessor :__vc_render_stack

      def render_in(view_context, &block)
        self.__vc_render_stack =
          if view_context.respond_to?(:__vc_render_stack)
            view_context.__vc_render_stack || [self.__vc_original_view_context || view_context]
          else
            [view_context]
          end

        self.__vc_render_stack.push(self)

        super
      ensure
        self.__vc_render_stack.pop
      end

      # A wrapper around Rails' `form_with` helper that uses a custom form builder to maximize
      # compatibility. See the Rails docs for more information.
      def form_with(*args, builder: nil, **kwargs, &block)
        super(*args, builder: builder || ViewComponent::FormBuilder, **kwargs, &block)
      end

      # A wrapper around Rails' `form_for` helper that uses a custom form builder to maximize
      # compatibility. See the Rails docs for more information.
      def form_for(*args, builder: nil, **kwargs, &block)
        super(*args, builder: builder || ViewComponent::FormBuilder, **kwargs, &block)
      end
    end
  end
end
