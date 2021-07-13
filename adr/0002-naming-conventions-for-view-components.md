# 2. Naming conventions for ViewComponents

Date: 2021-07-13

## Status

Proposed

## Context

The `Component` suffix has been questioned a few times. Based on our ViewComponents at GitHub and those shared on the ViewComponent repo, it looks like the namespaces used are unique even when the `Component` suffix is removed. This is due to following the naming convention of views, which is to use the plural paths in the namespace. e.g. `users/index.html.erb` -> `Users::IndexComponent`/`Users::Index`.

## Decision

We will recommend that ViewComponents are named without the `-Component` suffix, for the User Interface elements they render, namespaced like views and controllers.

## Alternatives considered

We've used the `-Component` suffix for some time, so it is a viable alternative.

## Consequences

* **Pro**: Less boilerplate and better readability. No more `render Primer::LinkComponent.new`, we can now call `render Primer::Link.new`. Once you learn that components are objects that can be rendered, the `Component` suffix loses a lot of its value.
* **Pro**: Component names now completely align with the `views` naming conventions. This will make it easier to put components in the `views` directory if we go down that path.
* **Con**: It's no longer immediately clear that your class/object is a component. However, ViewComponents are often the only objects present in Rails view code, so the potential confusion is likely minimal.
* **Con**: It will take time to migrate existing code to the new convention.
