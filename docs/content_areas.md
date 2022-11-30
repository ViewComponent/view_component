---
nav_exclude: true
---

# Content areas

_Note: The content_areas API is soft-deprecated, and will soon be deprecated in favor of [Slots](/guide/slots.html)._

ViewComponents can declare additional content areas. For example:

```ruby
# app/components/modal_component.rb
class ModalComponent < ViewComponent::Base
  with_content_areas :header, :body
end
```

```erb
<%# app/components/modal_component.html.erb %>
<div class="modal">
  <div class="header"><%= header %></div>
  <div class="body"><%= body %></div>
</div>
```

Rendered in a view as:

```erb
<%= render(ModalComponent.new) do |component| %>
  <% component.with(:header) do %>
    Hello Jane
  <% end %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

Returning:

```html
<div class="modal">
  <div class="header">Hello Jane</div>
  <div class="body"><p>Have a great day.</p></div>
</div>
```
