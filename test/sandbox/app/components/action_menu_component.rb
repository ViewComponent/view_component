# frozen_string_literal: true

# Simplified ActionMenu component inspired by Primer::Alpha::ActionMenu
# Used to test deeply nested translation scoping
class ActionMenuComponent < ViewComponent::Base
  renders_one :list, ActionListComponent

  erb_template <<~ERB
    <div class="action-menu">
      <%= list %>
    </div>
  ERB
end
