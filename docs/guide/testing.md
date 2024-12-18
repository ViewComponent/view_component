---
layout: default
title: Testing
parent: How-to guide
---

# Testing

Unit test components using the `render_inline` test helper, asserting against the rendered output:

```ruby
require "test_helper"

class ExampleComponentTest < ViewComponent::TestCase
  def test_render_component
    render_inline(ExampleComponent.new(title: "my title")) { "Hello, World!" }

    assert_component_rendered

    assert_selector("span[title='my title']", text: "Hello, World!")
    # or, to just assert against the text:
    assert_text("Hello, World!")
  end
end
```

(Capybara matchers are available if the gem is installed)

_Note: `assert_selector` only matches on visible elements by default. To match on elements regardless of visibility, add `visible: false`. See the [Capybara documentation](https://rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers) for more details._

For debugging purposes, the `rendered_content` test helper outputs the rendered HTML.

## Use with RSpec

To enable ViewComponent test helpers in RSpec, add:

```ruby
# spec/rails_helper.rb
require "view_component/test_helpers"

RSpec.configure do |config|
  # ...

  config.include ViewComponent::TestHelpers, type: :component
end
```

## Testing Slots

```ruby
def test_render_component
  component = ListComponent.new(title: "Fruits").tap do |c|
    c.with_item { "Apple" }
    c.with_item { "Orange" }
    c.with_extra { "<div><span>rendered html</span></div>".html_safe }
  end

  render_inline(component)

  assert_selector("ul")
  assert_selector("li", text: "Apple")
  assert_selector("li", text: "Orange")
end
```

## Previews as test cases

Since 2.56.0
{: .label }

Use `render_preview(name)` to render previews in ViewComponent unit tests:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_render_preview
    render_preview(:with_default_title)

    assert_text("Example component default")
  end
end
```

## Testing components with behaviors

To test ViewComponents with behaviors, visit a preview in a system test:

```ruby
class MyComponentSystemTest < ActionDispatch::SystemTestCase
  def test_default_preview
    visit("/rails/view_components/my_component/default")

    click_on("Open dialog")

    assert_text("Test Dialog")
  end
end
```

## Best practices

Prefer testing the rendered output over individual methods:

```ruby
# Good
assert_selector(".Label", text: "My label")

# Bad
assert_equal MyComponent.new.label, "My label"
```

## Without `capybara`

In the absence of `capybara`, assert against the return value of `render_inline`, which is an instance of `Nokogiri::HTML::DocumentFragment`:

```ruby
def test_render_component
  result = render_inline(ExampleComponent.new(title: "my title")) { "Hello, World!" }

  assert_includes result.css("span[title='my title']").to_html, "Hello, World!"
end
```

## Slots

To test components that use Slots:

```ruby
def test_renders_slots_with_content
  render_inline(SlotsComponent.new(footer: "Bye!")) do |component|
    component.with_title { "Hello!" }
    component.with_body { "Have a nice day." }
  end

  assert_selector(".title", text: "Hello!")
  assert_selector(".body", text: "Have a nice day.")
end
```

## Action Pack Variants

Use the `with_variant` helper to test specific variants:

```ruby
def test_render_component_for_tablet
  with_variant :tablet do
    render_inline(ExampleComponent.new(title: "my title")) { "Hello, tablets!" }

    assert_selector("span[title='my title']", text: "Hello, tablets!")
  end
end
```

## Request formats

Use the `with_format` helper to test specific request formats:

```ruby
def test_render_component_as_json
  with_format :json do
    render_inline(MultipleFormatsComponent.new)

    assert_equal(rendered_json["hello"], "world")
  end
end
```

## Configuring the controller used in tests

Since 2.27.0
{: .label }

Component tests assume the existence of an `ApplicationController` class, which can be configured globally using the `test_controller` option:

```ruby
config.view_component.test_controller = "BaseController"
```

To configure the controller used for a test case, use `with_controller_class` from `ViewComponent::TestHelpers`.

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_component_in_public_controller
    with_controller_class PublicController do
      render_inline ExampleComponent.new

      assert_text "foo"
    end
  end

  def test_component_in_authenticated_controller
    with_controller_class AuthenticatedController do
      render_inline ExampleComponent.new

      assert_text "bar"
    end
  end
end
```

## Setting `request.path_parameters`

Since 2.31.0
{: .label }

Some Rails helpers won't work unless `request.path_parameters` are set correctly, resulting in an `ActionController::UrlGenerationError`.

To set `request.path_parameters` for a test case, use `with_request_url` from `ViewComponent::TestHelpers`:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_with_request_url
    with_request_url "/products/42" do
      render_inline ExampleComponent.new # contains i.e. `link_to "French", url_for(locale: "fr")`
      assert_link "French", href: "/products/42?locale=fr"
    end
  end
end
```

## Setting `request.host`

Since 3.3.0
{: .label }

Rails routes that have a subdomain constraint require `request.host` to be set correctly.

To set `request.host` for a test case, use `with_request_url` from `ViewComponent::TestHelpers`:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_with_request_url
    with_request_url "/products/42", host: "app.example.com" do
      render_inline ExampleComponent.new # contains i.e. `products_path` that is constrained to the 'app' subdomain
      assert_link "Products", href: "/products"
    end
  end
end
```

### Query parameters

Since 2.41.0
{: .label }

It's also possible to set query parameters:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_with_request_url
    with_request_url "/products/42?locale=en" do
      render_inline ExampleComponent.new # contains i.e. `link_to "Recent", url_for(request.query_parameters.merge(filter: "recent"))`
      assert_link "Recent", href: "/?locale=en&filter=recent"
    end
  end
end
```

## RSpec configuration

To use RSpec, add the following:

```ruby
# spec/rails_helper.rb
require "view_component/test_helpers"
require "view_component/system_test_helpers"
require "capybara/rspec"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
end
```

To access Devise's controller helper methods in tests, add the following:

```ruby
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :component

  config.before(:each, type: :component) do
    @request = vc_test_controller.request
  end
end
```

Specs created by the generator have access to test helpers like `render_inline`. For example:

```ruby
require "rails_helper"

RSpec.describe ExampleComponent, type: :component do
  it "renders component" do
    render_inline(described_class.new(title: "my title")) { "Hello, World!" }

    expect(page).to have_css "span[title='my title']", text: "Hello, World!"
    # or, to just assert against the text
    expect(page).to have_text "Hello, World!"
  end
end
```

To use component previews:

```ruby
# config/application.rb
config.view_component.preview_paths << "#{Rails.root}/spec/components/previews"
```

## Component system tests

Use `with_rendered_component_path` with `render_inline` to system test components:

```rb
class ViewComponentSystemTest < ViewComponent::SystemTestCase
  def test_simple_js_interaction_in_browser_without_layout
    with_rendered_component_path(render_inline(SimpleJavascriptInteractionWithJsIncludedComponent.new)) do |path|
      visit(path)

      assert(find("[data-hidden-field]", visible: false))
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert(find("[data-hidden-field]", visible: true))
    end
  end
end
```

For components that depend on a layout, provide the `layout` argument:

```rb
class ViewComponentSystemTest < ViewComponent::SystemTestCase
  def test_simple_js_interaction_in_browser_with_layout
    with_rendered_component_path(render_inline(SimpleJavascriptInteractionWithoutJsIncludedComponent.new), layout: "application") do |path|
      # ...
    end
  end
end
```
