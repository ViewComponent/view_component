---
layout: default
title: Known issues
nav_order: 11
---

# Known issues

_There remain several known issues with ViewComponent. We'd be thrilled to see you consider solutions to these thorny bugs!_

## Forms don't use the default `FormBuilder`

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/viewcomponent/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```

## Incompatibility with `active_scaffold`

Due to `active_scaffold`'s [monkey-patching](https://github.com/activescaffold/active_scaffold/blob/0ada8b7a51bf608c4ade18983ce4494c963963f3/lib/active_scaffold/extensions/action_view_rendering.rb) of `render` that hasn't been updated to support renderable objects like ViewComponents, it's impossible to use `active_scaffold` alongside `view_component`.
