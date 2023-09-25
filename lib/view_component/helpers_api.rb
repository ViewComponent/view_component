module ViewComponent::HelpersApi
  extend ActiveSupport::Concern

  class_methods do
    def use_helper(*args)
      args.each do |helper|
        define_method helper do
          self.helpers.send(helper)
        end
      end
    end
  end
end
