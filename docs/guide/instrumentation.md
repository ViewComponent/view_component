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
```

Then subscribe to the `!render.view_component` event:

```ruby
ActiveSupport::Notifications.subscribe("!render.view_component") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  event.name    # => "!render.view_component"
  event.payload # => { name: "MyComponent", identifier: "/Users/mona/project/app/components/my_component.rb" }
end
```
