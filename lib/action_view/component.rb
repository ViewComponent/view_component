# frozen_string_literal: true

require "active_model"
require "action_view"
require "active_support/dependencies/autoload"
require "action_view/component/engine"

module ActionView
  module Component
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :Conversion
    autoload :Preview
    autoload :Previewable
    autoload :TestHelpers
    autoload :TestCase
    autoload :RenderMonkeyPatch
    autoload :TemplateError
  end
end

ActiveModel::Conversion.include ActionView::Component::Conversion
