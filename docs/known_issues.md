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

## Compatibility with Rails form helpers

ViewComponent [isn't compatible](https://github.com/viewcomponent/view_component/issues/241) with `form_for` helpers by default.

This means that it isn't supported to pass a form object to a view component.
It won't render as expected. Some content will be rendered twice.

Consider following options:

- Render a form end-to-end within one view component
- Render a [classical view partial](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials) within the view component, which includes the form
- Use `[FormBuilder](https://guides.rubyonrails.org/form_helpers.html#customizing-form-builders)` to create reusable form components.
  Note: There are multiple approaches how to implement a FormBuilder:
  - Classic approach (without ViewComponent)
  - Using ViewComponent (for example, [view_component-form gem](https://github.com/pantographe/view_component-form))
  - Using a lightweight implementation of ViewComponent. For example, [Primer ViewComponents](https://github.com/primer/view_components) implemented with [`ActsAsComponent`](https://github.com/primer/view_components/blob/main/lib/primer/forms/acts_as_component.rb) a lightweight version, which they use in the context of `FormBuilder`.

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.

## Forms don't use the default form builder

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/viewcomponent/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```
