class FailingComponentWithSlot < ViewComponent::Base
  include ViewComponent::SlotableV2

  renders_one :body

  rescue_from ZeroDivisionError, with: :handle_error

  def handle_error
    "Something bad happened"
  end
end
