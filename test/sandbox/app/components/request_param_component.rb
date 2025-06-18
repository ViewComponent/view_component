class RequestParamComponent < ViewComponent::Base
  def initialize(request:)
    @request = request
  end

  def call
    @request.html_safe
  end
end
