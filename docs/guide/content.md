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

## `#with_content` (Experimental)

Content can also be passed to a ViewComponent by calling `#with_content`. This is especially useful to build UI when you don't have a `view_context` available and render it at a later moment.

```rb
component = MyComponent.new.with_content("This is my content")
...
render(component)
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
component = MyComponent.new
component.some_slot(args).with_content("This is my slot content")
component.another_slot(args).with_content("This is Nother slot content")
component.yet_another_slot(args).with_content(SomeComponent.new)
...
render(component)
```
