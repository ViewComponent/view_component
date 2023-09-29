# frozen_string_literal: true

class UseHelperComponent < ViewComponent::Base
  include ViewComponent::UseHelpers

  use_helper :message
end
