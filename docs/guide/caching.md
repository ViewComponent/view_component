---
layout: default
title: Caching
parent: How-to guide
---

# Caching

Experimental
{: .label }

Caching is experimental.

To enable caching, include `ViewComponent::ExperimentallyCacheable`.

Components implement caching by marking dependencies using `cache_on`:

```ruby
class CacheComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :foo, :bar
  attr_reader :foo, :bar

  def initialize(foo:, bar:)
    @foo = foo
    @bar = bar
  end
end
```

```erb
<p><%= view_cache_dependencies.inspect %></p>

<p><%= Time.zone.now %></p>
<p><%= "#{foo} #{bar}" %></p>
```

`cache_on` accepts method names. Returned values are expanded via `ActiveSupport::Cache.expand_cache_key`, so Active Record models, `GlobalID`, arrays, and plain strings work as expected.

Methods listed in `cache_on` may be private.

The cache key includes a digest of component source (Ruby + templates + i18n sidecars) and rendered child ViewComponents.

Partial/layout string dependencies are not currently included in the digest; modify `RAILS_CACHE_ID`/`RAILS_APP_VERSION` to invalidate on deploy.
