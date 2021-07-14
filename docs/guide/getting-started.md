---
layout: default
title: Getting started
parent: Building ViewComponents
nav_order: 1
---

# Getting started

## Conventions

- Components are subclasses of `ViewComponent::Base` and live in `app/components`. It's common practice to create and inherit from an `ApplicationComponent` that is a subclass of `ViewComponent::Base`.
- Component module names are plural, as for controllers and views: `Users::Avatar`
- Name components after the UI element they render.

## Installation

In `Gemfile`, add:

```ruby
gem "view_component", require: "view_component/engine"
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

A ViewComponent is a Ruby file and corresponding template file with the same base name:

```ruby
# app/components/example_component.rb
class ExampleComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
end
```

```erb
<%# app/components/example_component.html.erb %>
<span title="<%= @title %>"><%= content %></span>
```

Content passed to a ViewComponent as a block is captured and assigned to the `content` accessor.

Rendered in a view as:

```erb
<%# app/views/home/index.html.erb %>
<%= render(ExampleComponent.new(title: "my title")) do %>
  Hello, World!
<% end %>
```

Returning:

```html
<span title="my title">Hello, World!</span>
```

## `#with_content`

String content can also be passed to a ViewComponent by calling `#with_content`:

```erb
<%# app/views/home/index.html.erb %>
<%= render(ExampleComponent.new(title: "my title").with_content("Hello, World!")) %>
```

## Rendering from controllers

It's also possible to render ViewComponents in controllers:

```ruby
# app/controllers/home_controller.rb
def show
  render(ExampleComponent.new(title: "My Title")) { "Hello, World!" }
end
```

_In versions of Rails < 6.1, rendering a ViewComponent from a controller does not include the layout._
