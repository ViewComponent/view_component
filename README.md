# ActionView::Component
`ActionView::Component` is a framework for building view components in Rails.

**Current Status**: Used in production at GitHub. Because of this, all changes will be thoroughly vetted, which could slow down the process of contributing. We will do our best to actively communicate status of pull requests with any contributors. If you have any substantial changes that you would like to make, it would be great to first [open an issue](http://github.com/github/actionview-component/issues/new) to discuss them with us.

## Roadmap

This gem is meant to serve as a precursor to upstreaming this functionality into Rails. It also serves to enable the usage of view components in older versions of Rails.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'actionview-component'
```

And then execute:
```bash
$ bundle
```

In `config/application.rb`, add:

```bash
require "action_view/component"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/github/actionview-component. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. We recommend reading the [contributing guide](./CONTRIBUTING.md) as well.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
