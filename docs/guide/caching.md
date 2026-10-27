---
layout: default
title: Caching
parent: How-to guide
---

# Caching

Since 4.14.0
{: .label }

Components work with Rails fragment caching. Editing a component's template, Ruby class, sidecar files, superclasses, included modules, or anything it renders invalidates every `cache` block that contains it, whether that block is in a view or inside a component's own template:

```erb
<% cache @post do %>
  <%= render PostComponent.new(post: @post) %>
<% end %>
```

## Self-caching

Use `cache_on` to have a component cache its own output, keyed by the values of the named methods:

```ruby
class PostComponent < ViewComponent::Base
  cache_on :post

  def initialize(post:)
    @post = post
  end

  private

  attr_reader :post
end
```

The cache key also includes the component's digest, format, variant, and locale. As with Rails' `cache` helper, caching only happens when `perform_caching` is enabled.

To cache only some renders, pass `if:` or `unless:` with a method name or a proc:

```ruby
cache_on :post, unless: -> { post.draft? }
```

A component that declares `cache_on` can't take content from its callers, since that content isn't part of the cache key. Passing a block, `with_content`, or a slot raises `ContentPassedToCachedComponentError`, even when caching is disabled. Slots filled by the component's own `default_*` methods are fine.

`cache_on` methods run before the component renders, so they can't use `helpers` or the view context.

## Reading a component's digest

`.cache_digest` returns the digest of everything a component renders from, for tying a cache to a component outside a render:

```ruby
Rails.cache.fetch(["post-summary", post, PostComponent.cache_digest]) do
  expensive_summary_for(post)
end
```

## Declaring dependencies

Dependencies are found by scanning the component's templates, its Ruby class, and the modules it includes. Every component class named there counts, whether it's passed to `render`, built by a method, or assigned to a variable, and so does every partial rendered by its path. Slots count the class they're declared with, including one named by a string.

A class or partial name built at runtime can't be found that way. Declare it with Rails' `# Template Dependency:` comment in the Ruby file or template, naming partials by path and components by class:

```ruby
class PostComponent < ViewComponent::Base
  # Template Dependency: posts/byline
  # Template Dependency: PostSummaryComponent
  # Template Dependency: PostDetailComponent

  def call
    render "Post#{@style.to_s.camelize}Component".constantize.new(post: @post)
  end
end
```
