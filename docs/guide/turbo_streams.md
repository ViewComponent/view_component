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

### Setup

Include `ViewComponent::Serializable` in the component and use `.serializable` instead of `.new` when broadcasting:

```ruby
class MessageComponent < ViewComponent::Base
  include ViewComponent::Serializable

  def initialize(message:)
    @message = message
  end

  erb_template <<~ERB
    <div id="<%= dom_id(@message) %>">
      <%= @message.body %>
    </div>
  ERB
end
```

### Broadcasting

Use `.serializable` to create a component instance that can be serialized by ActiveJob:

```ruby
class Message < ApplicationRecord
  after_create_commit :broadcast_append

  private

  def broadcast_append
    Turbo::StreamsChannel.broadcast_action_later_to(
      "messages",
      action: :append,
      target: "messages",
      renderable: MessageComponent.serializable(message: self),
      layout: false
    )
  end
end
```

The component is serialized when the job is enqueued and deserialized when the job runs. The job renders the component via `ApplicationController.render` and broadcasts the resulting HTML over ActionCable.

### How it works

- `.serializable(**kwargs)` creates a normal component instance and stores the keyword arguments for later serialization.
- `ViewComponent::SerializableSerializer` (an ActiveJob serializer) handles converting the component to and from a JSON-safe format. It's automatically registered when ActiveJob is loaded.
- ActiveRecord objects passed as keyword arguments are serialized via GlobalID, just like any other ActiveJob argument.

### Limitations

- Only keyword arguments passed to `.serializable` are serialized. Slots, `with_content`, and other state set after initialization are not included.
- Components must be instantiated with `.serializable` instead of `.new` for serialization to work. Instances created with `.new` are not serializable.
- The component class must be `safe_constantize`-able at deserialization time (i.e., it must be autoloadable).
