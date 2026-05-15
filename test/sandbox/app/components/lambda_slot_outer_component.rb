# frozen_string_literal: true

class LambdaSlotOuterComponent < ViewComponent::Base
  renders_one :inner, LambdaSlotInnerComponent

  erb_template <<~ERB
    <div class="lambda-slot-outer">
      <%= inner %>
    </div>
  ERB
end
