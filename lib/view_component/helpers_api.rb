# frozen_string_literal: true

module ViewComponent::UseHelper
  def use_helper(*args)
    args.each do |helper_mtd|
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
      def #{helper_mtd} do |*args, &block|
        helpers.send(#{helper_mtd}, *args, &block)
      end
      RUBY
      
      ruby2_keywords(helper_mtd) if respond_to?(:ruby2_keywords, true)
    end
  end
end
