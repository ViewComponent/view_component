# frozen_string_literal: true

class HelpersApiComponent < ViewComponent::Base
  include ViewComponent::HelpersApi

  use_helper :message
end
