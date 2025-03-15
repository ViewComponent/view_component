# frozen_string_literal: true

class ConfigurableComponent < ViewComponent::Base
  configure do |config|
    config.strip_trailing_whitespace = true
  end
end
