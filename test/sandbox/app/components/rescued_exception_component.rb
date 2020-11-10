# frozen_string_literal: true

class RescuedExceptionComponent < ViewComponent::Base
  include ViewComponent::Slotable

  with_content_areas :head
  with_slot :body

  rescue_from ZeroDivisionError, with: :handle_error

  def call_inline
    "Inline renders are also rescued. #{10 / 0}"
  end

  def handle_error
    "Something bad happened"
  end

  class Body < ViewComponent::Slot
  end
end
