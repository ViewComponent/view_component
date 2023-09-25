module ViewComponent::HelpersApi
  extend ActiveSupport::Concern

  class_methods do
    def use_helper(*args)
      args.each do |helper|
        define_method helper do |*args, &block|
          helpers.send(helper, *args, &block)
        end
      end
    end
  end
end
