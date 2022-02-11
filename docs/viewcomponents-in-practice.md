---
layout: default
title: ViewComponents in practice
nav_order: 4
---

# ViewComponents in practice

_GitHub's internal guide to building component-driven UI in Rails. Consider it to be more opinion than fact._

## Why we use ViewComponents

We built the ViewComponent framework to help manage the growing complexity of the GitHub.com view layer. We've accumulated thousands of templates over the years, almost entirely through copy-pasting. A lack of abstraction made it challenging to make sweeping design, accessibility, and behavior improvements.

ViewComponent gives us a way to isolate common UI patterns for reuse, helping us improve the quality and consistency of the customer experience, especially when it comes to accessibility.

## Everything is a ViewComponent

Our goal is to build all GitHub's Rails-rendered HTML with ViewComponents, composed of [Primer ViewComponents](https://primer.style/view-components/).

## ViewComponent is to UI what ActiveRecord is to SQL

ViewComponent brings [conceptual compression](https://m.signalvnoise.com/conceptual-compression-means-beginners-dont-need-to-know-sql-hallelujah/) to the practice of building user interfaces.

At GitHub, this means enabling developers to build consistent, accessible, and correctly designed products by encoding our best practices into reusable ViewComponents.

## The two types of ViewComponents we write

We build our views using ViewComponents that tend to fall into two categories: general-purpose and app-specific.

### General-purpose ViewComponents

General-purpose ViewComponents implement common UI patterns. At GitHub, we open-source these components as [Primer ViewComponents](https://primer.style/view-components/).

### App-specific ViewComponents

App-specific ViewComponents translate a domain object (often an ActiveRecord model) into one or more general-purpose components.

For example: we've a `User::AvatarComponent` that accepts a `User` ActiveRecord object and renders a `Primer::AvatarComponent`.

## Organization

### Extract general-purpose ViewComponents

"Good frameworks are extracted, not invented" - [DHH](https://dhh.dk/arc/000416.html)

Just as ViewComponent itself was extracted from GitHub.com, our experience has shown that the best general-purpose components are extracted from the GitHub application once they've proven helpful across more than one area.

Our process typically follows the following steps:

1. Single use-case component implemented in the application.
2. Component adapted for general use in multiple locations in the application.
3. Component extracted into [Primer ViewComponents](https://primer.style/view-components/).

### Reduce permutations

As we build ViewComponents, we should look for opportunities to consolidate similar patterns into a single implementation. We tend to follow standard DRY practices in this regard, such as abstracting once there are three or more similar instances.

### Avoid one-offs

We should aim to minimize the amount of single-use view code that we write. Every time we don't reuse an existing pattern, we create something to keep up to date, increasing the maintenance burden of our applications.

### Expose existing complexity

Refactoring a view to being a ViewComponent often exposes existing complexity. For example, a ViewComponent may need numerous arguments to be rendered, revealing the number of dependencies in the existing view code. This is good! Refactoring to use ViewComponents helps us understand our view code and gives us a foundation for making it better.

## General guidance

### When to use a ViewComponent for an entire route

ViewComponents have less value in single-use cases like replacing a `show` view. However, it can make sense to render an entire route with a ViewComponent when unit testing is valuable, such as for views with many permutations from a state machine.

When migrating an entire route to use ViewComponents, we've had our best luck doing so from the bottom up, extracting portions of the page into ViewComponents first.

### Integrating Javascript behaviors

Write ViewComponents that wrap Web Components, writing any custom Javascript with [Catalyst](https://github.github.io/catalyst/).

### Prefer tests against rendered content, not instance methods

ViewComponent tests should use `render_inline` and assert against the rendered output. While it can be useful to test specific component instance methods directly, we've found it more valuable to write assertions against what we show to the end user:

```ruby
# good
render_inline(MyComponent.new)
assert_text("Hello, World!")

# not our preference
assert_equal(MyComponent.new.message, "Hello, World!")
```

### Most ViewComponent instance methods can be private

Most ViewComponent instance methods can be private, as they will still be available in the component template:

```ruby
# good
class MyComponent < ViewComponent::Base
  def initialize; end

  private

  def method_used_in_template; end
end

# bad
class MyComponent < ViewComponent::Base
  def initialize; end

  def method_used_in_template; end
end
```

### Prefer ViewComponents over ViewModels

ViewModels (view-specific objects) are deprecated in favor of ViewComponents. New ViewModels shouldn't be created, and existing ViewModels should be migrated to be ViewComponents when possible.

### Prefer ViewComponents over partials

Use ViewComponents in place of partials, as ViewComponents allow us to test reused view code directly (via unit tests) instead of through each place a partial is reused.

### Prefer ViewComponents over HTML-generating helpers

Use ViewComponents in place of helpers that return HTML.

### Avoid global state

The more a ViewComponent is dependent on global state (such as request parameters or the current URL), the less likely it's to be reusable. Avoid implicit coupling to global state, instead passing it into the component explicitly. Thorough unit testing is a good way to ensure decoupling from global state.

```ruby
# good
class MyComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end
end

# bad
class MyComponent < ViewComponent::Base
  def initialize
    @name = params[:name]
  end
end
```

### Avoid inline Ruby in ViewComponent templates

Avoid writing inline Ruby in ViewComponent templates. Try using an instance method on the ViewComponent instead:

```ruby
# good
class MyComponent < ViewComponent::Base
  def message
    "Hello, #{@name}!"
  end
end
```

``` erb
<%# bad %>
<% message = "Hello, #{@name}" %>
```

### Pass an object instead of 3+ object attributes

ViewComponents should be passed individual object attributes unless three or more attributes are needed from the object, in which case the entire object should be passed:

```ruby
# good
class MyComponent < ViewComponent::Base
  def initialize(repository:); end
end

# bad
class MyComponent < ViewComponent::Base
  def initialize(repository_name:, repository_owner:, repository_created_at:); end
end
```

### Avoid database queries

Avoid executing database queries in ViewComponents. Be especially careful for ViewComponents that are rendered as lists.

In the GitHub monolith, we automatically assert that `render_inline` calls execute no database queries. To allow queries to be run, pass `allowed_queries`:

```ruby
render_inline(MyComponent.new, allowed_queries: 2)
```
