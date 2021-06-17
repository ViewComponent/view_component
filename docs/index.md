---
layout: default
title: Overview
nav_order: 1
---

# ViewComponent

A framework for building reusable, testable & encapsulated view components in Ruby on Rails.

## What are ViewComponents?

ViewComponents are Ruby objects used to build markup. Think of them as an evolution of the presenter pattern, inspired by [React](https://reactjs.org/docs/react-component.html).

## When should I use ViewComponents?

ViewComponents are most effective when view code is reused or would benefit from being tested directly. Heavily reused partials and templates with significant amounts of embedded Ruby often make good ViewComponents.

## Why should I use ViewComponents?

### Testing

Unlike traditional Rails views, ViewComponents can be unit tested. In the GitHub codebase, ViewComponent unit tests are over 100x faster than similar controller tests.

With ViewComponent, integration tests can be reserved for end-to-end assertions, with permutations covered at the unit level.

### Data Flow

Traditional Rails views have an implicit interface, making it hard to reason about their dependencies. This can lead to subtle bugs when rendering the same view in different contexts.

ViewComponents use a standard Ruby initializer that clearly defines what is needed to render, making reuse easier (and safer) than with partials.

### Performance

Based on our [benchmarks](https://github.com/github/view_component/blob/main/performance/benchmark.rb), ViewComponents are ~10x faster than partials.

### Standards

Views often fail basic Ruby code quality standards: long methods, deep conditional nesting, and mystery guests abound.

ViewComponents are Ruby objects, making it easy to follow (and enforce) code quality standards.

## Design philosophy

ViewComponent is designed to integrate as seamlessly as possible [with Rails](https://rubyonrails.org/doctrine/), with the [least surprise](https://www.artima.com/intv/ruby4.html).

## Contributors

ViewComponent is built by:

<img src="https://avatars.githubusercontent.com/asgerb?s=64" alt="asgerb" width="32" />
<img src="https://avatars.githubusercontent.com/bbugh?s=64" alt="bbugh" width="32" />
<img src="https://avatars.githubusercontent.com/bigbigdoudou?s=64" alt="bigbigdoudou" width="32" />
<img src="https://avatars.githubusercontent.com/blakewilliams?s=64" alt="blakewilliams" width="32" />
<img src="https://avatars.githubusercontent.com/bobmaerten?s=64" alt="bobmaerten" width="32" />
<img src="https://avatars.githubusercontent.com/bradparker?s=64" alt="bradparker" width="32" />
<img src="https://avatars.githubusercontent.com/cesariouy?s=64" alt="cesariouy" width="32" />
<img src="https://avatars.githubusercontent.com/cover?s=64" alt="cover" width="32" />
<img src="https://avatars.githubusercontent.com/czj?s=64" alt="czj" width="32" />
<img src="https://avatars.githubusercontent.com/dark-panda?s=64" alt="dark-panda" width="32" />
<img src="https://avatars.githubusercontent.com/davekaro?s=64" alt="davekaro" width="32" />
<img src="https://avatars.githubusercontent.com/dukex?s=64" alt="dukex" width="32" />
<img src="https://avatars.githubusercontent.com/dylnclrk?s=64" alt="dylnclrk" width="32" />
<img src="https://avatars.githubusercontent.com/elia?s=64" alt="elia" width="32" />
<img src="https://avatars.githubusercontent.com/franco?s=64" alt="franco" width="32" />
<img src="https://avatars.githubusercontent.com/franks921?s=64" alt="franks921" width="32" />
<img src="https://avatars.githubusercontent.com/fsateler?s=64" alt="fsateler" width="32" />
<img src="https://avatars.githubusercontent.com/fugufish?s=64" alt="fugufish" width="32" />
<img src="https://avatars.githubusercontent.com/g13ydson?s=64" alt="g13ydson" width="32" />
<img src="https://avatars.githubusercontent.com/horacio?s=64" alt="horacio" width="32" />
<img src="https://avatars.githubusercontent.com/jaredcwhite?s=64" alt="jaredcwhite" width="32" />
<img src="https://avatars.githubusercontent.com/jcoyne?s=64" alt="jcoyne" width="32" />
<img src="https://avatars.githubusercontent.com/jensljungblad?s=64" alt="jensljungblad" width="32" />
<img src="https://avatars.githubusercontent.com/joelhawksley?s=64" alt="joelhawksley" width="32" />
<img src="https://avatars.githubusercontent.com/johannesengl?s=64" alt="johannesengl" width="32" />
<img src="https://avatars.githubusercontent.com/jonspalmer?s=64" alt="jonspalmer" width="32" />
<img src="https://avatars.githubusercontent.com/juanmanuelramallo?s=64" alt="juanmanuelramallo" width="32" />
<img src="https://avatars.githubusercontent.com/jules2689?s=64" alt="jules2689" width="32" />
<img src="https://avatars.githubusercontent.com/kaspermeyer?s=64" alt="kaspermeyer" width="32" />
<img src="https://avatars.githubusercontent.com/kylefox?s=64" alt="kylefox" width="32" />
<img src="https://avatars.githubusercontent.com/manuelpuyol?s=64" alt="manuelpuyol" width="32" />
<img src="https://avatars.githubusercontent.com/mattbrictson?s=64" alt="mattbrictson" width="32" />
<img src="https://avatars.githubusercontent.com/maxbeizer?s=64" alt="maxbeizer" width="32" />
<img src="https://avatars.githubusercontent.com/mellowfish?s=64" alt="mellowfish" width="32" />
<img src="https://avatars.githubusercontent.com/metade?s=64" alt="metade" width="32" />
<img src="https://avatars.githubusercontent.com/michaelem?s=64" alt="michaelem" width="32" />
<img src="https://avatars.githubusercontent.com/mixergtz?s=64" alt="mixergtz" width="32" />
<img src="https://avatars.githubusercontent.com/mrrooijen?s=64" alt="mrrooijen" width="32" />
<img src="https://avatars.githubusercontent.com/nashby?s=64" alt="nashby" width="32" />
<img src="https://avatars.githubusercontent.com/nielsslot?s=64" alt="nshki" width="32" />
<img src="https://avatars.githubusercontent.com/nshki?s=64" alt="nshki" width="32" />
<img src="https://avatars.githubusercontent.com/rainerborene?s=64" alt="rainerborene" width="32" />
<img src="https://avatars.githubusercontent.com/rdavid1099?s=64" alt="rdavid1099" width="32" />
<img src="https://avatars.githubusercontent.com/rmacklin?s=64" alt="rmacklin" width="32" />
<img src="https://avatars.githubusercontent.com/seanpdoyle?s=64" alt="seanpdoyle" width="32" />
<img src="https://avatars.githubusercontent.com/simonrand?s=64" alt="simonrand" width="32" />
<img src="https://avatars.githubusercontent.com/skryukov?s=64" alt="skryukov" width="32" />
<img src="https://avatars.githubusercontent.com/smashwilson?s=64" alt="smashwilson" width="32" />
<img src="https://avatars.githubusercontent.com/spdawson?s=64" alt="spdawson" width="32" />
<img src="https://avatars.githubusercontent.com/Spone?s=64" alt="Spone" width="32" />
<img src="https://avatars.githubusercontent.com/swanson?s=64" alt="swanson" width="32" />
<img src="https://avatars.githubusercontent.com/tbroad-ramsey?s=64" alt="tbroad-ramsey" width="32" />
<img src="https://avatars.githubusercontent.com/tclem?s=64" alt="tclem" width="32" />
<img src="https://avatars.githubusercontent.com/tenderlove?s=64" alt="tenderlove" width="32" />
<img src="https://avatars.githubusercontent.com/tonkpils?s=64" alt="tonkpils" width="32" />
<img src="https://avatars.githubusercontent.com/traels?s=64" alt="traels" width="32" />
<img src="https://avatars.githubusercontent.com/vinistock?s=64" alt="vinistock" width="32" />
<img src="https://avatars.githubusercontent.com/xronos-i-am?s=64" alt="xronos-i-am" width="32" />
<img src="https://avatars.githubusercontent.com/matheusrich?s=64" alt="matheusrich" width="32" />
