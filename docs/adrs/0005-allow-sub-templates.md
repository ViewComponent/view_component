# 1. Sub-templates

## Author

Felipe Sateler

## Status

Accepted

## Context

As views become larger (such as an entire page), it becomes useful to be able to extract sections of the view to a different file. In ActionView this is done with partials, but ViewComponent lacks a similar mechanism.

The interface of ActionView partials can't be introspected. Because data may be passed into the partial via ivars or locals it is impossible to know which without reading the file. Partials are also globally accessible, making it difficult to determine if a given partial is in use or not.

## Considered Options

* Introduce sub-templates to components
* Do nothing

### Sub-templates

Introduce support for multiple ERB templates within a single component and make it possible to invoke them from the main view, explicitly listing the arguments the additional templates accept. This allows a single method to be compiled and invoked directly.

**Pros:**

* Better performance due to lack of GC pressure and object creation
* Reduces the number of components needed to express a more complex view.
* Extracted sections aren't exposed outside the component, thus reducing component library API surface.

**Cons:**

* Another concept for users of ViewComponent to learn and understand.
* Components are no longer the only way to encapsulate behavior.

### Do nothing

**Pros:**

* The API remains simple and components are the only way to encapsulate behavior.
* Encourages creating reusable sub-components.

**Cons:**

* Extracting a component results in more GC and intermediate objects.
* Extracting a component may result in coupled but split components.
* Creates new public components thus expanding component library API surface.

## Decision

Support multiple sidecar templates. Compile each template into its own method `render_<template_name>_template`. To allow the compiled method to receive arguments,
the template must define them using the same syntax as [Rails' Strict Locals](https://edgeguides.rubyonrails.org/action_view_overview.html#strict-locals), with one difference: a missing strict locals tag means the template takes no arguments (equivalent to `locals: ()`).

## Consequences

This implementation has better performance characteristics over both an extracted component
and ActionView partials because it avoids creating intermediate objects and the overhead of
creating bindings and `instance_exec`. Having explicit arguments makes the interface explicit.

There is no provision at the moment to allow `render(*)` to render a sub template. This could be
added later if necessary and it becomes desirable.

The generated methods are only invokable via keyword arguments, inheriting the limitation
from ActionView.

The generated methods are public, and thus could be invoked by a third party. There is
no pressing need to make the methods private, and we avoid introducing new concepts
into ViewComponent.
