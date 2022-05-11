---
layout: default
title: Templates
parent: Guide
---

# Templates

ViewComponents wrap a template (or several, if using [variants](https://guides.rubyonrails.org/layouts_and_rendering.html#the-variants-option)), defined in one of several ways:

## Sibling file

The simplest option is to place the view next to the Ruby component:

```console
app/components
├── ...
├── example_component.rb
├── example_component.html.erb
├── ...
```

## Subdirectory

As an alternative, views and other assets can be placed in a subdirectory with the same name as the component:

```console
app/components
├── ...
├── example_component.rb
├── example_component
|   ├── example_component.html.erb
├── ...
```

To generate a component with a sidecar directory, use the `--sidecar` flag:

```console
bin/rails generate component Example title --sidecar
  invoke  test_unit
  create  test/components/example_component_test.rb
  create  app/components/example_component.rb
  create  app/components/example_component/example_component.html.erb
```

## Inline

ViewComponents can render without a template file, by defining a `call` method:

```ruby
# app/components/inline_component.rb
class InlineComponent < ViewComponent::Base
  def call
    if active?
      link_to "Cancel integration", integration_path, method: :delete
    else
      link_to "Integrate now!", integration_path
    end
  end
end
```

It's also possible to define methods for Action Pack variants (`phone` in this case):

```ruby
class InlineVariantComponent < ViewComponent::Base
  def call_phone
    link_to "Phone", phone_path
  end

  def call
    link_to "Default", default_path
  end
end
```

_**Note**: `call_*` methods must be public._

To override the `variant` set by the request, use `with_variant`:

```erb
<%= render InlineVariantComponent.new.with_variant(:phone) %>
```

## Inherited

Component subclasses inherit the parent component's template if they don't define their own template.

```ruby
# If MyLinkComponent doesn't define a template,
# it will fall back to the `LinkComponent` template.
class MyLinkComponent < LinkComponent
end
```

### Rendering parent templates

Subclasses that wish to render the parent's template may do so by calling the `render_parent` helper method.

```ruby
<%# my_link_component.html.erb %>
<div class="base-component-template">
  <% render_parent %>
</div>
```
