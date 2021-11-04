---
layout: default
title: Frequently asked questions
nav_order: 5
---

# Frequently asked questions

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
