# frozen_string_literal: true

class Performance::InlineTrailingWhitespaceComponent < ViewComponent::Base
  strip_trailing_whitespace

  erb_template <<~ERB

    <h1>Template does not contain any trailing whitespace</h1>
  ERB
end
