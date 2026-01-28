---
layout: default
title: Overview
nav_order: 1
---

# ViewComponent (v{{ site.data.library.version }})

A framework for creating reusable, testable & encapsulated view components, built to integrate seamlessly with Ruby on Rails.

_As of version 4, ViewComponent is in Long-Term Support and considered feature-complete._

## What's a ViewComponent?

ViewComponents are Ruby objects used to build markup. Think of them as an evolution of the presenter pattern, inspired by [React](https://reactjs.org/docs/react-component.html).

ViewComponents are objects that encapsulate a template:

```ruby
# app/components/message_component.rb
class MessageComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end
end
```

```erb
<%# app/components/message_component.html.erb %>
<h1>Hello, <%= @name %>!<h1>
```

Which is rendered by calling:

```erb
<%# app/views/demo/index.html.erb %>
<%= render(MessageComponent.new(name: "World")) %>
```

Returning:

```html
<h1>Hello, World!</h1>
```

## Why use ViewComponents?

### TL;DR

ViewComponents work best for templates that are reused or benefit from being tested directly. Partials and templates with significant amounts of embedded Ruby often make good ViewComponents.

### Single responsibility

Rails applications often scatter view-related logic across models, controllers, and helpers, diluting their intended responsibilities. ViewComponents consolidate the logic needed for a template into a single class, resulting in a cohesive object that is easy to understand.

ViewComponent methods are implemented within the scope of the template, encapsulating them in proper object-oriented fashion. This cohesion is especially evident when multiple methods are needed for a single view.

### Testing

ViewComponent was designed with the intention that all components should be unit tested. In the GitHub codebase, ViewComponent unit tests are over 100x faster than similar controller tests.

With ViewComponent, integration tests can be reserved for end-to-end assertions, with permutations covered at the unit level.

For example, to test the `MessageComponent` above:

```ruby
class MessageComponentTest < GitHub::TestCase
  include ViewComponent::TestHelpers

  test "renders message" do
    render_inline(MessageComponent.new(name: "World"))

    assert_selector "h1", text: "Hello, World!"
  end
end
```

ViewComponent unit tests leverage the Capybara matchers library, allowing for complex assertions traditionally reserved for controller and browser tests.

### Data Flow

Traditional Rails templates have an implicit interface, making it hard to reason about their dependencies. This can lead to subtle bugs when rendering the same template in different contexts.

ViewComponents use a standard Ruby initializer that clearly defines what's needed to render, making reuse easier and safer than partials.

### Performance

Based on several [benchmarks](https://github.com/viewcomponent/view_component/blob/main/performance/partial_benchmark.rb), ViewComponents are ~2.5x faster than partials:

```console
Comparison:
  component:     6498.1 i/s
    partial:     2676.5 i/s - 2.50x  slower
```

### Code quality

Template code often fails basic Ruby standards: long methods, deep conditional nesting, and mystery guests abound.

ViewComponents are Ruby objects, making it easy to follow (and enforce) code quality standards.

## Contributors

Hundreds of people have [contributed](https://github.com/ViewComponent/view_component/graphs/contributors) to ViewComponent:

<div>
{% for contributor in site.data.contributors.usernames %}
<img src="https://avatars.githubusercontent.com/{{ contributor }}?s=64" alt="{{ contributor }}" width="32" />
{% endfor %}
</div>

<hr />

[Getting started →](/guide/getting-started.html)
