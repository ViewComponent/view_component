class SlotableTestComponent < ViewComponent::Base
  renders_one :tag, TagComponent

  def initialize(image)
    @image = image
  end
end
