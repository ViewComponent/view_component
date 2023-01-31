# frozen_string_literal: true

module ViewComponent
  module FormBuilderMixin
    def initialize(*args)
      super

      @render_stack = @template.__vc_render_stack
    end

    ActionView::Helpers::FormBuilder.field_helpers.each do |field_helper|
      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{field_helper}(*args, &block)
          old_template = @template
          @template = @render_stack.last
          super
        ensure
          @template = old_template
        end
      RUBY

      ruby2_keywords(field_helper) if respond_to?(:ruby2_keywords)
    end
  end
end
