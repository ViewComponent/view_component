# frozen_string_literal: true

class LambdaSlotInnerComponent < ViewComponent::Base
  renders_one :aside, ->(&block) do
    content_tag :div, class: "lambda-slot-aside", &block
  end

  erb_template <<~ERB
    <div class="lambda-slot-inner">
      <%= aside %>
    </div>
  ERB
end
