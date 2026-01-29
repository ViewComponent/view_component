---
layout: default
title: Caching
parent: How-to guide
---

# Caching

Experimental
{: .label }

Caching is experimental.

To enable caching globally (opt-in), add this to an initializer:

```ruby
require "view_component/fragment_caching"
```

Alternatively, you can opt in per-component by including `ViewComponent::Cacheable`.

Components implement caching by marking the dependencies that should be included in the cache key using `cache_on`:

```ruby
class CacheComponent < ViewComponent::Base
  include ViewComponent::Cacheable

  cache_on :foo, :bar
  attr_reader :foo, :bar

  def initialize(foo:, bar:)
    @foo = foo
    @bar = bar
  end
end
```

Notes:

- `cache_on` accepts method names; the returned values are expanded via `ActiveSupport::Cache.expand_cache_key` (so Active Record models, `GlobalID`, arrays, and plain strings work as expected).
- Methods listed in `cache_on` may be private (the cache dependency reader calls `send`).
- The cache key includes a digest of the component source (Ruby + templates + i18n sidecars) and rendered child ViewComponents.
- Partial/layout string dependencies are not currently included in the digest; use `RAILS_CACHE_ID`/`RAILS_APP_VERSION` if you need to invalidate on deploy.

```erb
<p><%= view_cache_dependencies.inspect %></p>

<p><%= Time.zone.now %></p>
<p><%= "#{foo} #{bar}" %></p>
```
