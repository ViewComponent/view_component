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

To cache only some renders, pass `if:` or `unless:`. Both accept a method name or a proc evaluated on the component:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :post, unless: -> { post.draft? }

  def initialize(post:)
    @post = post
  end

  private

  attr_reader :post
end
```

Drafts now render every time, while published posts are cached. Note that this controls whether the cache is *used*, not what goes into the key: a `cache_on` method returning `nil` or `false` still contributes that value to the key rather than disabling caching.

A component that declares `cache_on` can't accept content from its callers. A block, `with_content`, or a slot set by the caller isn't part of the cache key, so passing one raises `ContentPassedToCachedComponentError`:

```erb
<%# Raises: the block's content isn't in the cache key %>
<%= render PostComponent.new(post: @post) do %>
  Hello
<% end %>
```

The error is raised even when caching is disabled, so the conflict surfaces in development and test rather than only in production. See [Caveats](#caveats) for how to restructure a component that needs to take content.

`cache_on` is inherited, so declaring it on a base class opts every subclass into self-caching, and into that restriction. Declare it on the components that should cache themselves rather than on `ApplicationComponent`.

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

Declare these with Rails' `# Template Dependency:` comment, in either the Ruby file or the template. Partials are named by path:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: posts/byline
end
```

Components are named by class, listing each one the component might render:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: PostSummaryComponent
  # Template Dependency: PostDetailComponent

  def call
    render(@detailed ? PostDetailComponent : PostSummaryComponent).new(post: @post)
  end
end
```

The same works in a template, where the branch is often the more natural place for it:

```erb
<% if params[:style] == "summary" %>
  <%# Template Dependency: PostSummaryComponent %>
  <% component = PostSummaryComponent %>
<% else %>
  <%# Template Dependency: PostDetailComponent %>
  <% component = PostDetailComponent %>
<% end %>
<%= render component.new(post: @post) %>
```

A declared component doesn't have to include `ViewComponent::ExperimentallyCacheable` itself. The declaration alone gets its template, Ruby class, sidecar files, and superclasses digested, which matters because the components this escape hatch exists for are often ones you don't control.

## Caveats

**Self-caching components can't take content from their callers.** Besides a block, this covers `with_content` and slots set by the caller:

```erb
<%# Also raises ContentPassedToCachedComponentError %>
<%= render PostComponent.new(post: @post) do |component| %>
  <% component.with_header { "Hello" } %>
<% end %>
```

Slots a component fills in for itself with a `default_*` method are part of its own output, not the caller's, so those are cached normally:

```ruby
class PostComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  renders_one :header

  cache_on :post

  def default_header
    post.title # cached, because the component decides it
  end
end
```

To cache a component that takes content, move the content into the component and derive it from values declared in `cache_on`. Components that don't declare `cache_on` are unaffected: they still accept content and slots, and a `<% cache %>` block around them still invalidates correctly.

**`cache_on` methods run before the component renders**, so they can only depend on the component's own state, not on `helpers` or the view context. A cache key that depends on the view context is usually a sign the value should be passed to the component instead.

**Included modules aren't tracked.** A component's superclasses are, but a module included into a component isn't, since a module has no template or source file of its own to hash. Use `# Template Dependency:` for those.
