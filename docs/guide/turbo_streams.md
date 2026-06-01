---
layout: default
title: Turbo Streams
parent: How-to guide
---

# Turbo Streams

ViewComponents can be used with [Turbo Streams](https://turbo.hotwired.dev/handbook/streams) to broadcast updates over WebSockets.

## Rendering in controllers

In a controller action, render a component inside a Turbo Stream response using `render_to_string` or `view_context.render`:

```ruby
class MessagesController < ApplicationController
  def create
    @message = Message.create!(message_params)

    Turbo::StreamsChannel.broadcast_append_to(
      "messages",
      target: "messages",
      html: render_to_string(MessageComponent.new(message: @message))
    )
  end
end
```

## Broadcasting later with ActiveJob

To broadcast asynchronously via ActiveJob (using `broadcast_action_later_to`), components must be serializable so they can be passed to the background job.

Include `ViewComponent::Serializable` in the component and use `.render_later` instead of `.new` when broadcasting:

```ruby
class MessageComponent < ViewComponent::Base
  include ViewComponent::Serializable

  def initialize(message:)
    @message = message
  end
end

class Message < ApplicationRecord
  after_create_commit :broadcast_append

  private

  def broadcast_append
    Turbo::StreamsChannel.broadcast_action_later_to(
      "messages",
      action: :append,
      target: "messages",
      renderable: MessageComponent.render_later(message: self),
      layout: false
    )
  end
end
```

The component is serialized when the job is enqueued and deserialized when the job runs. The job renders the component via `ApplicationController.render` and broadcasts the resulting HTML over ActionCable.

### Slots

Slot calls made on the proxy are captured and replayed at render time. Slots must use a component class — passthrough slots that accept blocks are not supported because blocks cannot be serialized.

```ruby
class CardComponent < ViewComponent::Base
  class BodyComponent < ViewComponent::Base
    def initialize(text:)
      @text = text
    end
  end

  renders_many :bodies, BodyComponent
end

proxy = CardComponent.render_later(title: "Updates")
proxy.with_body(text: "First item")
proxy.with_body(text: "Second item")

Turbo::StreamsChannel.broadcast_action_later_to("cards", renderable: proxy, ...)
```

Passing a block to a slot call raises `ViewComponent::Serializable::UnserializableError` immediately.

### How it works

- `.render_later(*args, **kwargs)` returns a `ViewComponent::Serializable::Proxy` that stores the component class and initialization arguments without instantiating the component.
- `ViewComponent::ActiveJobSerializer` handles converting the proxy to and from a JSON-safe format. It is automatically registered when ActiveJob is loaded.
- ActiveRecord objects passed as arguments are serialized via GlobalID, just like any other ActiveJob argument.

### Limitations

- Blocks passed to `render_in` or to slot calls raise `ViewComponent::Serializable::UnserializableError`. Use component-based slots instead.
- The component class must be `safe_constantize`-able at deserialization time (i.e., it must be autoloadable).
