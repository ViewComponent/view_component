# frozen_string_literal: true

module ViewComponent::UseHelpers
  extend ActiveSupport::Concern

  class_methods do
    def use_helpers(*args, from: nil)
      args.each { |helper_method| use_helper(helper_method, from: from) }
    end

    def use_helper(helper_method, from: nil)
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def #{helper_method}(*args, &block)
          raise HelpersCalledBeforeRenderError if view_context.nil?

          #{define_helper(helper_method: helper_method, source: from)}
        end
      RUBY
      ruby2_keywords(helper_method) if respond_to?(:ruby2_keywords, true)
    end

    private

    def define_helper(helper_method:, source:)
      return "__vc_original_view_context.#{helper_method}(*args, &block)" unless source.present?

      "#{source}.instance_method(:#{helper_method}).bind(self).call(*args, &block)"
    end
  end
end
