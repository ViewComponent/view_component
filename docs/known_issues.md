---
layout: default
title: Known issues
---

# Known issues

## form_for compatibility

ViewComponent [isn't compatible](https://github.com/github/view_component/issues/241) with `form_for` helpers by default.

### Using a Global Output Buffer

Added in 2.52.0
{: .label }

Experimental
{: .label .label-yellow }

One possible solution to the form helpers problem is to use a single, global output buffer. For details, please refer to [this pull request](https://github.com/github/view_component/pull/1307).

The global output buffer behavior is opt-in. Prepend the `ViewComponent::GlobalOutputBuffer` module into individual component classes to use it.

For example:

```ruby
class MyComponent < ViewComponent::Base
  prepend ViewComponent::GlobalOutputBuffer
end
```

It is also possible to enable the global output buffer globally by setting the `config.view_component.use_global_output_buffer` setting to `true` in your Rails config.

## Inconsistent controller rendering behavior between Rails versions

In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout.

## Forms don't use the default form builder

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/github/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```
