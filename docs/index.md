---
layout: default
title: Overview
nav_order: 1
---

# ViewComponent (v{{ site.data.library.version }})

A framework for creating reusable, testable & encapsulated view components, built to integrate seamlessly with Ruby on Rails.

_As of version 4, ViewComponent is in Long-Term Support and considered feature-complete._

## What's a ViewComponent?

ViewComponents are Ruby objects used to build markup. Think of them as an evolution of the presenter pattern, inspired by [React](https://reactjs.org/docs/react-component.html).

ViewComponents are objects that encapsulate a template:

```ruby
# app/components/message_component.rb
class MessageComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end
end
```

```erb
<%# app/components/message_component.html.erb %>
<h1>Hello, <%= @name %>!<h1>
```

Which is rendered by calling:

```erb
<%# app/views/demo/index.html.erb %>
<%= render(MessageComponent.new(name: "World")) %>
```

Returning:

```html
<h1>Hello, World!</h1>
```

## Why use ViewComponents?

### TL;DR

ViewComponents work best for templates that are reused or benefit from being tested directly. Partials and templates with significant amounts of embedded Ruby often make good ViewComponents.

### Single responsibility

Rails applications often scatter view-related logic across models, controllers, and helpers, diluting their intended responsibilities. ViewComponents consolidate the logic needed for a template into a single class, resulting in a cohesive object that is easy to understand.

ViewComponent methods are implemented within the scope of the template, encapsulating them in proper object-oriented fashion. This cohesion is especially evident when multiple methods are needed for a single view.

### Testing

ViewComponent was designed with the intention that all components should be unit tested. In the GitHub codebase, ViewComponent unit tests are over 100x faster than similar controller tests.

With ViewComponent, integration tests can be reserved for end-to-end assertions, with permutations covered at the unit level.

For example, to test the `MessageComponent` above:

```ruby
class MessageComponentTest < GitHub::TestCase
  include ViewComponent::TestHelpers

  test "renders message" do
    render_inline(MessageComponent.new(name: "World"))

    assert_selector "h1", text: "Hello, World!"
  end
end
```

ViewComponent unit tests leverage the Capybara matchers library, allowing for complex assertions traditionally reserved for controller and browser tests.

### Data Flow

Traditional Rails templates have an implicit interface, making it hard to reason about their dependencies. This can lead to subtle bugs when rendering the same template in different contexts.

ViewComponents use a standard Ruby initializer that clearly defines what's needed to render, making reuse easier and safer than partials.

### Performance

Based on several [benchmarks](https://github.com/viewcomponent/view_component/blob/main/performance/partial_benchmark.rb), ViewComponents are ~2.5x faster than partials:

```console
Comparison:
  component:     6498.1 i/s
    partial:     2676.5 i/s - 2.50x  slower
```

### Code quality

Template code often fails basic Ruby standards: long methods, deep conditional nesting, and mystery guests abound.

ViewComponents are Ruby objects, making it easy to follow (and enforce) code quality standards.

## Contributors

Hundreds of people have [contributed](https://github.com/ViewComponent/view_component/graphs/contributors) to ViewComponent, including:

<div>
{% for contributor in site.data.contributors.usernames %}
<img src="https://avatars.githubusercontent.com/{{ contributor }}?s=64" alt="{{ contributor }}" width="32" />
{% endfor %}
</div>

## Who uses ViewComponent?

* [Aboard HR](https://aboardhr.com/)
* [Arrows](https://arrows.to/)
* [Aluuno](https://aluuno.com/)
* [Avo Admin for Rails](https://avohq.io/rails-admin)
* [Bearer](https://www.bearer.com/) (70+ components)
* [Brightline](https://hellobrightline.com)
* [Buildkite](https://buildkite.com)
* [Bump.sh](https://bump.sh)
* [Carwow](https://www.carwow.com/) (300+ components)
* [Causey](https://www.causey.app/) (100+ components)
* [CharlieHR](https://www.charliehr.com/)
* [City of Paris](https://www.paris.fr/)
* [Clio](https://www.clio.com/)
* [Cometeer](https://cometeer.com/)
* [Consul](https://consulproject.org/en/)
* [Consultport](https://app.consultport.com/)
* [Content Harmony](https://www.contentharmony.com/)
* [Cults.](https://cults3d.com/)
* [Defacto](https://www.defacto.nl)
* [DotRuby](https://www.dotruby.com)
* [Eagerworks](https://eagerworks.com/)
* [FlightLogger](https://flightlogger.net/)
* [Framework](https://frame.work/)
* [FreeAgent](https://www.freeagent.com)
* [FreeATS](https://www.freeats.com/)
* [G2](https://www.g2.com/) (200+ components)
* [Getblock](https://getblock.io/)
* [GitHub](https://github.com/) (900+ components used 15k+ times)
* [GitLab](https://gitlab.com/)
* [HappyCo](https://happy.co)
* [HomeStyler AI](https://homestyler.ai)
* [Keenly](https://www.keenly.so) (100+ components)
* [Kicksite](https://kicksite.com/)
* [Krystal](https://krystal.uk)
* [Launch Scout](https://launchscout.com/)
* [Learn To Be](https://www.learntobe.org/) (100+ components)
* [Litmus](https://litmus.engineering/)
* [Login.gov](https://github.com/18F/identity-idp)
* [Mission Met Center](https://www.missionmet.com/mission-met-center)
* [Mon Ami](https://www.monami.io)
* [Nikola Motor](https://www.nikolamotor.com/) (50+ components and counting)
* [Niva](https://www.niva.co/)
* [OBLSK](https://oblsk.com/)
* [openSUSE Open Build Service](https://openbuildservice.org/)
* [OpenProject](https://www.openproject.org/)
* [Ophelos](https://ophelos.com)
* [Orbit](https://orbit.love)
* [PeopleForce](https://peopleforce.io)
* [Percent Pledge](https://www.percentpledge.org/)
* [PLT4M](https://plt4m.com/)
* [Podia](https://www.podia.com/)
* [PrintReleaf](https://www.printreleaf.com/)
* [Project Blacklight](http://projectblacklight.org/)
* [QuickNode](https://www.quicknode.com/)
* [RailsCarma](https://www.railscarma.com)
* [Reinvented Hospitality](https://reinvented-hospitality.com/)
* [Room AI](https://roomai.com/)
* [SerpApi](https://www.serpapi.com/)
* [SearchApi](https://www.searchapi.io/)
* [Simundia](https://www.simundia.com/)
* [Skroutz](https://engineering.skroutz.gr/blog/)
* [Shogun](https://getshogun.com/)
* [SpendHQ](https://www.spendhq.com/)
* [Spina CMS](https://spinacms.com/)
* [Spring](https://spring.net/)
* [Startup Jobs](https://startup.jobs/)
* [TalentoHQ](https://talentohq.com)
* [Teamtailor](https://teamtailor.com/)
* [Topkey](https://topkey.io/)
* [Web3 Jobs](https://web3.career)
* [Wecasa](https://www.wecasa.fr/)
* [WIP](https://wip.co/)
* [Within3](https://www.within3.com/)
* [Workbrew](https://www.workbrew.com/)
* [Wrapbook](https://wrapbook.com/)
* [Yobbers](https://www.yobbers.com/)

Using ViewComponent? [Send a pull request](https://github.com/viewcomponent/view_component/edit/main/docs/index.md) to update this list!
You can also check out [how various projects use ViewComponent](https://github.com/viewcomponent/view_component/network/dependents?package_id=UGFja2FnZS0xMDEwNjQxMzYx).

<hr />

[Getting started →](/guide/getting-started.html)
