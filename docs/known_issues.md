---
layout: default
title: Known issues
---

# Known issues

## form_for compatibility

ViewComponent [isn't currently compatible](https://github.com/github/view_component/issues/241) with `form_for` helpers.

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.
## Forms do not use the default form builder

Calls to form helpers such as `form_with` from ViewComponent [will not use the default form builder](https://github.com/github/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, you may want to consider passing a form builder into form helpers via the `builder` argument.

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```
