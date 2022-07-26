---
layout: default
title: Slots
parent: Guide
---

# Slots

Since 2.12.0
{: .label }

In addition to the `content` accessor, ViewComponents can accept content through slots. Think of slots as a way to render multiple blocks of content, including other components.

Slots are defined with `renders_one` and `renders_many`:

- `renders_one` defines a slot that will be rendered at most once per component: `renders_one :header`
- `renders_many` defines a slot that can be rendered multiple times per-component: `renders_many :posts`

If a second argument isn't provided to these methods, a **passthrough slot** is registered. Any content passed through can be rendered inside these slots without restriction.

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
<h1><%= header %></h1>

<% posts.each do |post| %>
  <%= post %>
<% end %>
```

```erb
<%# index.html.erb %>
<%= render BlogComponent.new do |c| %>
  <% c.with_header do %>
    <%= link_to "My blog", root_path %>
  <% end %>

  <% BlogPost.all.each do |blog_post| %>
    <% c.with_post do %>
      <%= link_to blog_post.name, blog_post.url %>
    <% end %>
  <% end %>
<% end %>
```

Returning:

```erb
<h1><a href="/">My blog</a></h1>

<a href="/blog/first-post">First post</a>
<a href="/blog/second-post">Second post</a>
```

## Predicate methods

Since 2.50.0
{: .label }

To test whether a slot has been passed to the component, use the provided `#{slot_name}?` method.

```erb
<%# blog_component.html.erb %>
<% if header? %>
  <h1><%= header %></h1>
<% end %>

<% if posts? %>
  <div class="posts">
    <% posts.each do |post| %>
      <%= post %>
    <% end %>
  </div>
<% else %>
  <p>No post yet.</p>
<% end %>
```

## Component slots

Slots can also render other components. Pass the name of a component as the second argument to define a component slot.

Arguments passed when calling a component slot will be used to initialize the component and render it. A block can also be passed to set the component's content.

```ruby
# blog_component.rb
class BlogComponent < ViewComponent::Base
  # Since `HeaderComponent` is nested inside of this component, we've to
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
  <% c.with_header(classes: "") do %>
    <%= link_to "My Site", root_path %>
  <% end %>

  <% c.with_post(title: "My blog post") do %>
    Really interesting stuff.
  <% end %>

  <% c.with_post(title: "Another post!") do %>
    Blog every day.
  <% end %>
<% end %>
```

## Lambda slots

It's also possible to define a slot as a lambda that returns content to be rendered (either a string or a ViewComponent instance). Lambda slots are useful in cases where writing another component may be unnecessary, such as working with helpers like `content_tag` or as wrappers for another ViewComponent with specific default values:

```ruby
class BlogComponent < ViewComponent::Base
  renders_one :header, -> (classes:) do
    # This isn't complex enough to be its own component yet, so we'll use a
    # lambda slot. If it gets much bigger, it should be extracted out to a
    # ViewComponent and rendered here with a component slot.
    content_tag :h1 do
      link_to title, root_path, { class: classes }
    end
  end

  # It's also possible to return another ViewComponent with preset default values:
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

To provide content for a lambda slot via a block, add a block parameter. Render the content by calling the block's `call` method, or by passing the block directly to `content_tag`:

```ruby
class BlogComponent < ViewComponent::Base
  renders_one :header, -> (classes:, &block) do
    content_tag :h1, class: classes, &block
  end
end
```

## Rendering collections

Since 2.23.0
{: .label }

`renders_many` slots can also be passed a collection, using the plural setter (`links` in this example):

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
  <% c.with_links([
    { name: "Home", href: "/" },
    { name: "Pricing", href: "/pricing" },
    { name: "Sign Up", href: "/sign-up" },
  ]) %>
<% end %>
```

## `#with_content`

Since 2.31.0
{: .label }

Slot content can also be set using `#with_content`:

```erb
<%= render BlogComponent.new do |c| %>
  <% c.with_header(classes: "title").with_content("My blog") %>
<% end %>
```

_To view documentation for content_areas (deprecated) and the original implementation of Slots (deprecated), see [/content_areas](/content_areas) and [/slots_v1](/slots_v1)._

## Polymorphic slots

Since 2.42.0
{: .label }

Polymorphic slots can render one of several possible slots.

For example, consider this list item component that can be rendered with either an icon or an avatar visual. The `visual` slot is passed a hash mapping types to slot definitions:

```ruby
class ListItemComponent < ViewComponent::Base
  renders_one :visual, types: {
    icon: IconComponent,
    avatar: lambda { |**system_arguments|
      AvatarComponent.new(size: 16, **system_arguments)
    }
  }
end
```

**Note**: the `types` hash's values can be any valid slot definition, including a component class, string, or lambda.

Filling in the `visual` slot is done by calling the appropriate slot method:

```erb
<%= render ListItemComponent.new do |c| %>
  <% c.with_visual_avatar(src: "http://some-site.com/my_avatar.jpg", alt: "username") do %>
    Profile
  <% end >
<% end %>
<%= render ListItemComponent.new do |c| %>
  <% c.with_visual_icon(icon: :key) do %>
    Security Settings
  <% end >
<% end %>
```

To see whether a polymorphic slot has been passed to the component, use the `#{slot_name}?` method.

```erb
<% if visual? %>
  <%= visual %>
<% else %>
  <span class="visual-placeholder">N/A</span>
<% end %>
```
