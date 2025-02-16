# frozen_string_literal: true

class ConfigBaseComponent < ViewComponent::Base
  configure do
    preview.paths = ["expected_path"]
  end
end
