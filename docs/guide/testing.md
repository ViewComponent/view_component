---
layout: default
title: Testing
parent: Guide
---

# Testing

Unit test components using the `render_inline` test helper, asserting against the rendered output:

```ruby
require "test_helper"

class ExampleComponentTest < ViewComponent::TestCase
  def test_render_component
    render_inline(ExampleComponent.new(title: "my title")) { "Hello, World!" }

    assert_selector("span[title='my title']", text: "Hello, World!")
    # or, to just assert against the text:
    assert_text("Hello, World!")
  end
end
```

(Capybara matchers are available if the gem is installed)

_Note: `assert_selector` only matches on visible elements by default. To match on elements regardless of visibility, add `visible: false`. See the [Capybara documentation](https://rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers) for more details._

## Capybara DSL

Some parts of the Capybara DSL are available inside component tests, if the
gem is installed.

Component template:

```html
<table>
  <caption>Content</caption>
  <thead>
    <tr>
      <th>Name</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <td>Value</td>
    </tr>
  </tbody>
</table>
```

Component test:

```ruby
require "test_helper"

class TableComponentTest < ViewComponent::TestCase
  def table
    @table ||= find("table")
  end

  def test_table
    render_inline(TableComponent.new)

    assert has_table?("Content")
  end

  def test_table_header
    render_inline(TableComponent.new)

    within(table.find("thead")) do
      within(first("tr")) do
        assert_selector("th", text: "Name")
      end
    end
  end

  def test_table_body
    render_inline(TableComponent.new)

    within(table.find("tbody")) do
      within(first("tr")) do
        assert_selector("td", text: "Value")
      end
    end
  end
end
```

The available Capybara DSL methods are:

* [`all`](https://rubydoc.info/github/teamcapybara/capybara/Capybara%2FNode%2FFinders:all)
* [`first`](https://rubydoc.info/github/teamcapybara/capybara/Capybara%2FNode%2FFinders:first)
* [`text`](https://rubydoc.info/github/teamcapybara/capybara/Capybara%2FNode%2FSimple:text)
* [`find`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FFinders:find)
* [`find_all`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FFinders:find_all)
* [`find_button`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FFinders:find_button)
* [`find_by_id`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FFinders:find_by_id)
* [`find_field`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FFinders:find_field)
* [`find_link`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FFinders:find_link)
* [`has_content?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_content%3F)
* [`has_text?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_text%3F)
* [`has_css?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_css%3F)
* [`has_no_content?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_content%3F)
* [`has_no_text?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_text%3F)
* [`has_no_css?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_css%3F)
* [`has_no_xpath?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_xpath%3F)
* [`has_xpath?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_xpath%3F)
* [`has_link?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_link%3F)
* [`has_no_link?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_link%3F)
* [`has_button?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_button%3F)
* [`has_no_button?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_button%3F)
* [`has_field?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_field%3F)
* [`has_no_field?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_field%3F)
* [`has_checked_field?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_checked_field%3F)
* [`has_unchecked_field?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_unchecked_field%3F)
* [`has_no_table?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_table%3F)
* [`has_table?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_table%3F)
* [`has_select?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_select%3F)
* [`has_no_select?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_select%3F)
* [`has_selector?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_selector%3F)
* [`has_no_selector?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_selector%3F)
* [`has_no_checked_field?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_checked_field%3F)
* [`has_no_unchecked_field?`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FNode%2FMatchers:has_no_unchecked_field%3F)
* [`within`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FSession:within)
* [`within_element`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FSession:within)
* [`within_fieldset`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FSession:within_fieldset)
* [`within_table`](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara%2FSession:within_table)

## (Experimental) Previews as test cases

Use `render_preview(name)` to render previews in ViewComponent unit tests:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  include ViewComponent::RenderPreviewHelper

  def test_render_preview
    render_preview(:with_default_title)

    assert_text("Example component default")
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
    component.title { "Hello!" }
    component.body { "Have a nice day." }
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

## Configuring the controller used in tests

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
require "capybara/rspec"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
end
```

To access Devise's controller helper methods in tests, add the following:

```ruby
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :component

  config.before(:each, type: :component) do
    @request = controller.request
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
