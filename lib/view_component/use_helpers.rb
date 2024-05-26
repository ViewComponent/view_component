# frozen_string_literal: true

module ViewComponent::UseHelpers
  extend ActiveSupport::Concern

  class_methods do
    def use_helpers(*args, from: nil)
      helper_source = from
      if helper_source.nil?
        define_helpers_without_source(*args)
      else
        define_helpers_with_source(*args, source: helper_source)
      end
    end

    private

    def define_helpers_without_source(*args)
      args.each do |helper_method|
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{helper_method}(*args, &block)
            raise HelpersCalledBeforeRenderError if view_context.nil?
            __vc_original_view_context.#{helper_method}(*args, &block)
          end
        RUBY
        ruby2_keywords(helper_method) if respond_to?(:ruby2_keywords, true)
      end
    end

    def define_helpers_with_source(*args, source:)
      args.each do |helper_method|
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{helper_method}(*args, &block)
            #{source}.instance_method(:#{helper_method}).bind(self).call(*args, &block)
          end
        RUBY
        ruby2_keywords(helper_method) if respond_to?(:ruby2_keywords, true)
      end
    end
  end
end
