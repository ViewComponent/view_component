class FailingComponentInline < ViewComponent::Base
  rescue_from ZeroDivisionError, with: :handle_error

  def call
    "Might break: #{10 / 0}"
  end

  def handle_error
    "Something bad happened"
  end
end
