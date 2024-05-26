# frozen_string_literal: true

class UseHelpersMacroComponent < ViewComponent::Base
  use_helpers :message, :message_with_args, from: MacroHelper
end
