# ViewComponent

ViewComponent is a framework for building view components that are reusable, testable & encapsulated, in Ruby on Rails.

## Design philosophy

ViewComponent is designed to integrate as seamlessly as possible [with Rails](https://rubyonrails.org/doctrine/), with the [least surprise](https://www.artima.com/intv/ruby4.html).

## Compatibility

ViewComponent is [supported natively](https://edgeguides.rubyonrails.org/layouts_and_rendering.html#rendering-objects) in Rails 6.1, and compatible with Rails 5.0+ via an included [monkey patch](https://github.com/github/view_component/blob/master/lib/view_component/render_monkey_patch.rb).

ViewComponent is tested for compatibility [with combinations of](https://github.com/github/view_component/blob/22e3d4ccce70d8f32c7375e5a5ccc3f70b22a703/.github/workflows/ruby_on_rails.yml#L10-L11) Ruby 2.4+ and Rails 5+.

## Installation

In `Gemfile`, add:

```ruby
gem "view_component"
```

In `config/application.rb`, add:

```bash
require "view_component/engine"
```

## Guide

### What are components?

ViewComponents are Ruby objects that output HTML. Think of them as an evolution of the presenter pattern, inspired by [React](https://reactjs.org/docs/react-component.html).

Components are most effective in cases where view code is reused or benefits from being tested directly.

### Why should I use components?

#### Testing

Unlike traditional Rails views, ViewComponents can be unit-tested. In the GitHub codebase, component unit tests take around 25 milliseconds each, compared to about six seconds for controller tests.

Rails views are typically tested with slow integration tests that also exercise the routing and controller layers in addition to the view. This cost often discourages thorough test coverage.

With ViewComponent, integration tests can be reserved for end-to-end assertions, with permutations and corner cases covered at the unit level.

#### Data Flow

Traditional Rails views have an implicit interface, making it hard to reason about what information is needed to render, leading to subtle bugs when rendering the same view in different contexts.

ViewComponents use a standard Ruby initializer that clearly defines what is needed to render, making them easier (and safer) to reuse than partials.

#### Performance

Based on our [benchmarks](performance/benchmark.rb), ViewComponents are ~10x faster than partials.

#### Standards

Views often fail basic Ruby code quality standards: long methods, deep conditional nesting, and mystery guests abound.

ViewComponents are Ruby objects, making it easy to follow (and enforce) code quality standards.

### Building components

#### Conventions

Components are subclasses of `ViewComponent::Base` and live in `app/components`. It's common practice to create and inherit from an `ApplicationComponent` that is a subclass of `ViewComponent::Base`.

Component names end in -`Component`.

Component module names are plural, as for controllers and jobs: `Users::AvatarComponent`

Name components for what they render, not what they accept. (`AvatarComponent` instead of `UserComponent`)

#### Quick start

Use the component generator to create a new ViewComponent.

The generator accepts a component name and a list of arguments:

```bash
bin/rails generate component Example title content
      invoke  test_unit
      create  test/components/example_component_test.rb
      create  app/components/example_component.rb
      create  app/components/example_component.html.erb
```

ViewComponent includes template generators for the `erb`, `haml`, and `slim` template engines and will default to the template engine specified in `config.generators.template_engine`.

The template engine can also be passed as an option to the generator:

```bash
bin/rails generate component Example title content --template-engine slim
```

#### Implementation

A ViewComponent is a Ruby file and corresponding template file with the same base name:

`app/components/test_component.rb`:

```ruby
class TestComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
end
```

`app/components/test_component.html.erb`:

```erb
<span title="<%= @title %>"><%= content %></span>
```

Rendered in a view as:

```erb
<%= render(TestComponent.new(title: "my title")) do %>
  Hello, World!
<% end %>
```

Returning:

```html
<span title="my title">Hello, World!</span>
```

#### Content Areas

Content passed to a ViewComponent as a block is captured and assigned to the `content` accessor.

ViewComponents can declare additional content areas. For example:

`app/components/modal_component.rb`:

```ruby
class ModalComponent < ViewComponent::Base
  with_content_areas :header, :body
end
```

`app/components/modal_component.html.erb`:

```erb
<div class="modal">
  <div class="header"><%= header %></div>
  <div class="body"><%= body %></div>
</div>
```

Rendered in a view as:

```erb
<%= render(ModalComponent.new) do |component| %>
  <% component.with(:header) do %>
      Hello Jane
    <% end %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

Returning:

```html
<div class="modal">
  <div class="header">Hello Jane</div>
  <div class="body"><p>Have a great day.</p></div>
</div>
```

#### Slots (experimental)

_Slots are currently under development as a successor to Content Areas. The Slot APIs should be considered unfinished and subject to breaking changes in non-major releases of ViewComponent._

Slots enable multiple blocks of content to be passed to a single ViewComponent, reducing the need for sub-components (e.g. ModalHeader, ModalBody).

By default, slots can be rendered once per component. They provide an accessor with the name of the slot (`#header`) that returns an instance of `ViewComponent::Slot`, etc.

Slots declared with `collection: true` can be rendered multiple times. They provide an accessor with the pluralized name of the slot (`#rows`), which is an Array of `ViewComponent::Slot` instances.

To learn more about the design of the Slots API, see [#348](https://github.com/github/view_component/pull/348) and [#325](https://github.com/github/view_component/discussions/325).

##### Defining Slots

Slots are defined by `with_slot`:

`with_slot :header`

To define a collection slot, add `collection: true`:

`with_slot :row, collection: true`

To define a slot with a custom Ruby class, pass `class_name`:

`with_slot :body, class_name: 'BodySlot`

_Note: Slot classes must be subclasses of `ViewComponent::Slot`._

##### Example ViewComponent with Slots

`# box_component.rb`

```ruby
class BoxComponent < ViewComponent::Base
  include ViewComponent::Slotable

  with_slot :body, :footer
  with_slot :header, class_name: "Header"
  with_slot :row, collection: true, class_name: "Row"

  class Header < ViewComponent::Slot
    def initialize(classes: "")
      @classes = classes
    end

    def classes
      "Box-header #{@classes}"
    end
  end

  class Row < ViewComponent::Slot
    def initialize(theme: :gray)
      @theme = theme
    end

    def theme_class_name
      case @theme
      when :gray
        "Box-row--gray"
      when :hover_gray
        "Box-row--hover-gray"
      when :yellow
        "Box-row--yellow"
      when :blue
        "Box-row--blue"
      when :hover_blue
        "Box-row--hover-blue"
      else
        "Box-row--gray"
      end
    end
  end
end
```

`# box_component.html.erb`

```erb
<div class="Box">
  <% if header %>
    <div class="<%= header.classes %>">
      <%= header.content %>
    </div>
  <% end %>
  <% if body %>
    <div class="Box-body">
      <%= body.content %>
    </div>
  <% end %>
  <% if rows.any? %>
    <ul>
      <% rows.each do |row| %>
        <li class="Box-row <%= row.theme_class_name %>">
          <%= row.content %>
        </li>
      <% end %>
    </ul>
  <% end %>
  <% if footer %>
    <div class="Box-footer">
      <%= footer.content %>
    </div>
  <% end %>
</div>
```

`# index.html.erb`

```erb
<%= render(BoxComponent.new) do |component| %>
  <% component.slot(:header, classes: "my-class-name") do %>
    This is my header!
  <% end %>
  <% component.slot(:body) do %>
    This is the body.
  <% end %>
  <% component.slot(:row) do %>
    Row one
  <% end %>
  <% component.slot(:row, theme: :yellow) do %>
    Yellow row
  <% end %>
  <% component.slot(:footer) do %>
    This is the footer.
  <% end %>
<% end %>
```

### Inline Component

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

### Template Inheritance

Components that subclass another component inherit the parent component's
template if they don't define their own template.

```ruby
# If `my_link_component.html.erb` is not defined the component will fall back
# to `LinkComponent`s template
class MyLinkComponent < LinkComponent
end
```

### Sidecar Assets

ViewComponents supports two options for defining view files.

#### Sidecar view

The simplest option is to place the view next to the Ruby component:

```console
app/components
├── ...
├── test_component.rb
├── test_component.html.erb
├── ...
```

#### Sidecar directory

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
bin/rails generate component Example title content --sidecar
      invoke  test_unit
      create  test/components/example_component_test.rb
      create  app/components/example_component.rb
      create  app/components/example_component/example_component.html.erb
```

#### Component file inside Sidecar directory

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

### Conditional Rendering

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

### `before_render`

Components can define a `before_render` method to be called before a component is rendered, when `helpers` is able to be used:

`app/components/confirm_email_component.rb`

```ruby
class MyComponent < ViewComponent::Base
  def before_render
    @my_icon = helpers.star_icon
  end
end
```

### Rendering collections

Use `with_collection` to render a ViewComponent with a collection:

`app/view/products/index.html.erb`

``` erb
<%= render(ProductComponent.with_collection(@products)) %>
```

`app/components/product_component.rb`

``` ruby
class ProductComponent < ViewComponent::Base
  def initialize(product:)
    @product = product
  end
end
```

[By default](https://github.com/github/view_component/blob/89f8fab4609c1ef2467cf434d283864b3c754473/lib/view_component/base.rb#L249), the component name is used to define the parameter passed into the component from the collection.

#### `with_collection_parameter`

Use `with_collection_parameter` to change the name of the collection parameter:

`app/components/product_component.rb`

``` ruby
class ProductComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:)
    @item = item
  end
end
```

#### Additional arguments

Additional arguments besides the collection are passed to each component instance:

`app/view/products/index.html.erb`

``` erb
<%= render(ProductComponent.with_collection(@products, notice: "hi")) %>
```

`app/components/product_component.rb`

``` ruby
class ProductComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:, notice:)
    @item = item
    @notice = notice
  end
end
```

`app/components/product_component.html.erb`

``` erb
<li>
  <h2><%= @item.name %></h2>
  <span><%= @notice %></span>
</li>
```

#### Collection counter

ViewComponent defines a counter variable matching the parameter name above, followed by `_counter`. To access the variable, add it to `initialize` as an argument:

`app/components/product_component.rb`

``` ruby
class ProductComponent < ViewComponent::Base
  def initialize(product:, product_counter:)
    @product = product
    @counter = product_counter
  end
end
```

`app/components/product_component.html.erb`

``` erb
<li>
  <%= @counter %> <%= @product.name %>
</li>
```

### Using helpers

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

### Writing tests

Unit test components directly, using the `render_inline` test helper, asserting against the rendered output.

Capybara matchers are available if the gem is installed:

```ruby
require "view_component/test_case"

class MyComponentTest < ViewComponent::TestCase
  test "render component" do
    render_inline(TestComponent.new(title: "my title")) { "Hello, World!" }

    assert_selector("span[title='my title']", text: "Hello, World!")
  end
end
```

In the absence of `capybara`, assert against the return value of `render_inline`, which is an instance of `Nokogiri::HTML::DocumentFragment`:

```ruby
test "render component" do
  result = render_inline(TestComponent.new(title: "my title")) { "Hello, World!" }

  assert_includes result.css("span[title='my title']").to_html, "Hello, World!"
end
```

Alternatively, assert against the raw output of the component, which is exposed as `rendered_component`:

```ruby
test "render component" do
  render_inline(TestComponent.new(title: "my title")) { "Hello, World!" }

  assert_includes rendered_component, "Hello, World!"
end
```

To test components that use `with_content_areas`:

```ruby
test "renders content_areas template with content " do
  render_inline(ContentAreasComponent.new(footer: "Bye!")) do |component|
    component.with(:title, "Hello!")
    component.with(:body) { "Have a nice day." }
  end

  assert_selector(".title", text: "Hello!")
  assert_selector(".body", text: "Have a nice day.")
  assert_selector(".footer", text: "Bye!")
end
```

#### Action Pack Variants

Use the `with_variant` helper to test specific variants:

```ruby
test "render component for tablet" do
  with_variant :tablet do
    render_inline(TestComponent.new(title: "my title")) { "Hello, tablets!" }

    assert_selector("span[title='my title']", text: "Hello, tablets!")
  end
end
```

### Previewing Components

`ViewComponent::Preview`, like `ActionMailer::Preview`, provides a way to preview components in isolation:

`test/components/previews/test_component_preview.rb`

```ruby
class TestComponentPreview < ViewComponent::Preview
  def with_default_title
    render(TestComponent.new(title: "Test component default"))
  end

  def with_long_title
    render(TestComponent.new(title: "This is a really long title to see how the component renders this"))
  end

  def with_content_block
    render(TestComponent.new(title: "This component accepts a block of content")) do
      tag.div do
        content_tag(:span, "Hello")
      end
    end
  end
end
```

Which generates <http://localhost:3000/rails/view_components/test_component/with_default_title>,
<http://localhost:3000/rails/view_components/test_component/with_long_title>,
and <http://localhost:3000/rails/view_components/test_component/with_content_block>.

It's also possible to set dynamic values from the params by setting them as arguments:

`test/components/previews/test_component_preview.rb`

```ruby
class TestComponentPreview < ViewComponent::Preview
  def with_dynamic_title(title: "Test component default")
    render(TestComponent.new(title: title))
  end
end
```

Which enables passing in a value with <http://localhost:3000/rails/components/test_component/with_dynamic_title?title=Custom+title>.

The `ViewComponent::Preview` base class includes
[`ActionView::Helpers::TagHelper`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html), which provides the [`tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-tag)
and [`content_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-content_tag) view helper methods.

Previews use the application layout by default, but can use a specific layout with the `layout` option:

`test/components/previews/test_component_preview.rb`

```ruby
class TestComponentPreview < ViewComponent::Preview
  layout "admin"

  ...
end
```

You can also set a custom layout to be used by default for previews as well as the preview index pages via the `default_preview_layout` configuration option:

`config/application.rb`

```ruby
# Set the default layout to app/views/layouts/component_preview.html.erb
config.view_component.default_preview_layout = "component_preview"
```

Preview classes live in `test/components/previews`, which can be configured using the `preview_paths` option:

`config/application.rb`

```ruby
config.view_component.preview_paths << "#{Rails.root}/lib/component_previews"
```

Previews are served from <http://localhost:3000/rails/view_components> by default. To use a different endpoint, set the `preview_route` option:

`config/application.rb`

```ruby
config.view_component.preview_route = "/previews"
```

This example will make the previews available from <http://localhost:3000/previews>.

#### Preview templates

Given a preview `test/components/previews/cell_component_preview.rb`, template files can be defined at `test/components/previews/cell_component_preview/`:

`test/components/previews/cell_component_preview.rb`

```ruby
class CellComponentPreview < ViewComponent::Preview
  def default
  end
end
```

`test/components/previews/cell_component_preview/default.html.erb`

```erb
<table class="table">
  <tbody>
    <tr>
      <%= render CellComponent.new %>
    </tr>
  </tbody>
</div>
```

To use a different location for preview templates, pass the `template` argument:
(the path should be relative to `config.view_component.preview_path`):

`test/components/previews/cell_component_preview.rb`

```ruby
class CellComponentPreview < ViewComponent::Preview
  def default
    render_with_template(template: 'custom_cell_component_preview/my_preview_template')
  end
end
```

Values from `params` can be accessed through `locals`:

`test/components/previews/cell_component_preview.rb`

```ruby
class CellComponentPreview < ViewComponent::Preview
  def default(title: "Default title", subtitle: "A subtitle")
    render_with_template(locals: {
      title: title,
      subtitle: subtitle
    })
  end
end
```

Which enables passing in a value with <http://localhost:3000/rails/components/cell_component/default?title=Custom+title&subtitle=Another+subtitle>.

#### Configuring TestController

Component tests and previews assume the existence of an `ApplicationController` class, which be can be configured using the `test_controller` option:

`config/application.rb`

```ruby
config.view_component.test_controller = "BaseController"
```

### Setting up RSpec

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

### Disabling the render monkey patch (Rails < 6.1)

In order to [avoid conflicts](https://github.com/github/view_component/issues/288) between ViewComponent and other gems that also monkey patch the `render` method, it is possible to configure ViewComponent to not include the render monkey patch:

`config.view_component.render_monkey_patch_enabled = false # defaults to true`

With the monkey patch disabled, use `render_component` (or  `render_component_to_string`) instead:

```erb
<%= render_component Component.new(message: "bar") %>
```

### Sidecar assets (experimental)

It’s possible to include Javascript and CSS alongside components, sometimes called "sidecar" assets or files.

To use the Webpacker gem to compile sidecar assets located in `app/components`:

1. In `config/webpacker.yml`, add `"app/components"` to the `resolved_paths` array (e.g. `resolved_paths: ["app/components"]`).
2. In the Webpack entry file (often `app/javascript/packs/application.js`), add an import statement to a helper file, and in the helper file, import the components' Javascript:

```js
import "../components"
```

Then, in `app/javascript/components.js`, add:

```js
function importAll(r) {
  r.keys().forEach(r)
}

importAll(require.context("../components", true, /_component.js$/))
```

Any file with the `_component.js` suffix (such as `app/components/widget_component.js`) will be compiled into the Webpack bundle. If that file itself imports another file, for example `app/components/widget_component.css`, it will also be compiled and bundled into Webpack's output stylesheet if Webpack is being used for styles.

#### Encapsulating sidecar assets

Ideally, sidecar Javascript/CSS should not "leak" out of the context of its associated component.

One approach is to use Web Components, which contain all Javascript functionality, internal markup, and styles within the shadow root of the Web Component.

For example:

`app/components/comment_component.rb`

```ruby
class CommentComponent < ViewComponent::Base
  def initialize(comment:)
    @comment = comment
  end

  def commenter
    @comment.user
  end

  def commenter_name
    commenter.name
  end

  def avatar
    commenter.avatar_image_url
  end

  def formatted_body
    simple_format(@comment.body)
  end

  private

  attr_reader :comment
end
```

`app/components/comment_component.html.erb`

```erb
<my-comment comment-id="<%= comment.id %>">
  <time slot="posted" datetime="<%= comment.created_at.iso8601 %>"><%= comment.created_at.strftime("%b %-d") %></time>

  <div slot="avatar"><img src="<%= avatar %>" /></div>

  <div slot="author"><%= commenter_name %></div>

  <div slot="body"><%= formatted_body %></div>
</my-comment>
```

`app/components/comment_component.js`

```js
class Comment extends HTMLElement {
  styles() {
    return `
      :host {
        display: block;
      }
      ::slotted(time) {
        float: right;
        font-size: 0.75em;
      }
      .commenter { font-weight: bold; }
      .body { … }
    `
  }

  constructor() {
    super()
    const shadow = this.attachShadow({mode: 'open'});
    shadow.innerHTML = `
      <style>
        ${this.styles()}
      </style>
      <slot name="posted"></slot>
      <div class="commenter">
        <slot name="avatar"></slot> <slot name="author"></slot>
      </div>
      <div class="body">
        <slot name="body"></slot>
      </div>
    `
  }
}
customElements.define('my-comment', Comment)
```

##### Stimulus

In Stimulus, create a 1:1 mapping between a Stimulus controller and a component. In order to load in Stimulus controllers from the `app/components` tree, amend the Stimulus boot code in `app/javascript/packs/application.js`:

```js
const application = Application.start()
const context = require.context("controllers", true, /.js$/)
const context_components = require.context("../../components", true, /_controller.js$/)
application.load(
  definitionsFromContext(context).concat(
    definitionsFromContext(context_components)
  )
)
```

This enables the creation of files such as `app/components/widget_controller.js`, where the controller identifier matches the `data-controller` attribute in the component's HTML template.

After configuring Webpack to load Stimulus controller files from the `components` directory, add the path to `resolved_paths` in `config/webpacker.yml`:

```yml
  resolved_paths: ["app/components"]
```

When placing a Stimulus controller inside a sidecar directory, be aware that when referencing the controller [each forward slash in a namespaced controller file’s path becomes two dashes in its identifier](
https://stimulusjs.org/handbook/installing#controller-filenames-map-to-identifiers):

```console
app/components
├── ...
├── example
|   ├── component.rb
|   ├── component.css
|   ├── component.html.erb
|   └── component_controller.js
├── ...
```

`component_controller.js`'s Stimulus identifier becomes: `example--component`:

```erb
<div data-controller="example--component">
  <input type="text">
  <button data-action="click->example--component#greet">Greet</button>
</div>
```

## Frequently Asked Questions

### Can I use other templating languages besides ERB?

Yes. ViewComponent is tested against ERB, Haml, and Slim, but it should support most Rails template handlers.

### Isn't this just like X library?

ViewComponent is far from a novel idea! Popular implementations of view components in Ruby include, but are not limited to:

- [trailblazer/cells](https://github.com/trailblazer/cells)
- [dry-rb/dry-view](https://github.com/dry-rb/dry-view)
- [komposable/komponent](https://github.com/komposable/komponent)
- [activeadmin/arbre](https://github.com/activeadmin/arbre)

## Resources

- [Encapsulating Views, RailsConf 2020](https://youtu.be/YVYRus_2KZM)
- [Rethinking the View Layer with Components, Ruby Rogues Podcast](https://devchat.tv/ruby-rogues/rr-461-rethinking-the-view-layer-with-components-with-joel-hawksley/)
- [ViewComponents in Action with Andrew Mason, Ruby on Rails Podcast](https://5by5.tv/rubyonrails/320)
- [ViewComponent at GitHub with Joel Hawksley](https://the-ruby-blend.fireside.fm/9)
- [Components, HAML vs ERB, and Design Systems](https://the-ruby-blend.fireside.fm/4)
- [Choosing the Right Tech Stack with Dave Paola](https://5by5.tv/rubyonrails/307)
- [Rethinking the View Layer with Components, RailsConf 2019](https://www.youtube.com/watch?v=y5Z5a6QdA-M)
- [Introducing ActionView::Component with Joel Hawksley, Ruby on Rails Podcast](http://5by5.tv/rubyonrails/276)
- [Rails to Introduce View Components, Dev.to](https://dev.to/andy/rails-to-introduce-view-components-3ome)
- [ActionView::Components in Rails 6.1, Drifting Ruby](https://www.driftingruby.com/episodes/actionview-components-in-rails-6-1)
- [Demo repository, view-component-demo](https://github.com/joelhawksley/view-component-demo)

## Contributing

This project is intended to be a safe, welcoming space for collaboration. Contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. We recommend reading the [contributing guide](./CONTRIBUTING.md) as well.

## Contributors

ViewComponent is built by:

|<img src="https://avatars.githubusercontent.com/joelhawksley?s=256" alt="joelhawksley" width="128" />|<img src="https://avatars.githubusercontent.com/tenderlove?s=256" alt="tenderlove" width="128" />|<img src="https://avatars.githubusercontent.com/jonspalmer?s=256" alt="jonspalmer" width="128" />|<img src="https://avatars.githubusercontent.com/juanmanuelramallo?s=256" alt="juanmanuelramallo" width="128" />|<img src="https://avatars.githubusercontent.com/vinistock?s=256" alt="vinistock" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@joelhawksley|@tenderlove|@jonspalmer|@juanmanuelramallo|@vinistock|
|Denver|Seattle|Boston||Toronto|

|<img src="https://avatars.githubusercontent.com/metade?s=256" alt="metade" width="128" />|<img src="https://avatars.githubusercontent.com/asgerb?s=256" alt="asgerb" width="128" />|<img src="https://avatars.githubusercontent.com/xronos-i-am?s=256" alt="xronos-i-am" width="128" />|<img src="https://avatars.githubusercontent.com/dylnclrk?s=256" alt="dylnclrk" width="128" />|<img src="https://avatars.githubusercontent.com/kaspermeyer?s=256" alt="kaspermeyer" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@metade|@asgerb|@xronos-i-am|@dylnclrk|@kaspermeyer|
|London|Copenhagen|Russia, Kirov|Berkeley, CA|Denmark|

|<img src="https://avatars.githubusercontent.com/rdavid1099?s=256" alt="rdavid1099" width="128" />|<img src="https://avatars.githubusercontent.com/kylefox?s=256" alt="kylefox" width="128" />|<img src="https://avatars.githubusercontent.com/traels?s=256" alt="traels" width="128" />|<img src="https://avatars.githubusercontent.com/rainerborene?s=256" alt="rainerborene" width="128" />|<img src="https://avatars.githubusercontent.com/jcoyne?s=256" alt="jcoyne" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@rdavid1099|@kylefox|@traels|@rainerborene|@jcoyne|
|Los Angeles|Edmonton|Odense, Denmark|Brazil|Minneapolis|

|<img src="https://avatars.githubusercontent.com/elia?s=256" alt="elia" width="128" />|<img src="https://avatars.githubusercontent.com/cesariouy?s=256" alt="cesariouy" width="128" />|<img src="https://avatars.githubusercontent.com/spdawson?s=256" alt="spdawson" width="128" />|<img src="https://avatars.githubusercontent.com/rmacklin?s=256" alt="rmacklin" width="128" />|<img src="https://avatars.githubusercontent.com/michaelem?s=256" alt="michaelem" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@elia|@cesariouy|@spdawson|@rmacklin|@michaelem|
|Milan||United Kingdom||Berlin|

|<img src="https://avatars.githubusercontent.com/mellowfish?s=256" alt="mellowfish" width="128" />|<img src="https://avatars.githubusercontent.com/horacio?s=256" alt="horacio" width="128" />|<img src="https://avatars.githubusercontent.com/dukex?s=256" alt="dukex" width="128" />|<img src="https://avatars.githubusercontent.com/dark-panda?s=256" alt="dark-panda" width="128" />|<img src="https://avatars.githubusercontent.com/smashwilson?s=256" alt="smashwilson" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@mellowfish|@horacio|@dukex|@dark-panda|@smashwilson|
|Spring Hill, TN|Buenos Aires|São Paulo||Gambrills, MD|

|<img src="https://avatars.githubusercontent.com/blakewilliams?s=256" alt="blakewilliams" width="128" />|<img src="https://avatars.githubusercontent.com/seanpdoyle?s=256" alt="seanpdoyle" width="128" />|<img src="https://avatars.githubusercontent.com/tclem?s=256" alt="tclem" width="128" />|<img src="https://avatars.githubusercontent.com/nashby?s=256" alt="nashby" width="128" />|<img src="https://avatars.githubusercontent.com/jaredcwhite?s=256" alt="jaredcwhite" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@blakewilliams|@seanpdoyle|@tclem|@nashby|@jaredcwhite|
|Boston, MA|New York, NY|San Francisco, CA|Minsk|Portland, OR|

|<img src="https://avatars.githubusercontent.com/simonrand?s=256" alt="simonrand" width="128" />|<img src="https://avatars.githubusercontent.com/fugufish?s=256" alt="fugufish" width="128" />|<img src="https://avatars.githubusercontent.com/cover?s=256" alt="cover" width="128" />|<img src="https://avatars.githubusercontent.com/franks921?s=256" alt="franks921" width="128" />|<img src="https://avatars.githubusercontent.com/fsateler?s=256" alt="fsateler" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@simonrand|@fugufish|@cover|@franks921|@fsateler|
|Dublin, Ireland|Salt Lake City, Utah|Barcelona|South Africa|Chile|

|<img src="https://avatars.githubusercontent.com/maxbeizer?s=256" alt="maxbeizer" width="128" />|<img src="https://avatars.githubusercontent.com/franco?s=256" alt="franco" width="128" />|<img src="https://avatars.githubusercontent.com/tbroad-ramsey?s=256" alt="tbroad-ramsey" width="128" />|<img src="https://avatars.githubusercontent.com/jensljungblad?s=256" alt="jensljungblad" width="128" />|<img src="https://avatars.githubusercontent.com/bbugh?s=256" alt="bbugh" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@maxbeizer|@franco|@tbroad-ramsey|@jensljungblad|@bbugh|
|Nashville, TN|Switzerland|Spring Hill, TN|New York, NY|Austin, TX|

|<img src="https://avatars.githubusercontent.com/johannesengl?s=256" alt="johannesengl" width="128" />|<img src="https://avatars.githubusercontent.com/czj?s=256" alt="czj" width="128" />|<img src="https://avatars.githubusercontent.com/mrrooijen?s=256" alt="mrrooijen" width="128" />|<img src="https://avatars.githubusercontent.com/bradparker?s=256" alt="bradparker" width="128" />|<img src="https://avatars.githubusercontent.com/mattbrictson?s=256" alt="mattbrictson" width="128" />|
|:---:|:---:|:---:|:---:|:---:|
|@johannesengl|@czj|@mrrooijen|@bradparker|@mattbrictson|
|Berlin, Germany|Paris, France|The Netherlands|Brisbane, Australia|San Francisco|

|<img src="https://avatars.githubusercontent.com/mixergtz?s=256" alt="mixergtz" width="128" />|<img src="https://avatars.githubusercontent.com/jules2689?s=256" alt="jules2689" width="128" />|<img src="https://avatars.githubusercontent.com/g13ydson?s=256" alt="g13ydson" width="128" />|
|:---:|:---:|:---:|
|@mixergtz|@jules2689|@g13ydson|
|Medellin, Colombia|Toronto, Canada|João Pessoa, Brazil|

## License

ViewComponent is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
