# frozen_string_literal: true

require "action_view"
require "active_support/dependencies/autoload"

module ViewComponent
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :CaptureCompatibility
  autoload :Compiler
  autoload :CompileCache
  autoload :ComponentError
  autoload :Config
  autoload :Deprecation
  autoload :Instrumentation
  autoload :Preview
  autoload :PreviewTemplateError
  autoload :TestHelpers
  autoload :SystemTestHelpers
  autoload :TestCase
  autoload :SystemTestCase
  autoload :TemplateError
  autoload :Translatable
end

require "view_component/engine" if defined?(Rails::Engine)
