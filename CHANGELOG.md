*   The `render_component` test helper has been renamed to `render_inline`. `render_component` has been deprecated and will be removed in v2.0.0.

    *Joel Hawksley*

*   Components are now rendered with `render MyComponent, foo: :bar` syntax. The existing `render MyComponent.new(foo: :bar)` syntax has been deprecated and will be removed in v2.0.0.

    *Joel Hawksley*

# v1.1.0

*   Components now inherit from ActionView::Component::Base

    *Joel Hawksley*

# v1.0.1

*   Always recompile component templates outside production.

    *Joel Hawksley, John Hawthorn*

# v1.0.0
