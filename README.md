# ActionView::Component
`ActionView::Component` is a framework for building view components in Rails.

**Current Status**: Used in production at GitHub. Because of this, all changes will be thoroughly vetted, which could slow down the process of contributing. We will do our best to actively communicate status of pull requests with any contributors. If you have any substantial changes that you would like to make, it would be great to first [open an issue](http://github.com/github/actionview-component/issues/new) to discuss them with us.

## Roadmap

This gem is meant to serve as a precursor to upstreaming this functionality into Rails. It also serves to enable the usage of view components in older versions of Rails.

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
require "action_view/component"
```

## Guide

### What are components?

`ActionView::Component`s are Ruby classes that are used to render views. They take data as input and return output-safe HTML. Think of them as an evolution of the presenter/decorator/view model pattern, inspired by [React Components](https://reactjs.org/docs/react-component.html).

### Why components?

Traditional Rails views are hard to test efficiently, difficult to measure with code coverage tools, and often fall short of basic Ruby code standards.

Components allow us to test our views in isolation, use code coverage tools, and leverage Ruby to its full potential.

### When should I use components?

Components are most effective in cases where view code is reused or needs to be tested directly.

### Using components

Render components by passing an instance to `#render`:

```erb
<div class="container">
  <%= render Greeting.new(name: "Sarah") %>
</div>
```

### Building components

Components are subclasses of `ActionView::Component`. You may wish to create an `ApplicationComponent` that is a subclass of `ActionView::Component` and inherit from that instead.

#### Implementation

An `ActionView::Component` is implemented as a Ruby file alongside a template file (in any format supported by Rails) with the same base name:

`app/components/greeting.html.erb`
```erb
<h1>Hello, <%= name %></h1>
```

`app/components/greeting.rb`
```ruby
class Greeting < ActionView::Component
  def initialize(name:)
    @name = name
  end

  private

  attr_reader: :name
end
```

Generally, only the `initialize` method should be public.

#### Validations

`ActionView::Component` includes `ActiveModel::Validations`, so components can validate their attributes:

```ruby
class Greeting < ActionView::Component
  validates :name, length: { minimum: 2, maximum: 50 }

  def initialize(name:)
    @name = name
  end

  private

  attr_reader :name
end
```

#### Rendering content

Components can also render content passed as a block. To do so, simply return `content` inside the template:

`app/components/heading.rb`
```ruby
class Heading < ActionView::Component
end
```

`app/components/heading.html.erb`
```erb
<h1><%= content %></h1>
```

Under the hood, `ActionView::Component` captures the output of the passed block within the context of the original view and assigns it to `content`.

In use:

```ruby
<%= render Heading.new do %>Components are fun!<% end %>
```

Returns:

`<h1>Components are fun!</h1>`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/github/actionview-component. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. We recommend reading the [contributing guide](./CONTRIBUTING.md) as well.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
