# frozen_string_literal: true

class CacheableInlinePartialComponent < ViewComponent::Base
  erb_template <<~ERB
    <div><%= render "integration_examples/erb_partial" %></div>
  ERB
end
