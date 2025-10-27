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

## `#around_render`

Since 4.0.0.rc2
{: .label }

Define an `around_render` method to be called around the rendering of a component:

```ruby
# app/components/example_component.rb
class ExampleComponent < ViewComponent::Base
  def around_render
    MyInstrumenter.instrument do
      yield
    end
  end
end
```
