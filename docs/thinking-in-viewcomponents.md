---
layout: default
title: Thinking in ViewComponents
nav_order: 4
---

# Thinking in ViewComponents

_GitHub's guide to building component-driven UI in Rails, shared publicly due to interest from the community._

_Consider it to be more opinion than fact._

## Why we use ViewComponents

We built the ViewComponent framework to help manage the growing complexity of the GitHub.com view layer. We've accumulated thousands of templates over the years, almost entirely through copy-pasting. A lack of abstraction made it difficult to make sweeping design, accessibility, and behavior improvements.

ViewComponent gives us a way to isolate and abstract common UI patterns for testability and reuse, helping us improve the quality and consistency of the customer experience.

## Everything is a ViewComponent

Our goal is to build all of GitHub's Rails-rendered HTML with ViewComponents, composed of [Primer ViewComponents](https://primer.style/view-components/).

Using Primer ViewComponents ensures that our UIs remain consistent, accessible, and correctly designed.

## The two types of ViewComponents we write

We build our views using ViewComponents that generally fall into two categories: app-specific and general-purpose.

### General-purpose ViewComponents

General-purpose ViewComponents implement common UI patterns. At GitHub, we open-source these components as [Primer ViewComponents](https://primer.style/view-components/).

### App-specific ViewComponents

App-specific ViewComponents translate a domain object (often an ActiveRecord model) into one or more general-purpose components.

For example: we have a `User::AvatarComponent` that accepts a `User` ActiveRecord object and renders a `Primer::AvatarComponent`.

## Implementation

### Extract general-purpose ViewComponents

> Good frameworks are extracted, not invented - [DHH](https://dhh.dk/arc/000416.html)

Just as ViewComponent itself was extracted from GitHub.com, our experience has shown that the best general-purpose components are those extracted from the GitHub application once they've proven useful across more than one area.

### Reduce permutations

As we build ViewComponents, we should look for opportunities to consolidate similar patterns into a single implementation.

### Avoid global state

The more a ViewComponent is dependent on global state (such as request paramters or the current URL), the less likely it is to be reusable. Avoid implicit coupling to global state, instead passing it into the component explicitly. Unit testing your ViewComponent thoroughly is a good way to ensure decoupling from global state.

### Avoid inline Ruby in ViewComponent templates

As much as possible, avoid writing inline Ruby in ViewComponent templates. Try using an instance method on the ViewComponent instead.

###