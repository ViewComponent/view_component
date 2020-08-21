class ActionTextComponent < ViewComponent::Base

  attr_reader :model

  def initialize(model:)
    @model = model
  end

end