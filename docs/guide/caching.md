---
layout: default
title: Caching
parent: How-to guide
---

# Caching

Experimental
{: .label }

Components can implement caching by marking the depndencies that a digest can be built om using the cache_on macro, like so:

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

<p><%= Time.zone.now %>"></p>
<p><%= "#{foo} #{bar}" %></p>

```
will result in
```html
<p>foo-bar</p>

<p>2025-03-27 16:46:10 UTC</p>
<p> foo bar</p>
```

