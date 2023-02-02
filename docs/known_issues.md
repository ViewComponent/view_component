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

Passing a form object reference (usually `f`) to a ViewComponent works for simple cases, like `f.text_field :name`.
Content will be ill-ordered or duplicated in complex cases (such as passing blocks to form helpers or when nesting components).

Consider following options:

- Render a form end-to-end within one ViewComponent
- Render a [classical view partial](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials) within the ViewComponent, which includes the form
- Use a [custom `FormBuilder`](https://guides.rubyonrails.org/form_helpers.html#customizing-form-builders) to create reusable form components.
  Note: There are multiple approaches how to implement a FormBuilder:
  - Without FormBuilder at all, where one would [use Action View helpers](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html) to create the desired output
  - Using a FormBuilder that overrides all field helpers to render a ViewComponent, so that you can customize each field individually (for example, [view_component-form gem](https://github.com/pantographe/view_component-form))
  - Using a lightweight implementation of ViewComponent. For example, [Primer ViewComponents](https://github.com/primer/view_components) implemented with [`ActsAsComponent`](https://github.com/primer/view_components/blob/main/lib/primer/forms/acts_as_component.rb) a lightweight version, which they use in the context of `FormBuilder`.

## Forms don't use the default `FormBuilder`

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/viewcomponent/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.
