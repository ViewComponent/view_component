---
layout: default
title: Caching
parent: How-to guide
---

# Caching

Experimental
{: .label }

Caching is experimental. To cache a component, include `ViewComponent::ExperimentallyCacheable` and declare cache dependencies using `cache`:

```ruby
class CacheComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  attr_reader :foo, :bar

  cache do
    [foo, bar]
  end

  def initialize(foo:, bar:)
    @foo = foo
    @bar = bar
  end
end
```

```erb
<p><%= Time.zone.now %></p>
<p><%= "#{foo} #{bar}" %></p>
```

Components that include `ViewComponent::ExperimentallyCacheable` but do not call `cache` render normally without fragment caching.

Caching only reads and writes fragments when controller caching is enabled.

## Dependencies

The `cache` block is evaluated in the component instance context. Returned values are expanded via `ActiveSupport::Cache.expand_cache_key`, so Active Record models, `GlobalID`, arrays, plain strings, and values returned by private methods work as expected.

```ruby
class UserComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def initialize(user:)
    @user = user
  end

  cache do
    [@user]
  end
end
```

## Conditional caching

Use `cache_if` to cache only when a condition is met:

```ruby
class UserComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_if :cacheable?

  cache do
    [@user]
  end

  def initialize(user:, cacheable: true)
    @user = user
    @cacheable = cacheable
  end

  private

  def cacheable?
    @cacheable
  end
end
```

`cache_if` accepts a symbol, a boolean value, or a block.

## Cache invalidation

The cache key includes a digest of the component, its sidecar files, and ViewComponents rendered by the component.

Caches are invalidated when the component source, sidecar templates, sidecar translations, or rendered child ViewComponents change.

## Limitations

Changes to partial and layout string dependencies will not invalidate the cache. Modify `RAILS_CACHE_ID` or `RAILS_APP_VERSION` to invalidate these caches on deploy.
