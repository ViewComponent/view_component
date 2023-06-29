---
layout: default
title: Instrumentation
parent: How-to guide
---

# Instrumentation

Since 2.34.0
{: .label }

To enable ActiveSupport notifications, use the `instrumentation_enabled` option:

```ruby
# config/application.rb
# Enable ActiveSupport notifications for all ViewComponents
config.view_component.instrumentation_enabled = true
config.view_component.instrumentation_use_deprecated_name = false
```

Setting `instrumentation_use_deprecated_name` configures the event name used. If `false` the name `"render.view_component"` is used. If `true` (default) it will use the deprecated name `"!render.view_component"`.

You can then subscribe to the event:

```ruby
ActiveSupport::Notifications.subscribe("render.view_component") do |*args| # or !render.view_component
  event = ActiveSupport::Notifications::Event.new(*args)
  event.name    # => "render.view_component"
  event.payload # => { name: "MyComponent", identifier: "/Users/mona/project/app/components/my_component.rb" }
end
```

If you're using the non-deprecated key & have `config.server_timing = true` (default in development) set in Rails 7, you can see sum total timing information in your browser's developer-tools. Find the request on the Network tab and view it's "timing" sub-tab. On most browsers server results are shown beneath the client-side data. Look for the key `render.view_component`.
