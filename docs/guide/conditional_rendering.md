---
layout: default
title: Conditional rendering
parent: How-to guide
---

# Conditional rendering

Since 1.8.0
{: .label }

Components can implement a `#render?` method to be called after initialization to determine if the component should render.

Traditionally, the logic for whether to render a view could go in either the component template:

```erb
<% if user.requires_confirmation? %>
  <div class="alert">Please confirm your email address.</div>
<% end %>
```

or the view that renders the component:

```erb
<% if current_user.requires_confirmation? %>
  <%= render(ConfirmEmailComponent.new(user: current_user)) %>
<% end %>
```

Using the `#render?` hook simplifies the view:

```ruby
class ConfirmEmailComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="banner">
      Please confirm your email address.
    </div>
  ERB

  def initialize(user:)
    @user = user
  end

  def render?
    @user.requires_confirmation?
  end
end
```

```erb
<%= render(ConfirmEmailComponent.new(user: current_user)) %>
```

_To assert whether a component has been rendered, use `assert_component_rendered` / `refute_component_rendered` from `ViewComponent::TestHelpers`._
