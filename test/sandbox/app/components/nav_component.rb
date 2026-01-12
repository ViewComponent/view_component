# frozen_string_literal: true

# Level 2: Navigation component that contains an action menu
class NavComponent < ViewComponent::Base
  renders_one :action_menu, ActionMenuComponent

  erb_template <<~ERB
    <nav class="nav">
      <%= action_menu %>
    </nav>
  ERB
end
