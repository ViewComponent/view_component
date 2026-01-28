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

```erb
<p><%= view_cache_dependencies %></p>

<p><%= Time.zone.now %></p>
<p><%= "#{foo} #{bar}" %></p>
```

will result in:

```html
<p>foo-bar</p>

<p>2025-03-27 16:46:10 UTC</p>
<p> foo bar</p>
```
