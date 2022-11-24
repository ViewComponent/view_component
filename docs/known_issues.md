---
layout: default
title: Known issues
nav_order: 9
---

# Known issues

## turbo_frame_tag double rendering or scrambled HTML structure

When using `turbo_frame_tag` inside a ViewComponent, the template may be rendered twice. See [https://github.com/github/view_component/issues/1099](https://github.com/github/view_component/issues/1099).

As a workaround, use `tag.turbo_frame` instead of `turbo_frame_tag`.

Note: For the same functionality as `turbo_frame_tag(my_model)`, use `tag.turbo_frame(id: dom_id(my_model))`.

## form_for compatibility

ViewComponent [isn't compatible](https://github.com/viewcomponent/view_component/issues/241) with `form_for` helpers by default.

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.

## Forms don't use the default form builder

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/viewcomponent/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```
