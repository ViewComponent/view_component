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

Passing a form object (often `f`) to a ViewComponent works for simple cases like `f.text_field :name`. Content may be ill-ordered or duplicated in complex cases, such as passing blocks to form helpers or when nesting components.

Some workarounds include:

- Render an entire form within a single ViewComponent.
- Render a [partial](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials) within the ViewComponent which includes the form.
- Use a [custom `FormBuilder`](https://guides.rubyonrails.org/form_helpers.html#customizing-form-builders) to create reusable form components:
  - Using FormBuilder with [Action View helpers](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html).
  - Using a FormBuilder overriding all field helpers to render a ViewComponent so each field can be customized individually (for example, [view_component-form](https://github.com/pantographe/view_component-form)).
  - Using a lightweight re-implementation of ViewComponent. For example, [Primer ViewComponents](https://github.com/primer/view_components) implemented [`ActsAsComponent`](https://github.com/primer/view_components/blob/main/lib/primer/forms/acts_as_component.rb) which is used in the context of `FormBuilder`.

## Forms don't use the default `FormBuilder`

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/viewcomponent/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.
