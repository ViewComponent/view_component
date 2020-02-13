# ActionView::Component
`ActionView::Component` is a framework for building view components in Rails.

**Current Status**: Used in production at GitHub. Because of this, all changes will be thoroughly vetted, which could slow down the process of contributing. We will do our best to actively communicate status of pull requests with any contributors. If you have any substantial changes that you would like to make, it would be great to first [open an issue](http://github.com/github/actionview-component/issues/new) to discuss them with us.

## Roadmap

This gem is meant to serve as a precursor to upstreaming the `ActionView::Component` class into Rails. It also serves to enable the usage of `ActionView::Component` in older versions of Rails.

Preliminary support for rendering components was merged into Rails `6.1.0.alpha` in https://github.com/rails/rails/pull/36388. Assuming `ActionView::Component` makes it into Rails, this gem will then exist to serve as a backport.

## Design philosophy

As the goal of this gem is to be upstreamed into Rails, it is designed to integrate as seamlessly as possible, with the [least surprise](https://www.artima.com/intv/ruby4.html).

## Compatibility

`actionview-component` is tested for compatibility with combinations of Ruby `2.4`/`2.5`/`2.6` and Rails `5.0.0`/`5.2.3`/`6.0.0`/`6.1.0.alpha`.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "actionview-component"
```

And then execute:
```bash
$ bundle
```

In `config/application.rb`, add:

```bash
require "action_view/component/railtie"
```

## Guide

### What are components?

`ActionView::Component`s are Ruby classes that are used to render views. They take data as input and return output-safe HTML. Think of them as an evolution of the presenter/decorator/view model pattern, inspired by [React Components](https://reactjs.org/docs/react-component.html).

### Why components?

In working on views in the Rails monolith at GitHub (which has over 3700 templates), we have run into several key pain points:

#### Testing

Currently, Rails encourages testing views via integration or system tests. This discourages us from testing our views thoroughly, due to the costly overhead of exercising the routing/controller layer, instead of just the view. It also often leads to partials being tested for each view they are included in, cheapening the benefit of DRYing up our views.

#### Code Coverage

Many common Ruby code coverage tools cannot properly handle coverage of views, making it difficult to audit how thorough our tests are and leading to gaps in our test suite.

#### Data Flow

Unlike a method declaration on an object, views do not declare the values they are expected to receive, making it hard to figure out what context is necessary to render them. This often leads to subtle bugs when we reuse a view across different contexts.

#### Standards

Our views often fail even the most basic standards of code quality we expect out of our Ruby classes: long methods, deep conditional nesting, and mystery guests abound.

### What are the benefits?

#### Testing

`ActionView::Component` allows views to be unit-tested. In the main GitHub codebase, our unit tests run in around 25ms/test, vs. ~6s/test for integration tests.

#### Code Coverage

`ActionView::Component` is at least partially compatible with code coverage tools. We’ve seen some success with SimpleCov.

#### Data flow

By clearly defining the context necessary to render a component, we’ve found them to be easier to reuse than partials.

#### Performance

In early benchmarks, we’ve seen performance improvements over the existing rendering pipeline. For a test page with nested renders 10 levels deep, we’re seeing around a 5x increase in speed over partials:

```
Comparison:
           component:     6515.4 i/s
             partial:     1251.2 i/s - 5.21x  slower
```

_Rails 6.1.0.alpha, [joelhawksley/actionview-component-demo](https://github.com/joelhawksley/actionview-component-demo), /benchmark route, via `RAILS_ENV=production rails s`, measured with [evanphx/benchmark-ips](https://github.com/evanphx/benchmark-ips)_

### When should I use components?

Components are most effective in cases where view code is reused or needs to be tested directly.

### Building components

Components are subclasses of `ActionView::Component::Base` and live in `app/components`. You may wish to create an `ApplicationComponent` that is a subclass of `ActionView::Component::Base` and inherit from that instead.

Component class names end in -`Component`.

Component module names are plural, as they are for controllers. (`Users::AvatarComponent`)

Components support ActiveModel validations. Components are validated after initialization, but before rendering.

Content passed to an `ActionView::Component` as a block is captured and assigned to the `content` accessor.

#### Quick start

Use the component generator to create a new `ActionView::Component`.

The generator accepts the component name and the list of accepted properties as arguments:

```bash
bin/rails generate component Example title content
      invoke  test_unit
      create  test/components/example_component_test.rb
      create  app/components/example_component.rb
      create  app/components/example_component.html.erb
```

#### Implementation

An `ActionView::Component` is a Ruby file and corresponding template file (in any format supported by Rails) with the same base name:

`app/components/test_component.rb`:
```ruby
class TestComponent < ActionView::Component::Base
  validates :content, :title, presence: true

  def initialize(title:)
    @title = title
  end

  private

  attr_reader :title
end
```

`app/components/test_component.html.erb`:
```erb
<span title="<%= title %>"><%= content %></span>
```

We can render it in a view as:

```erb
<%= render(TestComponent, title: "my title") do %>
  Hello, World!
<% end %>
```

Which returns:

```html
<span title="my title">Hello, World!</span>
```

##### Supported `render` syntaxes

Components can be rendered via:

`render(TestComponent, foo: :bar)`

`render(component: TestComponent, locals: { foo: :bar })`

**Rendering components through models**

Passing model instances will cause `render` to look for its respective component class.

The component is instantiated with the rendered model instance.

Example for a `Post` model:

`render(@post)`

```ruby
class PostComponent < ActionView::Component::Base
  def initialize(post)
    @post = post
  end
end
```

The following syntax has been deprecated and will be removed in v2.0.0:

`render(TestComponent.new(foo: :bar))`

#### Error case

If the component is rendered with a blank title:

```erb
<%= render(TestComponent, title: "") do %>
  Hello, World!
<% end %>
```

An error will be raised:

`ActiveModel::ValidationError: Validation failed: Title can't be blank`

#### Content Areas

A component can declare additional content areas to be rendered in the component. For example:

`app/components/modal_component.rb`:
```ruby
class ModalComponent < ActionView::Component::Base
  validates :user, :header, :body, presence: true

  with_content_areas :header, :body

  def initialize(user:)
    @user = user
  end

  attr_reader :user
end
```

`app/components/modal_component.html.erb`:
```erb
<div class="modal">
  <div class="header"><%= header %></div>
  <div class="body"><%= body %></div>
</div>
```

We can render it in a view as:

```erb
<%= render(ModalComponent, user: {name: 'Jane'}) do |component| %>
  <% component.with(:header) do %>
      Hello <%= component.user[:name] %>
    <% end %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

Which returns:

```html
<div class="modal">
  <div class="header">Hello Jane</div>
  <div class="body"><p>Have a great day.</p></div>
</div>
```

Content for content areas can be passed as arguments to the render method or as named blocks passed to the `with` method.
This allows a few different combinations of ways to render the component:

##### Required render argument optionally overridden or wrapped by a named block

`app/components/modal_component.rb`:
```ruby
class ModalComponent < ActionView::Component::Base
  validates :header, :body, presence: true

  with_content_areas :header, :body

  def initialize(header:)
    @header = header
  end
end
```

```erb
<%= render(ModalComponent, header: "Hi!") do |component| %>
  <% component.with(:header) do %>
    <span class="help_icon"><%= component.header %></span>
  <% end %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

##### Required argument passed by render argument or by named block

`app/components/modal_component.rb`:
```ruby
class ModalComponent < ActionView::Component::Base
  validates :header, :body, presence: true

  with_content_areas :header, :body

  def initialize(header: nil)
    @header = header
  end
end
```

`app/views/render_arg.html.erb`:
```erb
<%= render(ModalComponent, header: "Hi!") do |component| %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

`app/views/with_block.html.erb`:
```erb
<%= render(ModalComponent) do |component| %>
  <% component.with(:header) do %>
    <span class="help_icon">Hello</span>
  <% end %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

##### Optional argument passed by render argument, by named block, or neither

`app/components/modal_component.rb`:
```ruby
class ModalComponent < ActionView::Component::Base
  validates :body, presence: true

  with_content_areas :header, :body

  def initialize(header: nil)
    @header = header
  end
end
```

`app/components/modal_component.html.erb`:
```erb
<div class="modal">
  <% if @header %>
    <div class="header"><%= header %></div>
  <% end %>
  <div class="body"><%= body %></div>
</div>
```

`app/views/render_arg.html.erb`:
```erb
<%= render(ModalComponent, header: "Hi!") do |component| %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

`app/views/with_block.html.erb`:
```erb
<%= render(ModalComponent) do |component| %>
  <% component.with(:header) do %>
    <span class="help_icon">Hello</span>
  <% end %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

`app/views/no_header.html.erb`:
```erb
<%= render(ModalComponent) do |component| %>
  <% component.with(:body) do %>
    <p>Have a great day.</p>
  <% end %>
<% end %>
```

### Conditional Rendering

Components can implement a `#render?` method which indicates if they should be rendered, or not at all.

For example, you might have a component that displays a "Please confirm your email address" banner to users who haven't confirmed their email address. The logic for rendering the banner would need to go in either the component template:

```
<!-- app/components/confirm_email_component.html.erb -->
<% if @user.requires_confirmation? %>
  <div class="alert">
    Please confirm your email address.
  </div>
<% end %>
```

or the view that renders the component:

```erb
<!-- app/views/_banners.html.erb -->
<% if current_user.requires_confirmation? %>
  <%= render(ConfirmEmailComponent, user: current_user) %>
<% end %>
```

The `#render?` hook allows you to move this logic into the Ruby class, leaving your views more readable and declarative in style:

```ruby
# app/components/confirm_email_component.rb
class ConfirmEmailComponent < ActionView::Component::Base
  def initialize(user:)
    @user = user
  end

  def render?
    @user.requires_confirmation?
  end

  attr_reader :user
end
```

```
<!-- app/components/confirm_email_component.html.erb -->
<div class="banner">
  Please confirm your email address.
</div>
```

```erb
<!-- app/views/_banners.html.erb -->
<%= render(ConfirmEmailComponent, user: current_user) %>
```

### Testing

Components are unit tested directly. The `render_inline` test helper wraps the result in `Nokogiri.HTML`, allowing us to test the component above as:

```ruby
require "action_view/component/test_case"

class MyComponentTest < ActionView::Component::TestCase
  test "render component" do
    assert_equal(
      %(<span title="my title">Hello, World!</span>),
      render_inline(TestComponent, title: "my title") { "Hello, World!" }.to_html
    )
  end
end
```

In general, we’ve found it makes the most sense to test components based on their rendered HTML.

#### Action Pack Variants

To test a specific variant you can wrap your test with the `with_variant` helper method as:

```ruby
test "render component for tablet" do
  with_variant :tablet do
    assert_equal(
      %(<span title="my title">Hello, tablets!</span>),
      render_inline(TestComponent, title: "my title") { "Hello, tablets!" }.css("span").to_html
    )
  end
end
```

### Previewing Components
`ActionView::Component::Preview` provides a way to see how components look by visiting a special URL that renders them.
In the previous example, the preview class for `TestComponent` would be called `TestComponentPreview` and located in `test/components/previews/test_component_preview.rb`.
To see the preview of the component with a given title, implement a method that renders the component.
You can define as many examples as you want:

```ruby
# test/components/previews/test_component_preview.rb

class TestComponentPreview < ActionView::Component::Preview
  def with_default_title
    render(TestComponent, title: "Test component default")
  end

  def with_long_title
    render(TestComponent, title: "This is a really long title to see how the component renders this")
  end
end
```

The previews will be available in <http://localhost:3000/rails/components/test_component/with_default_title>
and <http://localhost:3000/rails/components/test_component/with_long_title>.

Previews use the application layout by default, but you can also use other layouts from your app:

```ruby
# test/components/previews/test_component_preview.rb

class TestComponentPreview < ActionView::Component::Preview
  layout "admin"

  ...
end
```

By default, the preview classes live in `test/components/previews`.
This can be configured using the `preview_path` option.
For example, if you want to use `lib/component_previews`, set the following in `config/application.rb`:

```ruby
config.action_view_component.preview_path = "#{Rails.root}/lib/component_previews"
```

#### Configuring TestController

By default components tests and previews expect your Rails project to contain an `ApplicationController` class from which Controller classes inherit.
This can be configured using the `test_controller` option.
For example, if your controllers inherit from `BaseController`, set the following in `config/application.rb`:

```ruby
config.action_view_component.test_controller = "BaseController"
```

### Setting up RSpec

If you're using RSpec, you can configure component specs to have access to test helpers. Add the following to
`spec/rails_helper.rb`:

```ruby
require "action_view/component/test_helpers"

RSpec.configure do |config|
    # ...

    # Ensure that the test helpers are available in component specs
    config.include ActionView::Component::TestHelpers, type: :component
end
```

Specs created by the generator should now have access to test helpers like `render_inline`.

To use component previews, set the following in `config/application.rb`:

```ruby
config.action_view_component.preview_path = "#{Rails.root}/spec/components/previews"
```

### Initializer requirement

In Ruby 2.6.x and below, ActionView::Component requires the presence of an `initialize` method in each component. 
However, `initialize` is no longer required for projects using 2.7.x and above.

## Frequently Asked Questions

### Can I use other templating languages besides ERB?

Yes. This gem is tested against ERB, Haml, and Slim, but it should support most Rails template handlers.

### What happened to inline templates?

Inline templates have been removed (for now) due to concerns raised by [@soutaro](https://github.com/soutaro) regarding compatibility with the type systems being developed for Ruby 3.

### Isn't this just like X library?

`ActionView::Component` is far from a novel idea! Popular implementations of view components in Ruby include, but are not limited to:

- [trailblazer/cells](https://github.com/trailblazer/cells)
- [dry-rb/dry-view](https://github.com/dry-rb/dry-view)
- [komposable/komponent](https://github.com/komposable/komponent)
- [activeadmin/arbre](https://github.com/activeadmin/arbre)

## Resources

- [Rethinking the View Layer with Components, RailsConf 2019](https://www.youtube.com/watch?v=y5Z5a6QdA-M)
- [Introducing ActionView::Component with Joel Hawksley, Ruby on Rails Podcast](http://5by5.tv/rubyonrails/276)
- [Rails to Introduce View Components, Dev.to](https://dev.to/andy/rails-to-introduce-view-components-3ome)
- [ActionView::Components in Rails 6.1, Drifting Ruby](https://www.driftingruby.com/episodes/actionview-components-in-rails-6-1)
- [Demo repository, actionview-component-demo](https://github.com/joelhawksley/actionview-component-demo)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/github/actionview-component. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. We recommend reading the [contributing guide](./CONTRIBUTING.md) as well.

## Contributors

`actionview-component` is built by:

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

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
