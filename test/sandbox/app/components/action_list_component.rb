# frozen_string_literal: true

# Simplified ActionList component inspired by Primer::Alpha::ActionList
# Used to test deeply nested translation scoping
class ActionListComponent < ViewComponent::Base
  renders_many :items, MenuItemComponent

  erb_template <<~ERB
    <ul class="action-list">
      <% items.each do |item| %>
        <%= item %>
      <% end %>
    </ul>
  ERB
end
