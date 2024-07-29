# frozen_string_literal: true

module MacroHelper
  def message
    "Hello helper method"
  end

  def message_with_args(name)
    "Hello #{name}"
  end

  def message_with_kwargs(name:)
    "Hello #{name}"
  end

  def message_with_prefix(name)
    "Hello #{name}"
  end

  def message_with_named_prefix(name)
    "Hello #{name}"
  end

  def message_with_block
    yield
  end
end
