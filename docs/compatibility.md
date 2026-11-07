---
layout: default
title: Compatibility
nav_order: 8
---

# Compatibility

## Ruby & Rails

ViewComponent supports all actively supported versions of [Ruby](https://endoflife.date/ruby) (>= 3.2) and [Ruby on Rails](https://endoflife.date/rails) (>= 7.1). Changes to the minimum Ruby and Rails versions supported will only be made in major releases.

## Template languages

ViewComponent is tested against ERB, Haml, and Slim, but it should support most Rails template handlers.

### Herb

Rails 8.2 can compile HTML+ERB templates through [Herb](https://github.com/marcoroth/herb) (`config.action_view.erb_implementation = :herb`), and ships `bin/rails herb:check` to find templates that don't compile with it before adopting it. Component templates, sidecar and inline, compile through Herb too, but aren't in the view paths `herb:check` reads.

`bin/rails view_component:herb:check` compiles the HTML+ERB templates of every component through Herb and reports the ones that fail. `bin/rails herb:check` reports component failures first, then checks the views, and fails if either does, so one command covers both.

## Bridgetown (Static Site Generator)

[Bridgetown](https://www.bridgetownrb.com/) supports ViewComponent via an experimental shim provided by the [bridgetown-view-component gem](https://github.com/bridgetownrb/bridgetown-view-component). More information available [here](https://www.bridgetownrb.com/docs/components/ruby#need-compatibility-with-rails-try-viewcomponent-experimental).

## ActionText

Using `rich_textarea` from ActionText in a ViewComponent will result in this error:

`undefined method "rich_textarea_tag"`

This is due to ViewComponent not having access to the helpers it needs via ActionText. As a workaround, add the following to your component (or base component):

```ruby
delegate :rich_textarea_tag, to: :helpers
```
