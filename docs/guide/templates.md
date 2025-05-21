---
layout: default
title: Templates
parent: How-to guide
---

# Templates

ViewComponents wrap a template (or several, if using [variants](https://guides.rubyonrails.org/layouts_and_rendering.html#the-variants-option)), defined in one of several ways:

## Inline

Since 3.0.0
{: .label }

To define a template inside a component, call the `.TEMPLATE_HANDLER_template` macro:

```ruby
class InlineErbComponent < ViewComponent::Base
  erb_template <<~ERB
    <h1>Hello, <%= @name %>!</h1>
  ERB

  def initialize(name)
    @name = name
  end
end
```

### Interpolations

When using Slim, interpolations have to be escaped, or they'll be evaluated in the context of the ViewComponent class.

```ruby
class InlineSlimComponent < ViewComponent::Base
  slim_template <<~SLIM
    p Hello, #{name}!
    p Hello, \#{name}!
  SLIM

  def name
    "World"
  end
end
```

will render:

    <p>Hello InlineSlimComponent!</p>
    <p>Hello World!</p>

## Sibling file

Place template file next to the component:

```console
app/components
├── ...
├── example_component.rb
├── example_component.html.erb
├── ...
```

## Subdirectory

Since 2.7.0
{: .label }

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

## `#call`

Since 1.16.0
{: .label }

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

## Inherited

Since 2.19.0
{: .label }

Component subclasses inherit the parent component's template if they don't define their own template.

```ruby
# If MyLinkComponent doesn't define a template,
# it will fall back to the `LinkComponent` template.
class MyLinkComponent < LinkComponent
end
```

### Rendering parent templates

Since 2.55.0
{: .label }

To render a parent component's template from a subclass' template, use `#render_parent`:

```erb
<%# my_link_component.html.erb %>
<div class="base-component-template">
  <%= render_parent %>
</div>
```

If the parent supports the current variant, the variant will automatically be rendered.

`#render_parent` also works with inline templates:

```ruby
class MyComponent < ViewComponent::Base
  erb_template <<~ERB
    <div>
      <%= render_parent %>
    </div>
  ERB
end
```

Keep in mind that `#render_parent` doesn't return a string. If a string is desired, eg. inside a `#call` method, call `#render_parent_to_string` instead. For example:

```ruby
class MyComponent < ViewComponent::Base
  def call
    content_tag("div") do
      render_parent_to_string
    end
  end
end
```

## Trailing whitespace

Code editors commonly add a trailing newline character to source files in keeping with the Unix standard. Including trailing whitespace in component templates can result in unwanted whitespace in the HTML, eg. if the component is rendered before the period at the end of a sentence.

To strip trailing whitespace from component templates, use the `strip_trailing_whitespace` class method.

```ruby
class MyComponent < ViewComponent::Base
  # do strip whitespace
  strip_trailing_whitespace

  # don't strip whitespace
  strip_trailing_whitespace(false)
end
```
