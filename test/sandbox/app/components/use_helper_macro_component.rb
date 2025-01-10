# frozen_string_literal: true

class UseHelperMacroComponent < ViewComponent::Base
  use_helper :message, from: MacroHelper
  use_helper :message_with_args, from: MacroHelper
  use_helper :message_with_kwargs, from: MacroHelper
  use_helper :message_with_prefix, from: MacroHelper, prefix: true
  use_helper :message_with_block, from: MacroHelper
  use_helper :message_with_named_prefix, from: MacroHelper, prefix: :named

  def block_content
    message_with_block { "Hello block helper method" }
  end
end
