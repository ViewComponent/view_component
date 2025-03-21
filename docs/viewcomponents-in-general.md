---
layout: default
title: ViewComponents in general
nav_order: 5
---

# ViewComponents in the general community

_A general guide to building component-driven UI in Rails. Consider it to be more opinion than fact._

## Why we use ViewComponents

The ViewComponent framework helps manage the growing complexity of large (and small) Rails applications. They have the tendency to accumulate large numbers of templates over the years, often through copy-pasting and without a consistent structure or plan. A lack of abstraction makes it challenging to make sweeping design, accessibility, and behavior improvements.

## ViewComponent is to UI what ActiveRecord is to SQL

ViewComponent brings [conceptual compression](https://m.signalvnoise.com/conceptual-compression-means-beginners-dont-need-to-know-sql-hallelujah/) to the practice of building user interfaces.

## Deliniate broad categories of components

In general, it makes sense to have at least two types of ViewComponents: general-purpose and app-specific.

### General-purpose ViewComponents

General-purpose ViewComponents implement common UI patterns, such as a button, form, or modal.

### App-specific ViewComponents

App-specific ViewComponents translate a domain object (such as an `ActiveRecord` model or an API response modeled as a PORO) into one or more general-purpose components.

For example, `User::AvatarComponent` accepts a `User` ActiveRecord object and renders a `DesignSystem::AvatarComponent`.

## Organization

### Extract general-purpose ViewComponents

"Good frameworks are extracted, not invented" - [DHH](https://dhh.dk/arc/000416.html)

As you build, look for opportunities to extract general-purpose components that can be reused across your application.  A common pattern is to namespace your components into those considered general-purpose and those considered app or project specific.

A common process typically follows the following steps:

1. Single use-case component implemented.
2. Component adapted for general use in multiple locations in the application.
3. Component extracted into a general-purpose ViewComponent.

### Reduce permutations

When building ViewComponents, look for opportunities to consolidate similar patterns into a single implementation. Different practices may be used, but a common approach is to abstract similar components into a single implementation once there are three or more similar instances.

### Avoid one-offs

Aim to minimize the amount of single-use view code that you write. Every time you don't reuse an existing pattern, you create something to keep up to date, increasing the maintenance burden of your application.

### Expose existing complexity

Refactoring a view to being a ViewComponent often exposes existing complexity. For example, a ViewComponent may need numerous arguments to be rendered, revealing the number of dependencies in the existing view code. This is good! Refactoring to use ViewComponents helps to understand your view code and gives you a foundation for making it better.

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
  private

  def method_used_in_template
  end
end

# bad
class MyComponent < ViewComponent::Base
  def method_used_in_template
  end
end
```

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
  attr_accessor :name

  def message
    "Hello, #{name}!"
  end
end
```

```erb
<%# bad %>
<% message = "Hello, #{name}" %>
```

### Pass an object instead of 3+ object attributes

ViewComponents should be passed individual object attributes unless three or more attributes are needed from the object, in which case the entire object should be passed:

```ruby
# good
class MyComponent < ViewComponent::Base
  def initialize(repository:)
    #...
  end
end

# bad
class MyComponent < ViewComponent::Base
  def initialize(repository_name:, repository_owner:, repository_created_at:)
    #...
  end
end
```

### Prefer local variables over instance variables in template contexts

Most templating engines will cause `.to_s` to be called on any code that is run in the template context.  This can cause difficulties when debugging, as a mis-spelled variable name will silently emit an empty string, rather than raise an error.

```erb
# bad
Hello, <%= @name %>
```

```erb
# good
Hello, <%= name %>
```

### Prefer slots for any content which may contain markup

If a ViewComponent may contain markup, prefer using slots to render the content.  This allows you to benefit from all of the HTML sanitization that Rails provides, rather than having to implement your own or depending on component's users to pass in HTML-safe content.

```erb
# bad
<%= render MyComponent.new(name: "<strong>Hello, world!</strong>".html_safe) %>
```

```erb
# good
<%= render(MyComponent.new) do |component| %>
  <% component.with_name do %>
    <strong>Hello, world!</strong>
  <% end %>
<% end %>
```
