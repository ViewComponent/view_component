---
layout: default
title: Frequently asked questions
nav_order: 5
---

# Frequently asked questions

## Can I use other templating languages besides ERB?

Yes. ViewComponent is tested against ERB, Haml, and Slim, but it should support most Rails template handlers.

## Can I use a ViewComponent for an entire view?

If the view could benefit from unit testing, making it a ViewComponent is probably a good idea.

## Can I render a ViewComponent to a string, from inside a controller action?

When rendering multiple times the same component, you may want to render it only once, from the controller action, and reuse it.

```rb
class PagesController < ApplicationController
  def index
    # Does not work: triggers a `AbstractController::DoubleRenderError`
    # @reusable_icon = render IconComponent.new('close')

    # Does not work: renders the whole index view as a string
    # @reusable_icon = render_to_string IconComponent.new('close')

    # Works: renders the component as a string
    @reusable_icon = IconComponent.new('close').render_in(view_context)
  end
```

## Isn't this just like X library?

ViewComponent is far from a novel idea! Popular implementations of view components in Ruby include, but are not limited to:

- [trailblazer/cells](https://github.com/trailblazer/cells)
- [dry-rb/dry-view](https://github.com/dry-rb/dry-view)
- [komposable/komponent](https://github.com/komposable/komponent)
- [activeadmin/arbre](https://github.com/activeadmin/arbre)

## Can I use validations with ViewComponents?

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

## Can I use ViewComponent with `X library`?

ViewComponent is currently only available for Rails. Read more: [compatibility section](./compatibility).
