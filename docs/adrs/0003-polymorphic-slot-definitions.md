---
layout: default
title: 3. Polymorphic slots
parent: Architectural decisions
nav_order: 3
---

# 3. Polymorphic slots

Date: 2021/09/29

## Author

Cameron Dutro

## Status

Accepted

## Context

Components can currently define slots in two ways:

1. by specifying a component class (or class name string)
1. by providing a proc that either returns HTML or a component instance.

With these options in mind, imagine a scenario in which a component supports rendering one of two possible sub-components in a slot. In other words, the user of the component may only fill the slot with one of two (or more) possible kinds of sub-component.

To illustrate, let's consider a list component with an `items` slot. Each constituent `Item` has either an icon or an avatar on the right-hand side followed by some text.

When implementing the `Item` component, we've several options for determining whether we should render an icon or an avatar:

1. **Two slots w/error**: define two different slots for the icon and avatar, and raise an error in the `before_render` lifecycle method if both are defined.
1. **Two slots w/default**: define two different slots for the icon and avatar, but favor one or the other if both are provided.
1. **Examine kwargs**: define a single slot and determine which sub-component to render by examining the contents of `**kwargs`.
1. **Unrestricted content**: define a single slot that renders any content provided by the caller. The component has to "trust" that the caller will pass in only an icon or avatar.

While these options are reasonably acceptable, there are problems with each:

1. **Two slots w/error**: using `before_render` for slot validation feels like an anti-pattern. To make the interface clear, defining both slots shouldn't be possible.
1. **Two slots w/default**: same issues as #1, but worse because it "swallows" the error. This behavior probably won't be obvious to the component's users.
1. **Examine kwargs**: this approach is brittle because the kwargs accepted by constituent components can change over time, which may require changes to the `Item` component as well.
1. **Unrestricted content**: not ideal because the content can literally be anything and relies on the caller following the "rules."

It's my opinion that we need the ability to choose between multiple types within a single slot.

## Decision

We will introduce a third type of slot called a polymorphic slot. The `renders_one` and `renders_many` methods will accept a mapping of the various acceptable sub-components. Each of these sub-components will themselves be slot definitions, meaning they can be defined as either a class/string or proc.

Here's how the `Item` sub-component of the list example above would be implemented using polymorphic slots:

```ruby
class Item < ViewComponent::Base
  renders_one :leading_visual, types: {
    icon: IconComponent, avatar: AvatarComponent
  }
end
```

The `Item` component can then be used like this:

```html+erb
<%= render List.new do |component| %>
  <% component.with_item do |item| %>
    <% item.leading_visual_avatar(src: "assets/user/1234.png") %>
    Profile
  <% end %>
  <% component.with_item do |item| %>
    <% item.leading_visual_icon(icon: :gear) %>
    Settings
  <% end %>
<% end %>
```

Notice that the type of leading visual, either `:icon` or `:avatar`, is appended to the slot name, `leading_visual`, and corresponds to the items in the `types` hash passed to `renders_one`.

Finally, the polymorphic slot behavior will be implemented as a `module` so the behavior is opt-in until we're confident that it's a good addition to ViewComponent.

## Consequences

Things we tried and things we've learned.

### Additional Complexity

The biggest consequence of this design is that it makes the slots API more complicated, something the view_component maintainers have been hesitant to do given the confusion we routinely see around slots.

### Content Wrapping

One concern of the proposed approach is that it offers no immediately obvious way to wrap the contents of a slot. Here's an example of how a slot might be wrapped:

```ruby
renders_many :items do |*args, **kwargs|
  content_tag :td, class: kwargs[:table_row_classes] do
    Row.new(*args, **kwargs)
  end
end
```

In such cases, there are several viable workarounds:

1. Add the wrapping HTML to the template.
1. Provide a lambda for each polymorphic type that adds the wrapping HTML. There is the potential for code duplication here, which could be mitigated by calling a class or helper method.
1. Manually implement a polymorphic slot using a positional `type` argument and `case` statement, as shown in the example below. This effectively replicates the behavior described in this proposal.

```ruby
renders_many :items do |type, *args, **kwargs|
  content_tag :td, class: kwargs[:table_row_classes] do
    case type
    when :foo
      RowFoo.new(*args, **kwargs)
    when :bar
      RowBar.new(*args, **kwargs)
    end
  end
end
```

### Positional Type Argument vs Method Names

There has been some discussion around whether polymorphic slots should accept a positional `type` argument or instead define methods that correspond to each slot type as described in this ADR. We've decided to implement the method approach for several reasons:

1. Positional arguments aren't used anywhere else in the framework.
2. There is a preference amongst team members that the slot setter accept the exact same arguments as the slot itself, since doing so reduces the conceptual overhead of the slots API.

An argument was made that multiple setters for the same slot appear to be two different slots, but wasn't considered enough of a drawback to go the `type` argument route.
