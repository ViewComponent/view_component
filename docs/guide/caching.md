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

**This API is experimental.** It may change or be removed in a non-major release.
Please share feedback in [#234](https://github.com/ViewComponent/view_component/issues/234).

Rails computes a digest for every template from its source and from the templates
it renders. That digest is mixed into the key of every `<% cache %>` block in the
template, so editing a partial invalidates the caches of everything that renders it.

Components are invisible to that mechanism, which means this doesn't work:

```erb
<% cache @post do %>
  <%= render PostComponent.new(post: @post) %>
<% end %>
```

Editing `PostComponent`'s template, Ruby class, or sidecar files doesn't invalidate
the fragment, so the stale markup is served until the cache is cleared by hand.

## Opting in

Include `ViewComponent::ExperimentallyCacheable` in each component that should
participate in caching:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def initialize(post:)
    @post = post
  end
end
```

That's all that's needed for the `<% cache %>` block above to work. The component
is registered with Rails' digest tree, and the fragment is invalidated when any of
the following change:

| Change | Invalidates |
|---|---|
| The component's template | ✅ |
| The component's Ruby class | ✅ |
| A sidecar file (such as an i18n `.yml`) | ✅ |
| A superclass's template or Ruby class | ✅ |
| A child component rendered by the template | ✅ |
| A partial rendered by the template | ✅ |

Components that don't include the module are unaffected, and applications that
never opt in pay no cost.

## Caching a component's own output

Use `cache_on` to have the component cache its own rendered output. Each argument
names a method whose value identifies a rendering of the component:

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

Rendering the component now reads from and writes to `Rails.cache`, with no
`<% cache %>` block at the call site:

```erb
<%= render PostComponent.new(post: @post) %>
```

Private methods are allowed, so the values that form the key don't have to be
part of the component's public interface.

The cache key combines:

- the component's virtual path
- its digest, computed by Rails' `ActionView::Digestor`
- the requested format and variant
- the current `I18n.locale`
- the values returned by the `cache_on` methods

Caching is skipped unless `perform_caching` is enabled on the controller, matching
the behavior of Rails' `cache` helper. Override `#cache_key` for full control.

## Reading a component's digest

`.cache_digest` returns the digest of everything the component renders from. It
works outside a request, where no view context exists:

```ruby
PostComponent.cache_digest # => "a1b2c3..."
```

Use it to build cache keys by hand, or to key a cache in a background job:

```erb
<% cache [@post, PostComponent.cache_digest] do %>
  <%= render PostComponent.new(post: @post) %>
<% end %>
```

## Declaring dependencies static analysis can't see

Dependencies are discovered by scanning template source, so dynamic renders are
invisible:

```erb
<%= render @component %>
```

Declare these with Rails' `# Template Dependency:` comment, in either the Ruby
file or the template:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: posts/byline
end
```

## Caveats

**Content blocks aren't cached.** Content passed as a block isn't part of the
cache key, so caching it would risk serving one caller's content to another:

```erb
<%# Not cached: the block's content isn't in the key %>
<%= render PostComponent.new(post: @post) do %>
  Hello
<% end %>
```

To cache a component that takes content, include the values that determine that
content in `cache_on`, and set the content from within the component rather than
from the call site.

**Slots have the same constraint.** Slot content set by the caller isn't part of
the key unless declared in `cache_on`.

**`cache_on` methods run before the component renders**, so they can only depend
on the component's own state, not on `helpers` or the view context. A cache key
that depends on the view context is usually a sign the value should be passed to
the component instead.

**Inline templates and `#call` methods** are digested through the component's Ruby
file, so edits to them invalidate correctly. Partials and components they render
aren't discovered, because there's no template source to scan; use
`# Template Dependency:` for those.

**Included modules aren't tracked.** A component's superclasses are, but a module
included into a component isn't. Use `# Template Dependency:` or bump
`config.action_controller.perform_caching` cache versions on deploy.
