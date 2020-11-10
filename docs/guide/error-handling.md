---
layout: default
title: Error handling
parent: Guide
---

# Error handling

An exception occurring in a small fragment of the user interface can potentially break an entire page.

To prevent this you can use `rescue_from`, just like in a controller:

```ruby
class FailingComponent < ViewComponent::Base
  rescue_from User::NotAuthorized, with: :deny_access

  def deny_access
    'You cannot look at this.'
  end
end
```

The error handler can also render a fallback component.
