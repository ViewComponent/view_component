# 1. Allow multiple templates 

Date: 2021-10-13

## Status

Proposed.

## Context

As components become larger (for example, because you are implementing a whole page), it becomes
useful to be able to extract sections of the view to a different file. ActionView has
partials, and ViewComponent lacks a similar mechanism. 

ActionView partials have the problem that their interface is not introspectable. Data
may be passed into the partial via ivars or locals, and it is impossible to know
which without actually opening up the file. Additionally, partials are globally
invocable, thus making it difficult to detect if a given partial is in use or not,
and who are its users.

## Considered Options

* Introduce component partials to components
* Keep components as-is

### Component partials

Allow multiple ERB templates available within the component, and make it possible to
invoke them from the main view.Templates are compiled to methods in the format `render_#{template_basename}(locals = {})`

**Pros:**
* Better performance due to lack of GC pressure and object creation
* Reduces the number of components needed to express a more complex view.
* Extracted sections are not exposed outside the component, thus reducing component library API surface.

**Cons:**
* Another concept for users of ViewComponent to learn and understand.
* Components are no longer the only way to encapsulate behavior.

### Partial components by [fstaler](https://github.com/fsateler)

In this approach the template arguments are previously defined in the `template_arguments` method

[See here](https://github.com/github/view_component/pull/451):

**Pros:**
* Better performance due to lack of GC pressure and object creation
* Reduces the number of components needed to express a more complex view.
* Extracted sections are not exposed outside the component, thus reducing component library API surface.

**Cons:**
* Another concept for users of ViewComponent to learn and understand.
* Components are no longer the only way to encapsulate behavior.
* `call_foo` api feels awkward and not very Rails like
* Declare templates and their arguments explicitly before using them

### Keeping components as-is

**Pros:**
* The API remains simple and components are the only way to encapsulate behavior.
* Encourages creating reusable sub-components.

**Cons:**
* Extracting a component results in more GC and intermediate objects.
* Extracting a component may result in tightly coupled but split components.
* Creates new public components thus expanding component library API surface.

## Decision

We will allow having multiple templates in the sidecar asset. Each asset will be compiled to
it's own method `render_<template_name>`. I think it is simple, similar to rails and meets what is expected

## Consequences

This implementation has better performance characteristics over both an extracted component
and ActionView partials, because it avoids creating intermediate objects, and the overhead of
creating bindings and `instance_exec`. 
Having explicit arguments makes the interface explicit.

TODO: The following are consequences of the current approach, but the approach might be extended
to avoid them:

The interface to render a sidecar partial would be a method call, and depart from the usual 
`render(*)` interface used in ActionView.

The generated methods cannot have arguments with default values.

The generated methods are public, and thus could be invoked by a third party.