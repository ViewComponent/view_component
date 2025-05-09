---
layout: default
title: History
nav_order: 10
---

# History

## Fall 2018: Prototype at GitHub

Inspired by the benefits he was seeing from using React at GitHub, [@joelhawksley](http://github.com/joelhawksley) built a prototype with [@tenderlove](https://github.com/tenderlove) of what it might look like to incorporate ideas from React into Rails.

They took inspiration from existing projects such as [trailblazer/cells](https://github.com/trailblazer/cells), [dry-view](https://github.com/dry-rb/dry-view), [komponent](https://github.com/komposable/komponent), and [arbre](https://github.com/activeadmin/arbre), designing an API meant to integrate as seamlessly as possible with Rails.

## Spring 2019: ActionView::Component

Once the prototype was tested in production, GitHub open sourced the project as ActionView::Component. [@joelhawksley](http://github.com/joelhawksley) presented the prototype at [RailsConf 2019](https://www.youtube.com/watch?v=y5Z5a6QdA-M).

## Summer 2019: Support for 3rd-party component frameworks in Rails

In [rails#36388](https://github.com/rails/rails/pull/36388), Rails added support for 3rd-party component frameworks via the `render_in` API.

## Spring 2020: ViewComponent v2.0.0

In `v2.0.0`, `ActionView::Component` was renamed to `ViewComponent`, delineating it as a project separate from Rails.

## November 2021: Polymorphic slots

@camertron introduced Polymorphic slots, documenting the maintainers' decision:

### Polymorphic slots

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

#### Decision

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

```erb
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

### Consequences

Things we tried and things we've learned.

#### Additional Complexity

The biggest consequence of this design is that it makes the slots API more complicated, something the view_component maintainers have been hesitant to do given the confusion we routinely see around slots.

#### Content Wrapping

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

#### Positional Type Argument vs Method Names

There has been some discussion around whether polymorphic slots should accept a positional `type` argument or instead define methods that correspond to each slot type as described in this ADR. We've decided to implement the method approach for several reasons:

1. Positional arguments aren't used anywhere else in the framework.
2. There is a preference amongst team members that the slot setter accept the exact same arguments as the slot itself, since doing so reduces the conceptual overhead of the slots API.

An argument was made that multiple setters for the same slot appear to be two different slots, but wasn't considered enough of a drawback to go the `type` argument route.

## April 2023: ViewComponent v3

ViewComponent `v3.0.0` ships, headlined by a breaking change to the slots API.

### Context

Currently, slots implement a single method for both getting and setting a slot. For example, given a slot named `header`:

```ruby
class MyComponent < ViewComponent::Base
  renders_one :header
end

c = MyComponent.new

c.header { "Hello world!" } # sets the slot
c.header # gets the slot
```

This API was built with the assumption that a slot will always be set by passing an argument and/or passing a block.

This assumption hasn't remained valid. Specifically, `with_content` breaks the assumption when passing static content to a slot:

```ruby
class MyComponent < ViewComponent::Base
  renders_one :header
end

c = MyComponent.new

# c.header returns nil because the getter path is being executed due to having
# no arguments and no block passed: https://github.com/ViewComponent/view_component/blob/18c27adc7ec715ca05d7ad0299efcbff9f03544b/lib/view_component/slotable_v2.rb#L70-L74
#
c.header.with_content("Hello world!") # undefined method `with_content' for nil:NilClass (NoMethodError)
```

The above example shows off the gap in the slots API via `with_content`, but it's likely that as the library continues to grow this gap will appear in other valid use-cases.

### Outcome

Split the slots API into a getter and setter. Keeping the slot name as the getter makes the most sense, but the setter can be renamed to `with_#{slot_name}`.

For example, the above would become:

```ruby
class MyComponent < ViewComponent::Base
  renders_one :header
end

c = MyComponent.new

# New API for setting slots
c.with_header { "hello world" }

# Now `with_content` is valid when defining slots
c.with_header.with_content("Hello world!")
```

### Alternatives Considered

We've spoken about a few alternatives:

* Making a special `NilSlot` class that responds to `with_content`.
  * Results in extra allocations
  * Can't treat the `NilSlot` as falsy. So `if header` would no longer work
    even though you would expect it to.
* Introducing an API for the `header.with_content("Hello world!")` pattern as explained above (like: `c.with_header_content("Hello world!")`):
  * The API gap still exists and requires a specific work around for
    `with_content`, leaving the gap for future API's.
  * This API doesn't allow arguments to be passed 1-to-1 like the current setter API.

### Side effects

The largest consequence of this change is that we'll need to deprecate the old setter usage (`header { "Hello world!"}`) in favor of the new setter API (`with_header { "Hello world!" }`).

We propose that we make at least one release with the new API and no deprecation
warning followed by another release that includes the deprecation warning. This
will give teams some time to migrate before running into deprecation warnings.
