---
layout: default
title: Validations
parent: Building ViewComponents
---

# Validations

ViewComponent does not include support for validations. However, it can be added by using `ActiveModel::Validations`:

```ruby
class ExampleComponent < ViewComponent::Base
  include ActiveModel::Validations

  # Requires that a content block be passed to the component
  validate :content, presence: true

  def before_render
    validate!
  end
end
```

_Note: Using validations in this manner can lead to runtime exceptions. Use them wisely._
