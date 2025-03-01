# frozen_string_literal: true

class InheritedConfigComponent < ConfigBaseComponent
  configure do |config|
    config.test_controller = "AnotherController"
  end
end
