# frozen_string_literal: true

class Performance::NameComponentWithGOB < Performance::NameComponent
  prepend ViewComponent::GlobalOutputBuffer
end
