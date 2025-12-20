# frozen_string_literal: true

# Level 0: Wraps a nav component (for 5-level deep testing)
class SectionComponent < ViewComponent::Base
  renders_one :nav, NavComponent

  erb_template <<~ERB
    <section class="section">
      <%= nav %>
    </section>
  ERB
end
