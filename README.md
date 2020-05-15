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

#### Standards

Views often fail basic Ruby code quality standards: long methods, deep conditional nesting, and mystery guests abound.

ViewComponents are Ruby objects, making it easy to follow (and enforce) code quality standards.

### Building components

#### Conventions

Components are subclasses of `ViewComponent::Base` and live in `app/components`. It's common practice to create and inherit from an `ApplicationComponent` that is a subclass of `ViewComponent::Base`.

Component names end in -`Component`.

Component module names are plural, as for controllers and jobs: `Users::AvatarComponent`

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

### Conditional Rendering

Components can implement a `#render?` method to be called after initialization to determine if the component should render.

Traditionally, the logic for whether to render a view could go in either the component template:

`app/components/confirm_email_component.html.erb`
```
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
```
<div class="banner">
  Please confirm your email address.
</div>
```

`app/views/_banners.html.erb`
```erb
<%= render(ConfirmEmailComponent.new(user: current_user)) %>
```

_To assert that a component has not been rendered, use `refute_component_rendered` from `ViewComponent::TestHelpers`._

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

### Testing

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

Preview classes live in `test/components/previews`, which can be configured using the `preview_path` option:

`config/application.rb`
```ruby
config.view_component.preview_path = "#{Rails.root}/lib/component_previews"
```

Previews are served from <http://localhost:3000/rails/view_components> by default. To use a different endpoint, set the `preview_route` option:

`config/application.rb`
```ruby
config.view_component.preview_route = "/previews"
```

This example will make the previews available from <http://localhost:3000/previews>.

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
config.view_component.preview_path = "#{Rails.root}/spec/components/previews"
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
- [ViewComponent at GitHub with Joel Hawksley](https://the-ruby-blend.fireside.fm/9)
- [Components, HAML vs ERB, and Design Systems](https://the-ruby-blend.fireside.fm/4)
- [Choosing the Right Tech Stack with Dave Paola](https://5by5.tv/rubyonrails/307)
- [Rethinking the View Layer with Components, RailsConf 2019](https://www.youtube.com/watch?v=y5Z5a6QdA-M)
- [Introducing ActionView::Component with Joel Hawksley, Ruby on Rails Podcast](http://5by5.tv/rubyonrails/276)
- [Rails to Introduce View Components, Dev.to](https://dev.to/andy/rails-to-introduce-view-components-3ome)
- [ActionView::Components in Rails 6.1, Drifting Ruby](https://www.driftingruby.com/episodes/actionview-components-in-rails-6-1)
- [Demo repository, view-component-demo](https://github.com/joelhawksley/view-component-demo)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/github/view_component. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. We recommend reading the [contributing guide](./CONTRIBUTING.md) as well.

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

|<img src="https://avatars.githubusercontent.com/simonrand?s=256" alt="simonrand" width="128" />|<img src="https://avatars.githubusercontent.com/fugufish?s=256" alt="fugufish" width="128" />|<img src="https://avatars.githubusercontent.com/cover?s=256" alt="cover" width="128" />|<img src="https://avatars.githubusercontent.com/franks921?s=256" alt="franks921" width="128" />|
|:---:|:---:|:---:|:---:|
|@simonrand|@fugufish|@cover|@franks921|
|Dublin, Ireland|Salt Lake City, Utah|Barcelona|South Africa|

## License

ViewComponent is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
