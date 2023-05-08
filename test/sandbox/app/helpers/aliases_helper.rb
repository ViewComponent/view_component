# frozen_string_literal: true

module AliasesHelper
  def sandbox_slots(*args, **kwargs, &block)
    render SlotsComponent.new(*args, **kwargs), &block
  end
end
