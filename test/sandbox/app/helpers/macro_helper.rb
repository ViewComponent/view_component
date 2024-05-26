# frozen_string_literal: true

module MacroHelper
  def message
    "Hello helper method"
  end

  def message_with_args(name)
    "Hello #{name}"
  end
end
