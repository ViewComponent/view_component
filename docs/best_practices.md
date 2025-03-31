---
layout: default
title: Best practices
nav_order: 5
---

# Best practices

## Philosophy

### Why ViewComponent exists

ViewComponent was created to help manage the growing complexity of the GitHub.com view layer, which accumulated thousands of templates over the years, almost entirely through copy-pasting. A lack of abstraction made it challenging to make sweeping design, accessibility, and behavior improvements.

ViewComponent provides a way to isolate common UI patterns for reuse, helping to improve the quality and consistency of Rails applications.

### ViewComponent is to UI what ActiveRecord is to SQL

ViewComponent brings [conceptual compression](https://m.signalvnoise.com/conceptual-compression-means-beginners-dont-need-to-know-sql-hallelujah/) to the practice of building user interfaces.

### ViewComponent exposes existing complexity

Converting an existing view/partial to a ViewComponent often exposes existing complexity. For example, a ViewComponent may need numerous arguments to be rendered, revealing the number of dependencies in the existing view code.

This is good! Refactoring to use ViewComponent improves comprehension and provides a foundation for further improvement.

## Organization

### Two types of ViewComponents

ViewComponents typically come in two forms: general-purpose and application-specific.

#### General-purpose ViewComponents

General-purpose ViewComponents implement common UI patterns, such as a button, form, or modal. GitHub open-sources these components as [Primer ViewComponents](https://github.com/primer/view_components).

#### Application-specific ViewComponents

Application-specific ViewComponents translate a domain object (such as an `ActiveRecord` model or an API response modeled as a Plain Old Ruby Object) into one or more general-purpose components.

For example, `User::AvatarComponent` accepts a `User` ActiveRecord object and renders a `DesignSystem::AvatarComponent`.

### Extract general-purpose ViewComponents

"Good frameworks are extracted, not invented" - [DHH](https://dhh.dk/arc/000416.html)

Just as ViewComponent itself was extracted from GitHub.com, general-purpose components are best extracted once they've proven helpful across more than one area:

1. Single use-case component implemented.
2. Component adapted for general use in multiple locations in the application.
3. Component extracted into a general-purpose ViewComponent in `app/lib` or a separate gem.

### Reduce permutations

When building ViewComponents, look for opportunities to consolidate similar patterns into a single implementation. Consider following standard DRY practices, abstracting once there are three or more similar instances.

### Avoid one-offs

Aim to minimize the amount of single-use view code. Every new component introduced adds to application maintenance burden.

### Use -Component suffix

While it means class names are longer and perhaps less readable, including the -`Component` suffix in component names makes it clear that the class is a component, following Rails convention of using suffixes for all non-model objects.

## Implementation

### Avoid inheritance

Having one ViewComponent inherit from another leads to confusion, especially when each component has its own template. Instead, [use composition](https://thoughtbot.com/blog/reusable-oo-composition-vs-inheritance) to wrap one component with another.

### When to use a ViewComponent for an entire route

ViewComponents have less value in single-use cases like replacing a `show` view. However, it can make sense to render an entire route with a ViewComponent when unit testing is valuable, such as for views with many permutations from a state machine.

When migrating an entire route to use ViewComponents, work from the bottom up, extracting portions of the page into ViewComponents first.

### Test against rendered content, not instance methods

ViewComponent tests should use `render_inline` and assert against the rendered output. While it can be useful to test specific component instance methods directly, it's more valuable to write assertions against what's shown to the end user:

```ruby
# good
render_inline(MyComponent.new)
assert_text("Hello, World!")

# bad
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

### Prefer ViewComponents over partials

Use ViewComponents in place of partials.

### Prefer ViewComponents over HTML-generating helpers

Use ViewComponents in place of helpers that return HTML.

### Avoid global state

The more a ViewComponent is dependent on global state (such as request parameters or the current URL), the less likely it's to be reusable. Avoid implicit coupling to global state, instead passing it into the component explicitly:

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

Thorough unit testing is a good way to ensure decoupling from global state.

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

### Prefer slots over passing markup as an argument

Prefer using slots for providing markup to components. Passing markup as an argument bypasses the HTML sanitization provided by Rails, creating the potential for security issues:

```erb
# good
<%= render(MyComponent.new) do |component| %>
  <% component.with_name do %>
    <strong>Hello, world!</strong>
  <% end %>
<% end %>
```

```erb
# bad
<%= render MyComponent.new(name: "<strong>Hello, world!</strong>".html_safe) %>
```
