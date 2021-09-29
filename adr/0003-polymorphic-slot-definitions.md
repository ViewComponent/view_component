# 3. Polymorphic Slot Definitions

Date: 2021-09-29

## Status

Proposed

## Context

Component authors can currently define slots in two ways:

1. by specifying a component class (or class name string), or
1. by providing a proc (i.e. lambda) that either returns HTML or a component instance.

With these options in mind, imagine a scenario in which a component supports rendering one of two possible sub-components in a slot. In other words, the user of the component may only fill the slot with one of two (or more) possible kinds of sub-component.

To illustrate, let's consider a list component with an `items` slot. Each constituent `Item` has either an icon or an avatar on the right-hand side followed by some text.

In implementing the `Item` component, we have several options for determining whether we should render an icon or an avatar. We can

1. **Two slots w/error**: define two different slots for the icon and avatar, and raise an error in the `before_render` lifecycle method if both are defined.
1. **Two slots w/default**: define two different slots for the icon and avatar, but favor one or the other if both are provided.
1. **Examine kwargs**: define a single slot and determine which sub-component to render by examining the contents of `**kwargs`.
1. **Unrestricted content**: define a single slot that renders any content provided by the caller. The component has to "trust" that the caller will pass in only an icon or avatar.

All these options are perfectly acceptable and will probably work just fine. However, there are problems with each.

1. **Two slots w/error**: using `before_render` for slot validation feels like an anti-pattern. To make the interface clear, defining both slots shouldn't be possible.
1. **Two slots w/default**: same issues as #1, but worse because it silently "swallows" the error. This behavior probably won't be obvious to the component's users.
1. **Examine kwargs**: this approach is brittle because the kwargs accepted by constituent components can change over time, potentially requiring changes to the `Item` component as well.
1. **Unrestricted content**: not ideal because the content can literally be anything and relies on the caller following the "rules."

It is my opinion that we need the ability to choose between multiple types within a single slot.

## Decision

We will introduce a third type of slot called a polymorphic slot. The `renders_one` and `renders_many` methods will accept a hash as a second argument that will contain a mapping of the various acceptable sub-components. Each of these sub-components will themselves be slot definitions, meaning they can be defined as either a class/string or proc.

Here's how the `Item` sub-component of the list example above would be implemented using polymorphic slots:

```ruby
class Item < ViewComponent::Base
  renders_one :leading_visual, icon: IconComponent, avatar: AvatarComponent
end
```

The `Item` component can then be used like this:

```html+erb
<%= render List.new do |component| %>
  <% component.item do |item| %>
    <% item.leading_visual(:avatar, src: "assets/user/1234.png") %>
    Profile
  <% end %>
  <% component.item do |item| %>
    <% item.leading_visual(:icon, icon: :gear) %>
    Settings
  <% end %>
<% end %>
```

Notice that the type of leading visual, either `:icon` or `:avatar`, is passed as the first argument to `leading_visual` and corresponds to the items in the hash passed to `renders_one`.

## Consequences

The biggest consequence of this design is that it makes the slots API more complicated, something the view_component maintainers have been hesitant to do given the confusion we routinely see around slots.
