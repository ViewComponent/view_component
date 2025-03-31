---
layout: default
title: How it works
nav_order: 5
---

## How ViewComponent Works

### At application boot

When `ViewComponent::Base` is inherited from, `ViewComponent::Compiler.compile` compiles a component's template(s) into instance method(s) on the component:

```ruby
class MyComponent < ViewComponent::Base
end
```

```erb
<%= Time.now %>
```

Compiles to:

```ruby
class MyComponent < ViewComponent::Base
  def _call_my_component
    @output_buffer.append = (Time.now)
    @output_buffer
  end
end
```

### At component instantiation

Component initializer runs if defined. ViewComponent does not perform any actions.

### At render

When a ViewComponent is passed to `render`, Rails calls `render_in`, passing the current [ActionView::Context](https://api.rubyonrails.org/classes/ActionView/Context.html). `ActionView::Context` is used to provide access to the current controller, request, and helpers, which is why they cannot be referenced until a component is rendered.

First, ViewComponent calls the `before_render` method, which gives ViewComponents the opportunity to execute logic before render time but after initialization.

Second, ViewComponent calls `render?`, returning early with an empty string if `render?` returns false.

ViewComponent then renders the component template.
