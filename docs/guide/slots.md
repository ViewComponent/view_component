---
layout: default
title: Slots
parent: Building ViewComponents
---

# Slots

In addition to the `content` accessor, ViewComponents accept content through slots, enabling multiple blocks of content to be passed to a single ViewComponent.

Slots are defined with `renders_one` and `renders_many`:

- `renders_one` defines a slot that will be rendered at most once per component: `renders_one :header`
- `renders_many` defines a slot that can be rendered multiple times per-component: `renders_many :posts`

For example:

```ruby
# blog_component.rb
class BlogComponent < ViewComponent::Base
  renders_one :header
  renders_many :posts
end
```

To render a `renders_one` slot, call the name of the slot.

To render a `renders_many` slot, iterate over the name of the slot:

```erb
<%# blog_component.html.erb %>
<h1 class="<%= header.args[:classes] %>"><%= header %></h1>

<% posts.each do |post| %>
  <%= post.args.post %>
<% end %>
```

```erb
<%# index.html.erb %>
<%= render BlogComponent.new do |c| %>
  <% c.header(classes: '') do %>
    <%= link_to "My blog", root_path %>
  <% end %>

  <% @posts.each do |post| %>
    <%= c.post(post: post) %>
  <% end %>
<% end %>
```

## Component slots

It's also possible to have a slot be a ViewComponent itself by passing in a second argument to `renders_one` and `renders_many`:

```ruby
# blog_component.rb
class BlogComponent < ViewComponent::Base
  # Since `HeaderComponent` is nested inside of this component, we have to
  # reference it as a string instead of a class name.
  renders_one :header, "HeaderComponent"

  # `PostComponent` is defined in another file, so we can refer to it by class name.
  renders_many :posts, PostComponent

  class HeaderComponent < ViewComponent::Base
    attr_reader :classes

    def initialize(classes:)
      @classes = classes
    end

    def call
      content_tag :h1, content, { class: classes }
    end
  end
end
```

```erb
<%# blog_component.html.erb %>
<%= header %>

<% posts.each do |post| %>
  <%= post %>
<% end %>
```

```erb
<%# index.html.erb %>
<%= render BlogComponent.new do |c| %>
  <% c.header(classes: "") do %>
    <%= link_to "My Site", root_path %>
  <% end %>

  <% c.post(title: "My blog post") do %>
    Really interesting stuff.
  <% end %>

  <% c.post(title: "Another post!") do %>
    Blog every day.
  <% end %>
<% end %>
```

## Lambda slots

It's also possible to define a slot as a lambda that returns content to be rendered (either a string or a ViewComponent instance). Lambda slots are useful for working with helpers like `content_tag` or as wrappers for another ViewComponent with specific default values:

```ruby
class BlogComponent < ViewComponent::Base
  # Renders the returned string
  renders_one :header, -> (classes:) do
    content_tag :h1 do
      link_to title, root_path, { class: classes }
    end
  end

  # Returns a ViewComponent that will be rendered in that slot with a default argument.
  renders_many :posts, -> (title:, classes:) do
    PostComponent.new(title: title, classes: "my-default-class " + classes)
  end
end
```

Lambda slots are able to access state from the parent ViewComponent:

```ruby
class TableComponent < ViewComponent::Base
  renders_one :header, -> do
    HeaderComponent.new(selectable: @selectable)
  end

  def initialize(selectable: false)
    @selectable = selectable
  end
end
```

## Rendering collections

Collection slots (declared with `renders_many`) can also be passed a collection:

```ruby
# navigation_component.rb
class NavigationComponent < ViewComponent::Base
  renders_many :links, "LinkComponent"

  class LinkComponent < ViewComponent::Base
    def initialize(name:, href:)
      @name = name
      @href = href
    end
  end
end
```

```erb
<%# navigation_component.html.erb %>
<% links.each do |link| %>
  <%= link %>
<% end %>
```

```erb
<%# index.html.erb %>
<%= render(NavigationComponent.new) do |c| %>
  <% c.links([
    { name: "Home", href: "/" },
    { name: "Pricing", href: "/pricing" },
    { name: "Sign Up", href: "/sign-up" },
  ]) %>
<% end %>
```

## `#with_content`

Slot content can also be set using `#with_content`:

```erb
<%= render BlogComponent.new do |c| %>
  <% c.header(classes: "title").with_content("My blog") %>
<% end %>
```

_To view documentation for content_areas (deprecated) and the original implementation of Slots (deprecated), see [/content_areas](/content_areas) and [/slots_v1](/slots_v1)._
