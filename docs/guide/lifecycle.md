---
layout: default
title: Lifecycle
parent: How-to guide
---

# Lifecycle

## `#before_render`

Since 2.8.0
{: .label }

Define a `before_render` method to be called before a component is rendered, when `helpers` is able to be used:

```ruby
# app/components/example_component.rb
class ExampleComponent < ViewComponent::Base
  def before_render
    @my_icon = helpers.star_icon
  end
end
```
