---
layout: default
title: History
nav_order: 8
---

# History

## Prototype at GitHub

Inspired by the benefits he was seeing from using React at GitHub, [@joelhawksley](http://github.com/joelhawksley) built a prototype with [@tenderlove](https://github.com/tenderlove) of what it might look like to incorporate ideas from React into Rails.

They took inspiration from existing projects such as [trailblazer/cells](https://github.com/trailblazer/cells), [dry-view](https://github.com/dry-rb/dry-view), [komponent](https://github.com/komposable/komponent), and [arbre](https://github.com/activeadmin/arbre), designing an API meant to integrate as seamlessly as possible with Rails.

## ActionView::Component

Once the prototype was tested in production, GitHub open sourced the project as ActionView::Component. [@joelhawksley](http://github.com/joelhawksley) presented the prototype at [RailsConf 2019](https://www.youtube.com/watch?v=y5Z5a6QdA-M).

## Support for 3rd-party component frameworks in Rails

In [rails#36388](https://github.com/rails/rails/pull/36388), Rails added support for 3rd-party component frameworks via the `render_in` API.

## ViewComponent

In `v2.0.0`, `ActionView::Component` was renamed to `ViewComponent`, delineating it as a project separate from Rails.
