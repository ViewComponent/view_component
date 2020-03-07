# frozen_string_literal: true
require "action_view"
require "active_support/dependencies/autoload"

module ViewComponent
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Conversion
  autoload :Preview
  autoload :Previewable
  autoload :TestHelpers
  autoload :TestCase
  autoload :RenderMonkeyPatch
  autoload :Rendering
  autoload :RenderingMonkeyPatch
  autoload :ViewPaths
end

module ActionView
  module Component
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :Preview
    autoload :TestCase
  end
end

ActiveModel::Conversion.include ViewComponent::Conversion
