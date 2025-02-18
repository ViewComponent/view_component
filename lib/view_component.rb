# frozen_string_literal: true

require "action_view"
require "active_support/dependencies/autoload"

module ViewComponent
  extend ActiveSupport::Autoload

  autoload :ApplicationConfig
  autoload :Base
  autoload :CaptureCompatibility
  autoload :Compiler
  autoload :CompileCache
  autoload :ComponentError
  autoload :Deprecation
  autoload :InlineTemplate
  autoload :Instrumentation
  autoload :Preview
  autoload :TestHelpers
  autoload :SystemTestHelpers
  autoload :TestCase
  autoload :SystemTestCase
  autoload :Translatable
end

require "view_component/engine" if defined?(Rails::Engine)
