---
layout: default
title: Compatibility
---

# Compatibility

ViewComponent is [supported natively](https://edgeguides.rubyonrails.org/layouts_and_rendering.html#rendering-objects) in Rails 6.1, and compatible with Rails 5.0+ via an included [monkey patch](https://github.com/github/view_component/blob/main/lib/view_component/render_monkey_patch.rb).

ViewComponent is tested for compatibility [with combinations of](https://github.com/github/view_component/blob/22e3d4ccce70d8f32c7375e5a5ccc3f70b22a703/.github/workflows/ruby_on_rails.yml#L10-L11) Ruby v2.5+ and Rails v5+. Ruby 2.4 is likely compatible, but is no longer tested.

## Ensuring the correct path

In some versions of Rails (tested in 5.0.7.2) you may see `no implicit conversion of nil into String` when attempting to generate a component or render a component. You will need to specify the following in your `config/application.rb` (or an initializer):

```
config.view_component.view_component_path = "app/components"
```

## Disabling the render monkey patch (Rails < 6.1)

In order to [avoid conflicts](https://github.com/github/view_component/issues/288) between ViewComponent and other gems that also monkey patch the `render` method, it is possible to configure ViewComponent to not include the render monkey patch:

`config.view_component.render_monkey_patch_enabled = false # defaults to true`

With the monkey patch disabled, use `render_component` (or  `render_component_to_string`) instead:

```erb
<%= render_component Component.new(message: "bar") %>
```

## Bridgetown (Static Site Generator)

[Bridgetown](https://www.bridgetownrb.com/) supports ViewComponent via an experimental shim provided by the [bridgetown-view-component gem](https://github.com/bridgetownrb/bridgetown-view-component). More information available [here](https://www.bridgetownrb.com/docs/components/ruby#need-compatibility-with-rails-try-viewcomponent-experimental).

## ActionText

Using `rich_text_area` from ActionText in a ViewComponent will result in this error:

```ruby
undefined method 'rich_text_area_tag'
```

This is due to ViewComponent not having access to the helpers it needs via ActionText. As a workaround, add the following to your component (or base component):

```ruby
delegate :rich_text_area_tag, to: :helpers
```
