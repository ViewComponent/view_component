---
layout: default
title: Building ViewComponents
nav_order: 3
has_children: true
---

# Building ViewComponents

## Conventions

Components are subclasses of `ViewComponent::Base` and live in `app/components`. It's common practice to create and inherit from an `ApplicationComponent` that is a subclass of `ViewComponent::Base`.

Component names end in -`Component`.

Component module names are plural, as for controllers and jobs: `Users::AvatarComponent`

Name components for what they render, not what they accept. (`AvatarComponent` instead of `UserComponent`)

## Quick start

Use the component generator to create a new ViewComponent.

The generator accepts a component name and a list of arguments:

```bash
bin/rails generate component Example title

      invoke  test_unit
      create  test/components/example_component_test.rb
      create  app/components/example_component.rb
      create  app/components/example_component.html.erb
```

ViewComponent includes template generators for the `erb`, `haml`, and `slim` template engines and will default to the template engine specified in `config.generators.template_engine`.

The template engine can also be passed as an option to the generator:

```bash
bin/rails generate component Example title --template-engine slim
```

To generate a [preview](#previewing-components), pass the `--preview` option:

```bash
bin/rails generate component Example title --preview
```

## Implementation

A ViewComponent is a Ruby file and corresponding template file with the same base name:

`app/components/example_component.rb`:

```ruby
class ExampleComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
end
```

`app/components/example_component.html.erb`:

```erb
<span title="<%= @title %>"><%= content %></span>
```

_Content passed to a ViewComponent as a block is captured and assigned to the `content` accessor._

Rendered in a view as:

```erb
<%= render(ExampleComponent.new(title: "my title")) do %>
  Hello, World!
<% end %>
```

Returning:

```html
<span title="my title">Hello, World!</span>
```

## Inline Component

ViewComponents can render without a template file, by defining a `call` method:

`app/components/inline_component.rb`:

```ruby
class InlineComponent < ViewComponent::Base
  def call
    if active?
      link_to "Cancel integration", integration_path, method: :delete
    else
      link_to "Integrate now!", integration_path
    end
  end
end
```

It is also possible to define methods for variants:

```ruby
class InlineVariantComponent < ViewComponent::Base
  def call_phone
    link_to "Phone", phone_path
  end

  def call
    link_to "Default", default_path
  end
end
```

And render them `with_variant`:

```erb
<%= render InlineVariantComponent.new.with_variant(:phone) %>

# output: <%= link_to "Phone", phone_path %>
```

_**Note**: `call_*` methods must be public._

## Validations

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

## Template Inheritance

Components that subclass another component inherit the parent component's
template if they don't define their own template.

```ruby
# If `my_link_component.html.erb` is not defined the component will fall back
# to `LinkComponent`s template
class MyLinkComponent < LinkComponent
end
```

# Sidecar Assets

ViewComponents supports two options for defining view files.

## Sidecar view

The simplest option is to place the view next to the Ruby component:

```console
app/components
├── ...
├── example_component.rb
├── example_component.html.erb
├── ...
```

## Sidecar directory

As an alternative, views and other assets can be placed in a sidecar directory with the same name as the component, which can be useful for organizing views alongside other assets like Javascript and CSS.

```console
app/components
├── ...
├── example_component.rb
├── example_component
|   ├── example_component.css
|   ├── example_component.html.erb
|   └── example_component.js
├── ...
```

To generate a component with a sidecar directory, use the `--sidecar` flag:

```console
bin/rails generate component Example title --sidecar
      invoke  test_unit
      create  test/components/example_component_test.rb
      create  app/components/example_component.rb
      create  app/components/example_component/example_component.html.erb
```

## Component file inside Sidecar directory

It's also possible to place the Ruby component file inside the sidecar directory, grouping all related files in the same folder:

_Note: Avoid giving your containing folder the same name as your `.rb` file or there will be a conflict between Module and Class definitions_

```console
app/components
├── ...
├── example
|   ├── component.rb
|   ├── component.css
|   ├── component.html.erb
|   └── component.js
├── ...

```

The component can then be rendered using the folder name as a namespace:

```erb
<%= render(Example::Component.new(title: "my title")) do %>
  Hello, World!
<% end %>
```

# Conditional Rendering

Components can implement a `#render?` method to be called after initialization to determine if the component should render.

Traditionally, the logic for whether to render a view could go in either the component template:

`app/components/confirm_email_component.html.erb`

```erb
<% if user.requires_confirmation? %>
  <div class="alert">Please confirm your email address.</div>
<% end %>
```

or the view that renders the component:

`app/views/_banners.html.erb`

```erb
<% if current_user.requires_confirmation? %>
  <%= render(ConfirmEmailComponent.new(user: current_user)) %>
<% end %>
```

Using the `#render?` hook simplifies the view:

`app/components/confirm_email_component.rb`

```ruby
class ConfirmEmailComponent < ViewComponent::Base
  def initialize(user:)
    @user = user
  end

  def render?
    @user.requires_confirmation?
  end
end
```

`app/components/confirm_email_component.html.erb`

```erb
<div class="banner">
  Please confirm your email address.
</div>
```

`app/views/_banners.html.erb`

```erb
<%= render(ConfirmEmailComponent.new(user: current_user)) %>
```

_To assert that a component has not been rendered, use `refute_component_rendered` from `ViewComponent::TestHelpers`._

# `#before_render`

ViewComponents can define a `before_render` method to be called before a component is rendered, when `helpers` is able to be used:

`app/components/example_component.rb`

```ruby
class ExampleComponent < ViewComponent::Base
  def before_render
    @my_icon = helpers.star_icon
  end
end
```

## Using helpers

Helper methods can be used through the `helpers` proxy:

```ruby
module IconHelper
  def icon(name)
    tag.i data: { feather: name.to_s.dasherize }
  end
end

class UserComponent < ViewComponent::Base
  def profile_icon
    helpers.icon :user
  end
end
```

Which can be used with `delegate`:

```ruby
class UserComponent < ViewComponent::Base
  delegate :icon, to: :helpers

  def profile_icon
    icon :user
  end
end
```

Helpers can also be used by including the helper:

```ruby
class UserComponent < ViewComponent::Base
  include IconHelper

  def profile_icon
    icon :user
  end
end
```

## Using nested URL helpers

Rails nested URL helpers implicitly depend on the current `request` in certain cases. Since ViewComponent is built to enable reusing components in different contexts, nested URL helpers should be passed their options explicitly:

```ruby
# bad
edit_user_path # implicitly depends on current request to provide `user`

# good
edit_user_path(user: current_user)
```

# Writing tests

Unit test components directly, using the `render_inline` test helper, asserting against the rendered output.

Capybara matchers are available if the gem is installed:

```ruby
require "view_component/test_case"

class ExampleComponentTest < ViewComponent::TestCase
  def test_render_component
    render_inline(ExampleComponent.new(title: "my title")) { "Hello, World!" }

    assert_selector("span[title='my title']", text: "Hello, World!")
    # or, to just assert against the text:
    assert_text("Hello, World!")
  end
end
```

_Note: `assert_selector` only matches on visible elements by default. To match on hidden elements, add `visible: false`. See the [Capybara documentation](https://rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers) for more details._

In the absence of `capybara`, assert against the return value of `render_inline`, which is an instance of `Nokogiri::HTML::DocumentFragment`:

```ruby
def test_render_component
  result = render_inline(ExampleComponent.new(title: "my title")) { "Hello, World!" }

  assert_includes result.css("span[title='my title']").to_html, "Hello, World!"
end
```

Alternatively, assert against the raw output of the component, which is exposed as `rendered_component`:

```ruby
def test_render_component
  render_inline(ExampleComponent.new(title: "my title")) { "Hello, World!" }

  assert_includes rendered_component, "Hello, World!"
end
```

To test components that use `with_content_areas`:

```ruby
def test_renders_content_areas_template_with_content
  render_inline(ContentAreasComponent.new(footer: "Bye!")) do |component|
    component.with(:title, "Hello!")
    component.with(:body) { "Have a nice day." }
  end

  assert_selector(".title", text: "Hello!")
  assert_selector(".body", text: "Have a nice day.")
  assert_selector(".footer", text: "Bye!")
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
# Configuring the controller used in tests

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

# Setting up RSpec

To use RSpec, add the following:

`spec/rails_helper.rb`

```ruby
require "view_component/test_helpers"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
end
```

Specs created by the generator have access to test helpers like `render_inline`.

To use component previews:

`config/application.rb`

```ruby
config.view_component.preview_paths << "#{Rails.root}/spec/components/previews"
```

# Disabling the render monkey patch (Rails < 6.1)

In order to [avoid conflicts](https://github.com/github/view_component/issues/288) between ViewComponent and other gems that also monkey patch the `render` method, it is possible to configure ViewComponent to not include the render monkey patch:

`config.view_component.render_monkey_patch_enabled = false # defaults to true`

With the monkey patch disabled, use `render_component` (or  `render_component_to_string`) instead:

```erb
<%= render_component Component.new(message: "bar") %>
```
