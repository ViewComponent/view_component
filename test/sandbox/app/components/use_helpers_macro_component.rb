# frozen_string_literal: true

class UseHelpersMacroComponent < ViewComponent::Base
  use_helpers :message, :message_with_args, :message_with_kwargs, :message_with_block, from: MacroHelper

  def block_content
    message_with_block { "Hello block helper method" }
  end
end
