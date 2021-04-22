---
layout: default
title: Content
parent: Building ViewComponents
---

# Content

Content passed to a ViewComponent as a block is captured and assigned to the `content` accessor.

```erb
<%= render(MyComponent.new) do %>
  <!-- This will be accessible via `content` -->
  <div>This is my content</div>
<% end %>
```

## `#with_content`

Content can also be passed to a ViewComponent by calling `#with_content`, which is especially useful when rendering components outside of views (such as in a controller, background job, script, etc):

```rb
class MyController < ApplicationController
  def show
    render(MyComponentBuilder.build)
  end
end

class MyComponentBuilder
  def self.build(condition = true)
    component = MyComponent.new

    if condition
      component.with_content("This is my content")
    else
      component.with_content("This is another content")
    end

    component
  end
end
```

`#with_content` also accepts passing another component as content:

```rb
component = MyComponent.new.with_content(SomeComponent.new)
...
render(component)
```

### Slots

`#with_content` is also available for slots:

```rb
class MyController < ApplicationController
  def show
    render(MySlotComponentBuilder.build)
  end
end

class MySlotComponentBuilder
  def self.build(condition = true)
    component = MyComponent.new

    if condition
      component.some_slot(args).with_content("This is my slot content")
    else
      component.another_slot(args).with_content("This is another slot content")
    end

    component.yet_another_slot(args).with_content(SomeComponent.new)

    component
  end
end
```
