# frozen_string_literal: true

module ViewComponent::UseHelpers
  extend ActiveSupport::Concern

  class_methods do
    def use_helpers(*args, from: nil)
      helper_source = from
      args.each do |helper_method|
        if helper_source.nil?
          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{helper_method}(*args, &block)
              raise HelpersCalledBeforeRenderError if view_context.nil?
              __vc_original_view_context.#{helper_method}(*args, &block)
            end
          RUBY
        else
          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{helper_method}(*args, &block)
              #{helper_source}.instance_method(:#{helper_method}).bind(self).call(*args, &block)
            end
          RUBY
        end

        ruby2_keywords(helper_method) if respond_to?(:ruby2_keywords, true)
      end
    end
  end
end
