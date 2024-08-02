---
layout: default
title: Getting started
parent: How-to guide
nav_order: 1
---

# Getting started

## Conventions

- Components are subclasses of `ViewComponent::Base` and live in `app/components`. It's common practice to create and inherit from an `ApplicationComponent` that's a subclass of `ViewComponent::Base`.
- Component names end in -`Component`.
- Component module names are plural, as for controllers and jobs: `Users::AvatarComponent`
- Name components for what they render, not what they accept. (`AvatarComponent` instead of `UserComponent`)

## Installation

In `Gemfile`, add:

```ruby
gem "view_component"
```

## Quick start

Use the component generator to create a new ViewComponent.

The generator accepts a component name and a list of arguments:

```console
bin/rails generate component Example title

      invoke  test_unit
      create  test/components/example_component_test.rb
      create  app/components/example_component.rb
      create  app/components/example_component.html.erb
```

Available options to customize the generator are documented on the [Generators](/guide/generators.html) page.

## Implementation

A ViewComponent is a Ruby class that inherits from `ViewComponent::Base`:

```ruby
class ExampleComponent < ViewComponent::Base
  erb_template <<-ERB
    <span title="<%= @title %>"><%= content %></span>
  ERB

  def initialize(title:)
    @title = title
  end
end
```

Content passed to a ViewComponent as a block is captured and assigned to the `content` accessor.

Rendered in a view as:

```erb
<%= render(ExampleComponent.new(title: "my title")) do %>
  Hello, World!
<% end %>
```

Returning:

```html
<span title="my title">Hello, World!</span>
```

## `#with_content`

Since 2.31.0
{: .label }

String content can also be passed to a ViewComponent by calling `#with_content`:

```erb
<%= render(ExampleComponent.new(title: "my title").with_content("Hello, World!")) %>
```

## Rendering from controllers

It's also possible to render ViewComponents in controllers:

```ruby
def show
  render(ExampleComponent.new(title: "My Title"))
end
```

_Note: Content can't be passed to a component via a block in controllers. Instead, use `with_content`. In versions of Rails < 6.1, rendering a ViewComponent from a controller doesn't include the layout._

When using turbo frames with [turbo-rails](https://github.com/hotwired/turbo-rails), set `content_type` as `text/html`:

```ruby
def create
  render(ExampleComponent.new, content_type: "text/html")
end
```

### Rendering ViewComponents to strings inside controller actions

When rendering the same component multiple times for later reuse, use `render_in`:

```rb
class PagesController < ApplicationController
  def index
    # Doesn't work: triggers a `AbstractController::DoubleRenderError`
    # @reusable_icon = render IconComponent.new("close")

    # Doesn't work: renders the whole index view as a string
    # @reusable_icon = render_to_string IconComponent.new("close")

    # Works: renders the component as a string
    @reusable_icon = IconComponent.new("close").render_in(view_context)
  end
end
```

### Rendering ViewComponents outside of the view context

To render ViewComponents outside of the view context (such as in a background job, markdown processor, etc), instantiate a Rails controller:

```ruby
ApplicationController.new.view_context.render(MyComponent.new)
```
