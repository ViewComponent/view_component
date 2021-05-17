---
layout: default
title: API
---

<!-- Warning: AUTO-GENERATED file, do not edit. Add code comments to your Ruby instead <3 -->

# API

## Instance methods

### #_output_postamble → [String]

EXPERIMENTAL: Optional content to be returned after the rendered template.

### #before_render → [void]

Called before rendering the component. Override to perform operations that depend on having access to the view context, such as helpers.

### #before_render_check → [void] (Deprecated)

Called after rendering the component.

_Use `before_render` instead. Will be removed in v3.0.0._

### #render? → [Boolean]

Override to determine whether the ViewComponent should render.

### #controller → [ActionController::Base]

The current controller. Use sparingly as doing so introduces coupling that inhibits encapsulation & reuse, often making testing difficult.

### #helpers → [ActionView::Base]

A proxy through which to access helpers. Use sparingly as doing so introduces coupling that inhibits encapsulation & reuse, often making testing difficult.

### #request → [ActionDispatch::Request]

The current request. Use sparingly as doing so introduces coupling that inhibits encapsulation & reuse, often making testing difficult.
