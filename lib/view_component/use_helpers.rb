# frozen_string_literal: true

module ViewComponent::UseHelpers
  extend ActiveSupport::Concern

  class_methods do
    def use_helpers(*args, from: nil)
      args.each do |helper_method|
        use_helper(helper_method, from: from)
      end
    end

    def use_helper(helper_method, from: nil)
      if from.nil?
        define_helpers_without_source(helper_method: helper_method)
      else
        define_helpers_with_source(helper_method: helper_method, source: from)
      end
    end

    private

    def define_helpers_without_source(helper_method:)
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def #{helper_method}(*args, **kwargs, &block)
          raise HelpersCalledBeforeRenderError if view_context.nil?
          __vc_original_view_context.#{helper_method}(*args, **kwargs, &block)
        end
      RUBY
      ruby2_keywords(helper_method) if respond_to?(:ruby2_keywords, true)
    end

    def define_helpers_with_source(helper_method:, source:)
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def #{helper_method}(*args, **kwargs, &block)
          raise HelpersCalledBeforeRenderError if view_context.nil?
          #{source}.instance_method(:#{helper_method}).bind(self).call(*args, **kwargs, &block)
        end
      RUBY
      ruby2_keywords(helper_method) if respond_to?(:ruby2_keywords, true)
    end
  end
end
