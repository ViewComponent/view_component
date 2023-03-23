---
layout: default
title: API reference
nav_order: 3
---

<!-- Warning: AUTO-GENERATED file, don't edit. Add code comments to your Ruby instead <3 -->

# API

## Class methods

### `.config` → [ViewComponent::Config]

Returns the current config.

### `.config=(value)`

Replaces the entire config. You shouldn't need to use this directly
unless you're building a `ViewComponent::Config` elsewhere.

### `.sidecar_files(extensions)`

Find sidecar files for the given extensions.

The provided array of extensions is expected to contain
strings starting without the dot, example: `["erb", "haml"]`.

For example, one might collect sidecar CSS files that need to be compiled.

### `.strip_trailing_whitespace(value = true)`

Strips trailing whitespace from templates before compiling them.

```ruby
class MyComponent < ViewComponent::Base
  strip_trailing_whitespace
end
```

### `.strip_trailing_whitespace?` → [Boolean]

Whether trailing whitespace will be stripped before compilation.

### `.with_collection(collection, **args)`

Render a component for each element in a collection ([documentation](/guide/collections)):

```ruby
render(ProductsComponent.with_collection(@products, foo: :bar))
```

### `.with_collection_parameter(parameter)`

Set the parameter name used when rendering elements of a collection ([documentation](/guide/collections)):

```ruby
with_collection_parameter :item
```

## Instance methods

### `#before_render` → [void]

Called before rendering the component. Override to perform operations that
depend on having access to the view context, such as helpers.

### `#content` → [String]

The content passed to the component instance as a block.

### `#content?` → [Boolean]

Whether `content` has been passed to the component.

### `#controller` → [ActionController::Base]

The current controller. Use sparingly as doing so introduces coupling
that inhibits encapsulation & reuse, often making testing difficult.

### `#helpers` → [ActionView::Base]

A proxy through which to access helpers. Use sparingly as doing so introduces
coupling that inhibits encapsulation & reuse, often making testing difficult.

### `#output_postamble` → [String]

Optional content to be returned after the rendered template.

### `#render?` → [Boolean]

Override to determine whether the ViewComponent should render.

### `#render_in(view_context, &block)` → [String]

Entrypoint for rendering components.

- `view_context`: ActionView context from calling view
- `block`: optional block to be captured within the view context

Returns HTML that has been escaped by the respective template handler.

### `#render_parent`

Subclass components that call `super` inside their template code will cause a
double render if they emit the result:

```erb
<%= super %> # double-renders
<% super %> # does not double-render
```

Calls `super`, returning `nil` to avoid rendering the result twice.

### `#request` → [ActionDispatch::Request]

The current request. Use sparingly as doing so introduces coupling that
inhibits encapsulation & reuse, often making testing difficult.

### `#set_original_view_context(view_context)` → [void]

Components render in their own view context. Helpers and other functionality
require a reference to the original Rails view context, an instance of
`ActionView::Base`. Use this method to set a reference to the original
view context. Objects that implement this method will render in the component's
view context, while objects that don't will render in the original view context
so helpers, etc work as expected.

## Configuration

### `.capture_compatibility_patch_enabled` → [String]

A custom default layout used for the previews index page and individual
previews.
Defaults to `nil`. If this is falsy, `"component_preview"` is used.

Enables the experimental capture compatibility patch that makes ViewComponent
compatible with forms, capture, and other built-ins.
previews.
Defaults to `false`.

### `.component_parent_class` → [String]

The parent class from which generated components will inherit.
Defaults to `nil`. If this is falsy, generators will use
`"ApplicationComponent"` if defined, `"ViewComponent::Base"` otherwise.

### `#config`

Returns the value of attribute config.

### `.default_preview_layout` → [String]

A custom default layout used for the previews index page and individual
previews.
Defaults to `nil`. If this is falsy, `"component_preview"` is used.

Enables the experimental capture compatibility patch that makes ViewComponent
compatible with forms, capture, and other built-ins.
previews.
Defaults to `false`.

### `.generate` → [ActiveSupport::OrderedOptions]

The subset of configuration options relating to generators.

All options under this namespace default to `false` unless otherwise
stated.

#### `#sidecar`

Always generate a component with a sidecar directory:

    config.view_component.generate.sidecar = true

#### `#stimulus_controller`

Always generate a Stimulus controller alongside the component:

    config.view_component.generate.stimulus_controller = true

#### `#locale`

