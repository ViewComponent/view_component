# frozen_string_literal: true

class MutatedStringInlineComponent < ViewComponent::Base
  erb_template <<~ERB
    <%= "a" << "b" %>
  ERB
end
