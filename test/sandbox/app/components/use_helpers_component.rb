# frozen_string_literal: true

class UseHelpersComponent < ViewComponent::Base
  include ViewComponent::UseHelpers

  use_helpers :message
end
