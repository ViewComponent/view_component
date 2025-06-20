# frozen_string_literal: true

require "action_view"
require "active_support/dependencies/autoload"

module ViewComponent
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Compiler
  autoload :CompileCache
  autoload :Config
  autoload :Deprecation
  autoload :InlineTemplate
  autoload :Instrumentation
  autoload :Preview
  autoload :Translatable

  if Rails.env.test?
    autoload :TestHelpers
    autoload :SystemSpecHelpers
    autoload :SystemTestHelpers
    autoload :TestCase
    autoload :SystemTestCase
  end
end

require "view_component/engine" if defined?(Rails::Engine)
