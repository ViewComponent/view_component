---
layout: default
title: Known issues
---

# Known issues

## turbo_frame_tag double rendering or messed up HTML structure

When using `turbo_frame_tag` inside a ViewComponent, it will sometime render the template within the component twice. Depending on your component's HTML complexity, it can also mess up its DOM structure.

See [this issue](https://github.com/github/view_component/issues/1099) for additional information.

To fix this, you can use `tag.turbo_frame` instead of `turbo_frame_tag`. There is a caveat and that is:

To keep the same functionality `turbo_frame_tag(my_model)` provides, you need to write `tag.turbo_frame(id: dom_id(my_model))` instead.

## form_for compatibility

ViewComponent [isn't compatible](https://github.com/github/view_component/issues/241) with `form_for` helpers by default.

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.

## Forms don't use the default form builder

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/github/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```
