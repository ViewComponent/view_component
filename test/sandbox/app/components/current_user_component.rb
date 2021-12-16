# frozen_string_literal: true

class CurrentUserComponent < ViewComponent::Base
  delegate :current_user, to: :helpers
end
