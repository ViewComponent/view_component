# frozen_string_literal: true

# Simplified MenuItem component inspired by Primer::Alpha::ActionList::Item
# Used to test deeply nested translation scoping
class MenuItemComponent < ViewComponent::Base
  erb_template <<~ERB
    <li class="menu-item">
      <%= content %>
    </li>
  ERB
end
