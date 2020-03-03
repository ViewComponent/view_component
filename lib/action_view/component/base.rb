# frozen_string_literal: true

module ActionView
  module Component
    class Base < ViewComponent::Base
      include ActiveModel::Validations

      def before_render_check
        validate!
      end
    end
  end
end
