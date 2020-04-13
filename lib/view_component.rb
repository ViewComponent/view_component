# frozen_string_literal: true
require "action_view"
require "active_support/dependencies/autoload"

module ViewComponent
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Preview
  autoload :TestHelpers
  autoload :TestCase
  autoload :RenderMonkeyPatch
  autoload :RenderingMonkeyPatch
  autoload :TemplateError
end
