# frozen_string_literal: true

class UseHelpersComponent < ViewComponent::Base
  # include ViewComponent::UseHelpers
  # This module is now part of ViewComponent::Base, but the tests that
  # use this component are testing the functionality the module provides.
  use_helpers :message
end
