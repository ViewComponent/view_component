class FailingComponentWithContent < ViewComponent::Base
  rescue_from ZeroDivisionError, with: :handle_error

  def handle_error
    "Something bad happened"
  end
end
