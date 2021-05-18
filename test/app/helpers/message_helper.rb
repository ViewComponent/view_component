# frozen_string_literal: true

module MessageHelper
  def message
    "Hello helper method"
  end

  def message_from_member_var
    "Hello #{@user_name}"
  end
end
