---
layout: default
title: Overview
nav_order: 1
---

# ViewComponent

A framework for building reusable, testable & encapsulated view components in Ruby on Rails.

## Design philosophy

ViewComponent is designed to integrate as seamlessly as possible [with Rails](https://rubyonrails.org/doctrine/), with the [least surprise](https://www.artima.com/intv/ruby4.html).

## Compatibility

ViewComponent is [supported natively](https://edgeguides.rubyonrails.org/layouts_and_rendering.html#rendering-objects) in Rails 6.1, and compatible with Rails 5.0+ via an included [monkey patch](https://github.com/github/view_component/blob/main/lib/view_component/render_monkey_patch.rb).

ViewComponent is tested for compatibility [with combinations of](https://github.com/github/view_component/blob/22e3d4ccce70d8f32c7375e5a5ccc3f70b22a703/.github/workflows/ruby_on_rails.yml#L10-L11) Ruby 2.4+ and Rails 5+.

## Installation

In `Gemfile`, add:

```ruby
gem "view_component", require: "view_component/engine"
```