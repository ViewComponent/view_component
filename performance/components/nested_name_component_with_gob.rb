# frozen_string_literal: true

class Performance::NestedNameComponentWithGOB < Performance::NestedNameComponent
  prepend ViewComponent::GlobalOutputBuffer
end
