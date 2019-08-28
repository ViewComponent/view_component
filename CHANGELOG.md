*   The `render_component` test helper has been renamed to `render_inline`. `render_component` will be removed in v2.0.0.

    *Joel Hawksley*

*   Components are now rendered with `render MyComponent, foo: :bar` syntax. The existing `render MyComponent.new(foo: :bar)` syntax will be deprecated in v2.0.0.

    *Joel Hawksley*

*   Components now inherit from ActionView::Component::base

    *Joel Hawksley*

*   Always recompile component templates outside production.

    *Joel Hawksley, John Hawthorn*