Always generate translations file alongside the component:

    config.view_component.generate.locale = true

#### `#distinct_locale_files`

Always generate as many translations files as available locales:

    config.view_component.generate.distinct_locale_files = true

One file will be generated for each configured `I18n.available_locales`,
falling back to `[:en]` when no `available_locales` is defined.

#### `#preview`

Always generate a preview alongside the component:

     config.view_component.generate.preview = true

#### #preview_path

Path to generate preview:

     config.view_component.generate.preview_path = "test/components/previews"

Required when there is more than one path defined in preview_paths.
Defaults to `""`. If this is blank, the generator will use
`ViewComponent.config.preview_paths` if defined,
`"test/components/previews"` otherwise

### `.instrumentation_enabled` → [Boolean]

Whether ActiveSupport notifications are enabled.
Defaults to `false`.

### `.preview_controller` → [String]

The controller used for previewing components.
Defaults to `ViewComponentsController`.

### `.preview_paths` → [Array<String>]

The locations in which component previews will be looked up.
Defaults to `['test/component/previews']` relative to your Rails root.

### `.preview_route` → [String]

The entry route for component previews.
Defaults to `"/rails/view_components"`.

### `.render_monkey_patch_enabled` → [Boolean]

If this is disabled, use `#render_component` or
`#render_component_to_string` instead.
Defaults to `true`.

### `.show_previews` → [Boolean]

Whether component previews are enabled.
Defaults to `true` in development and test environments.

### `.show_previews_source` → [Boolean]

Whether to display source code previews in component previews.
Defaults to `false`.

### `.test_controller` → [String]

The controller used for testing components.
Can also be configured on a per-test basis using `#with_controller_class`.
Defaults to `ApplicationController`.

### `.view_component_path` → [String]

The path in which components, their templates, and their sidecars should
be stored.
Defaults to `"app/components"`.

## ViewComponent::TestHelpers

### `#render_in_view_context(*args, &block)`

Execute the given block in the view context (using `instance_exec`).
Internally sets `page` to be a `Capybara::Node::Simple`, allowing for
Capybara assertions to be used. All arguments are forwarded to the block.

```ruby
render_in_view_context(arg1, arg2:) do |arg1, arg2:|
  render(MyComponent.new(arg1, arg2))
end

assert_text("Hello, World!")
```

### `#render_inline(component, **args, &block)` → [Nokogiri::HTML]

Render a component inline. Internally sets `page` to be a `Capybara::Node::Simple`,
allowing for Capybara assertions to be used:

```ruby
render_inline(MyComponent.new)
assert_text("Hello, World!")
```

### `#render_preview(name, from: __vc_test_helpers_preview_class, params: {})` → [Nokogiri::HTML]

Render a preview inline. Internally sets `page` to be a `Capybara::Node::Simple`,
allowing for Capybara assertions to be used:

```ruby
render_preview(:default)
assert_text("Hello, World!")
```

Note: `#rendered_preview` expects a preview to be defined with the same class
name as the calling test, but with `Test` replaced with `Preview`:

MyComponentTest -> MyComponentPreview etc.

In RSpec, `Preview` is appended to `described_class`.

### `#rendered_content` → [ActionView::OutputBuffer]

Returns the result of a render_inline call.

### `#vc_test_controller` → [ActionController::Base]

Access the controller used by `render_inline`:

```ruby
test "logged out user sees login link" do
  vc_test_controller.expects(:logged_in?).at_least_once.returns(false)
  render_inline(LoginComponent.new)
  assert_selector("[aria-label='You must be signed in']")
end
```

### `#vc_test_request` → [ActionDispatch::TestRequest]

Access the request used by `render_inline`:

```ruby
test "component does not render in Firefox" do
  request.env["HTTP_USER_AGENT"] = "Mozilla/5.0"
  render_inline(NoFirefoxComponent.new)
  refute_component_rendered
end
```

### `#with_controller_class(klass)`

Set the controller to be used while executing the given block,
allowing access to controller-specific methods:

```ruby
with_controller_class(UsersController) do
  render_inline(MyComponent.new)
end
```

### `#with_request_url(path)`

Set the URL of the current request (such as when using request-dependent path helpers):

```ruby
with_request_url("/users/42") do
  render_inline(MyComponent.new)
end
```

### `#with_variant(variant)`

Set the Action Pack request variant for the given block:

```ruby
with_variant(:phone) do
  render_inline(MyComponent.new)
end
```
