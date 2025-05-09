---
layout: default
title: Compatibility
nav_order: 8
---

# Compatibility

## Ruby & Rails

ViewComponent supports all actively supported versions of Ruby (3.0+) and Ruby on Rails (6.1+) and is tested against a combination of these versions of Ruby on Rails.

While EOL (end-of-life) versions of Ruby and Ruby on Rails may still work with ViewComponent, they're not actively supported and no longer tested. We will still accept patches on a case-by-case basis to support older Ruby & Rails versions based on the complexity and maintenance burden. Please open an issue before submitting such a Pull Request.

## Template languages

ViewComponent is tested against ERB, Haml, and Slim, but it should support most Rails template handlers.

## Disabling the render monkey patch (Rails < 6.1)

Since 2.13.0
{: .label }

To [avoid conflicts](https://github.com/viewcomponent/view_component/issues/288) between ViewComponent and other gems that also monkey patch the `render` method, it's possible to configure ViewComponent to not include the render monkey patch:

`config.view_component.render_monkey_patch_enabled = false # defaults to true`

With the monkey patch disabled, use `render_component` (or  `render_component_to_string`) instead:

```erb
<%= render_component Component.new(message: "bar") %>
```

## Bridgetown (Static Site Generator)

[Bridgetown](https://www.bridgetownrb.com/) supports ViewComponent via an experimental shim provided by the [bridgetown-view-component gem](https://github.com/bridgetownrb/bridgetown-view-component). More information available [here](https://www.bridgetownrb.com/docs/components/ruby#need-compatibility-with-rails-try-viewcomponent-experimental).

## ActionText

Using `rich_textarea` from ActionText in a ViewComponent will result in this error:

`undefined method "rich_textarea_tag"`

This is due to ViewComponent not having access to the helpers it needs via ActionText. As a workaround, add the following to your component (or base component):

```ruby
delegate :rich_textarea_tag, to: :helpers
```
