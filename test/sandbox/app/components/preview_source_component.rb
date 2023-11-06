class PreviewSourceComponent < ViewComponent::Base
  def initialize(message: 'Hello world')
    @message = message
  end
end
