---
layout: default
title: API
---

<!-- Warning: AUTO-GENERATED file, do not edit. Add code comments to your Ruby instead <3 -->

# API

## Instance methods

### #before_render → [void]

Called before rendering the component.

### #before_render_check → [void] (Deprecated)

Called after rendering the component.

_Use `before_render` instead. Will be removed in v3.0.0._

### #render? → [Boolean]

Whether the ViewComponent should render.

### #controller → [ActionController::Base]

The current controller. Use sparingly as doing so introduces coupling that inhibits encapsulation & reuse, often making testing difficult.

### #helpers → [ActionView::Base]

A proxy through which to access helpers. Use sparingly as doing so introduces coupling that inhibits encapsulation & reuse, often making testing difficult.

### #request → [ActionDispatch::Request]

The current request. Use sparingly as doing so introduces coupling that inhibits encapsulation & reuse, often making testing difficult.
