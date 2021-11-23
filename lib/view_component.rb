# frozen_string_literal: true

require "action_view"
require "active_support/dependencies/autoload"

module ViewComponent
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Compiler
  autoload :CompileCache
  autoload :ComponentError
  autoload :Instrumentation
  autoload :Preview
  autoload :PreviewTemplateError
  autoload :TestHelpers
  autoload :TestCase
  autoload :TemplateError
  autoload :Translatable
end

# In the case of manually loading, "view_component/engine" is loaded first,
# so there is no need to load it.
require "view_component/engine" if defined?(Rails::Engine) && !defined?(ViewComponent::Engine)
