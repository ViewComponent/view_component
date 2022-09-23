---
layout: default
title: 4. Separate Slot Getters and Setters
parent: Architectural decisions
nav_order: 4
---

# 4. Separate Slot Getters and Setters

Date: 2022/03/22

## Author

Blake Williams

## Status

Accepted

## Context

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
# no arguments and no block passed: https://github.com/viewcomponent/view_component/blob/main/lib/view_component/slotable_v2.rb#L70-L74
#
c.header.with_content("Hello world!") # undefined method `with_content' for nil:NilClass (NoMethodError)
```

The above example shows off the gap in the slots API via `with_content`, but it's likely that as the library continues to grow this gap will appear in other valid use-cases.

## Decision

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

## Alternatives Considered

We've spoken about a few alternatives:

* Making a special `NilSlot` class that responds to `with_content`.
  * Results in extra allocations
  * Can't treat the `NilSlot` as falsy. So `if header` would no longer work
    even though you would expect it to.
* Introducing an API for the `header.with_content("Hello world!")` pattern as explained above (like: `c.with_header_content("Hello world!")`):
  * The API gap still exists and requires a specific work around for
    `with_content`, leaving the gap for future API's.
  * This API doesn't allow arguments to be passed 1-to-1 like the current setter API.

## Consequences

The largest consequence of this change is that we'll need to deprecate the old setter usage (`header { "Hello world!"}`) in favor of the new setter API (`with_header { "Hello world!" }`).

I propose that we make at least one release with the new API and no deprecation
warning followed by another release that includes the deprecation warning. This
will give teams some time to migrate before running into deprecation warnings.
