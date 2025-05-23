class Accordion::ItemComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
end
