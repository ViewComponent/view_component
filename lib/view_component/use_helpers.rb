# frozen_string_literal: true

module ViewComponent::UseHelpers
  extend ActiveSupport::Concern

  class_methods do
    def use_helpers(*args)
      args.each do |helper_mtd|
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{helper_mtd}(*args, &block)
            raise HelpersCalledBeforeRenderError if view_context.nil?
            __vc_original_view_context&.send(#{helper_mtd.inspect}, *args, &block) || view_context.send(#{helper_mtd.inspect}, *args, &block)
          end
        RUBY

        ruby2_keywords(helper_mtd) if respond_to?(:ruby2_keywords, true)
      end
    end
  end
end
