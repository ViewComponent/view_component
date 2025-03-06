# frozen_string_literal: true

class ConfigBaseComponent < ViewComponent::Base
  configure do |config|
    config.test_controller = "SomeController"
  end
end
