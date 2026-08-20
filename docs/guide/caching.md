---
layout: default
title: Caching
parent: How-to guide
---

# Caching

Experimental
{: .label .label-yellow }

Since 4.14.0
{: .label }

**This API is experimental.** It may change or be removed in a non-major release. Please share feedback in [#234](https://github.com/ViewComponent/view_component/issues/234).

Rails computes a digest for every template from its source and from the templates it renders. That digest is mixed into the key of every `<% cache %>` block in the template, so editing a partial invalidates the caches of everything that renders it.

Components are invisible to that mechanism. 

```erb
<% cache @post do %>
  <%= render PostComponent.new(post: @post) %>
<% end %>
```

Editing `PostComponent`'s template, Ruby class, or sidecar files doesn't invalidate the fragment, so the stale markup is served until the cache is cleared by hand.

## Opting in

Include `ViewComponent::ExperimentallyCacheable` in each component that should participate in caching:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def initialize(post:)
    @post = post
  end
end
```

That's all that's needed for the `<% cache %>` block above to work. The component is registered with Rails' digest tree, and the fragment is invalidated when the component's template, Ruby class, sidecar files, superclasses, child components, or rendered partials change, including components and partials rendered from an inline template or a `#call` method.

## Self-caching

To have a component cache its own output without needing a `cache` block, use `cache_on` to declare methods used for the component's cache key.

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :post

  def initialize(post:)
    @post = post
  end

  private

  attr_reader :post
end
```

Every call site is now cached automatically:

```erb
<%= render PostComponent.new(post: @post) %>
```

Which is equivalent to writing:

```erb
<% cache [@post, PostComponent.cache_digest] do %>
  <%= render PostComponent.new(post: @post) %>
<% end %>
```

The cache key combines:

- the component's virtual path
- its digest, computed by Rails' `ActionView::Digestor`
- the requested format and variant
- the current `I18n.locale`
- the values returned by the `cache_on` methods

Caching is skipped unless `perform_caching` is enabled on the controller, matching the behavior of Rails' `cache` helper.

## Reading a component's digest

`.cache_digest` returns the digest of everything the component renders from. It works outside a request, where no view context exists:

```ruby
PostComponent.cache_digest # => "a1b2c3..."
```

Use it when a cache needs to be tied to a component's source but is written somewhere the component isn't rendered, such as a background job:

```ruby
Rails.cache.fetch(["post-summary", post, PostComponent.cache_digest]) do
  expensive_summary_for(post)
end
```

## Declaring dependencies static analysis can't see

Dependencies are discovered by scanning template and Ruby source for literal references, so renders resolved at runtime are invisible:

```erb
<%= render @component %>
```

```ruby
def call
  render "posts/#{@post.style}" # interpolated, so not tracked
end
```

Declare these with Rails' `# Template Dependency:` comment, in either the Ruby file or the template:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: posts/byline
end
```

## Caveats

**Content blocks aren't cached.** Content passed as a block isn't part of the cache key, so caching it would risk serving one caller's content to another:

```erb
<%# Not cached: the block's content isn't in the key %>
<%= render PostComponent.new(post: @post) do %>
  Hello
<% end %>
```

To cache a component that takes content, include the values that determine that content in `cache_on`, and set the content from within the component rather than from the call site.

**Slots have the same constraint.** Slot content set by the caller isn't part of the key unless declared in `cache_on`.

**`cache_on` methods run before the component renders**, so they can only depend on the component's own state, not on `helpers` or the view context. A cache key that depends on the view context is usually a sign the value should be passed to the component instead.

**Included modules aren't tracked.** A component's superclasses are, but a module included into a component isn't, since a module has no template or source file of its own to hash. Use `# Template Dependency:` for those.
