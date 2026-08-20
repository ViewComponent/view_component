# frozen_string_literal: true

# Renders a child component from an inline template rather than a sidecar file.
class CacheableInlineTemplateComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  erb_template <<~ERB
    <div class="cacheable-inline"><%= render CacheableChildComponent.new %></div>
  ERB
end
