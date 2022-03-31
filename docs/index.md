---
layout: default
title: Overview
nav_order: 1
---

# ViewComponent

A framework for creating reusable, testable & encapsulated view components, built to integrate seamlessly with Ruby on Rails.

## Why ViewComponent?

### Cohesion

If you put all your domain logic into Active Record models, then it's easy for the Active Record models to grow too large and lose cohesion.

A model loses cohesion when its contents no longer relate to the same end purpose.
Maybe there are a few methods that support feature A, a few methods that support feature B, and so on.
The question "what idea does this model represent?" can’t be answered.
The reason the question can’t be answered is because the model doesn’t represent just one idea, it represents a heterogeneous mix of ideas.

Because cohesive things are easier to understand than incohesive things, it can be advantageous to organize your code into objects (and other structures) that have cohesion.

### Achieving cohesion

There are two devices that developers often use in order to try to achieve cohesion in their Rails apps.

#### POROs

One way is to organize code into plain old Ruby objects (POROs).
For example, you might have objects called `AppointmentBalance`, `ChargeBalance`, and `InsuranceBalance` which are responsible for the jobs of calculating the balances for various owed amounts in an application.

#### Concerns/mixins

When there's a piece of code which doesn’t quite fit in with any existing model, but it also doesn’t quite make sense as its own standalone model, then sometimes developers use concerns or mixins.

But even though POROs and concerns/mixins can go a really long way to give structure to my Rails apps, they can’t adequately cover everything.

### Homeless code

It's often possible to keep the vast majority of an app's code out of controllers and views. Most of the app's code can be housed in the model.

But there's often still a good amount of code for which doesn't have a comfortable home in the model.
That tends to be view-related code.
View-related code is often very fine-grained and detailed.
It's also often tightly coupled (at least from a conceptual standpoint) to the DOM or to the HTML or in some other way.

There are certain places where this code could go. None of them is great. Here are some options and why each is less than perfect.

#### The view

Perhaps the most obvious place to try to put view-related code is in the view itself.
Most of the time this works out great.
But when the view-related code is sufficiently complicated or voluminous, it creates a distraction.
It creates a mixture of levels of abstraction, which makes the code harder to understand.

#### The controller

The controller is also not a great home for this view-related code.
The problem of mixing levels of abstraction is still there.
In addition, putting view-related code in a controller mixes concerns, which makes the controller code harder to understand.

#### The model

Another poorly-suited home for this view-related code is the model. There are two options, both not great.

The first option is to put the view-related code into some existing model.
This option isn't great because it pollutes the model with peripheral details, creates a potential mixture of concerns and mixture of levels of abstraction, and makes the model lose cohesion.

The other option is to create a new, standalone model just for the view-related code.
This is usually better than stuffing it into an existing model but it's often still not great.
Now the view-related code and the view itself are at a distance from each other.
Plus it creates a mixture of abstractions at a macro level because now the code in `app/models` contains view-related code.

#### Helpers

Lastly, one possible home for non-trivial view-related code is a helper.
This can actually be a perfectly good solution sometimes.
But sometimes there are still problems.

Sometimes the view-related code is sufficiently complicated to require multiple methods.
If these methods are placed in a helper which is also home to other concerns, then we have a cohesion problem, and things get confusing.
In those cases the view-related code can perhaps be put into its own new helper, and maybe that’s fine.
But sometimes that's a lost opportunity because what's really wanted is a concept with meaning, and helpers (with their `-Helper` suffix) aren’t great for creating concepts with meaning.

#### No good home

The result is that when you have non-trivial view-related code, it doesn’t have a good home.
Instead, your view-related code has to "stay with friends".
It’s an uncomfortable arrangement.
The "friends" (controllers, models, etc.) wish that the view-related code would move out and get a place of its own, but it doesn’t have a place to go.

#### How ViewComponent provides a home for view-related code

A ViewComponent consists of two entities: 1) an ERB file and 2) a Ruby object.
These two files share a name (e.g. `save_button_component.html.erb` and `save_button_component.rb` and sit at a sibling level to each other in the filesystem.
This makes it easy to see that they’re closely related to one another.

If you use ViewComponent, your homeless view-related code can move into a nice, spacious, tidy new house that it gets all to its own.
And just as important, it can get out of its friends' hair.

And in case this sounds like a “silver bullet” situation, it’s not.
The reason is because ViewComponents are a specific solution to a specific problem.
ViewComponents aren't meant to be used for everything.
They're only meant to be used when a view has non-trivial logic associated with it that doesn’t have any other good place to live.

## What is a ViewComponent?

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
<h1>Hello, <%= @name %>!</h1>
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

## Why should I use ViewComponents?

### Testing

Unlike traditional Rails templates, ViewComponents can be unit tested. In the GitHub codebase, ViewComponent unit tests are over 100x faster than similar controller tests.

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

Based on several [benchmarks](https://github.com/github/view_component/blob/main/performance/benchmark.rb), ViewComponents are ~10x faster than partials in real-world use-cases.

The primary optimization is pre-compiling all ViewComponent templates at application boot, instead of at runtime like traditional Rails views.

For example, the `MessageComponent` template is compiled onto the Ruby object like so:

```ruby
# app/components/message_component.rb
class MessageComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end

  def call
    @output_buffer.safe_append='<h1>Hello, '.freeze
    @output_buffer.append=( @name )
    @output_buffer.safe_append='!</h1>'.freeze
    @output_buffer.to_s
  end
end
```

### Code quality

Template code often fails basic Ruby standards: long methods, deep conditional nesting, and mystery guests abound.

ViewComponents are Ruby objects, making it easy to follow (and enforce) code quality standards.

## Contributors

ViewComponent is built by over a hundred members of the community, including:

<img src="https://avatars.githubusercontent.com/andrewjtait?s=64" alt="andrewjtait" width="32" />
<img src="https://avatars.githubusercontent.com/asgerb?s=64" alt="asgerb" width="32" />
<img src="https://avatars.githubusercontent.com/bbugh?s=64" alt="bbugh" width="32" />
<img src="https://avatars.githubusercontent.com/bigbigdoudou?s=64" alt="bigbigdoudou" width="32" />
<img src="https://avatars.githubusercontent.com/blakewilliams?s=64" alt="blakewilliams" width="32" />
<img src="https://avatars.githubusercontent.com/boardfish?s=64" alt="boardfish" width="32" />
<img src="https://avatars.githubusercontent.com/bobmaerten?s=64" alt="bobmaerten" width="32" />
<img src="https://avatars.githubusercontent.com/bpo?s=64" alt="bpo" width="32" />
<img src="https://avatars.githubusercontent.com/bradparker?s=64" alt="bradparker" width="32" />
<img src="https://avatars.githubusercontent.com/cesariouy?s=64" alt="cesariouy" width="32" />
<img src="https://avatars.githubusercontent.com/cover?s=64" alt="cover" width="32" />
<img src="https://avatars.githubusercontent.com/cpjmcquillan?s=64" alt="cpjmcquillan" width="32" />
<img src="https://avatars.githubusercontent.com/czj?s=64" alt="czj" width="32" />
<img src="https://avatars.githubusercontent.com/dark-panda?s=64" alt="dark-panda" width="32" />
<img src="https://avatars.githubusercontent.com/davekaro?s=64" alt="davekaro" width="32" />
<img src="https://avatars.githubusercontent.com/dixpac?s=64" alt="dixpac" width="32" />
<img src="https://avatars.githubusercontent.com/dukex?s=64" alt="dukex" width="32" />
<img src="https://avatars.githubusercontent.com/dylanatsmith?s=64" alt="dylanatsmith" width="32" />
<img src="https://avatars.githubusercontent.com/dylnclrk?s=64" alt="dylnclrk" width="32" />
<img src="https://avatars.githubusercontent.com/edwinthinks?s=64" alt="edwinthinks" width="32" />
<img src="https://avatars.githubusercontent.com/elia?s=64" alt="elia" width="32" />
<img src="https://avatars.githubusercontent.com/franco?s=64" alt="franco" width="32" />
<img src="https://avatars.githubusercontent.com/franks921?s=64" alt="franks921" width="32" />
<img src="https://avatars.githubusercontent.com/fsateler?s=64" alt="fsateler" width="32" />
<img src="https://avatars.githubusercontent.com/fugufish?s=64" alt="fugufish" width="32" />
<img src="https://avatars.githubusercontent.com/g13ydson?s=64" alt="g13ydson" width="32" />
<img src="https://avatars.githubusercontent.com/horacio?s=64" alt="horacio" width="32" />
<img src="https://avatars.githubusercontent.com/horiaradu?s=64" alt="horiaradu" width="32" />
<img src="https://avatars.githubusercontent.com/jaredcwhite?s=64" alt="jaredcwhite" width="32" />
<img src="https://avatars.githubusercontent.com/javierm?s=64" alt="javierm" width="32" />
<img src="https://avatars.githubusercontent.com/jcoyne?s=64" alt="jcoyne" width="32" />
<img src="https://avatars.githubusercontent.com/jensljungblad?s=64" alt="jensljungblad" width="32" />
<img src="https://avatars.githubusercontent.com/joelhawksley?s=64" alt="joelhawksley" width="32" />
<img src="https://avatars.githubusercontent.com/johannesengl?s=64" alt="johannesengl" width="32" />
<img src="https://avatars.githubusercontent.com/jonspalmer?s=64" alt="jonspalmer" width="32" />
<img src="https://avatars.githubusercontent.com/juanmanuelramallo?s=64" alt="juanmanuelramallo" width="32" />
<img src="https://avatars.githubusercontent.com/jules2689?s=64" alt="jules2689" width="32" />
<img src="https://avatars.githubusercontent.com/kaspermeyer?s=64" alt="kaspermeyer" width="32" />
<img src="https://avatars.githubusercontent.com/kylefox?s=64" alt="kylefox" width="32" />
<img src="https://avatars.githubusercontent.com/leighhalliday?s=64" alt="leighhalliday" width="32" />
<img src="https://avatars.githubusercontent.com/manuelpuyol?s=64" alt="manuelpuyol" width="32" />
<img src="https://avatars.githubusercontent.com/matheusrich?s=64" alt="matheusrich" width="32" />
<img src="https://avatars.githubusercontent.com/matt-yorkley?s=64" alt="Matt-Yorkley" width="32" />
<img src="https://avatars.githubusercontent.com/mattbrictson?s=64" alt="mattbrictson" width="32" />
<img src="https://avatars.githubusercontent.com/mattwr18?s=64" alt="mattwr18" width="32" />
<img src="https://avatars.githubusercontent.com/maxbeizer?s=64" alt="maxbeizer" width="32" />
<img src="https://avatars.githubusercontent.com/mellowfish?s=64" alt="mellowfish" width="32" />
<img src="https://avatars.githubusercontent.com/metade?s=64" alt="metade" width="32" />
<img src="https://avatars.githubusercontent.com/michaelem?s=64" alt="michaelem" width="32" />
<img src="https://avatars.githubusercontent.com/mixergtz?s=64" alt="mixergtz" width="32" />
<img src="https://avatars.githubusercontent.com/mrrooijen?s=64" alt="mrrooijen" width="32" />
<img src="https://avatars.githubusercontent.com/nashby?s=64" alt="nashby" width="32" />
<img src="https://avatars.githubusercontent.com/nicolas-brousse?s=64" alt="nicolas-brousse" width="32" />
<img src="https://avatars.githubusercontent.com/nielsslot?s=64" alt="nshki" width="32" />
<img src="https://avatars.githubusercontent.com/nshki?s=64" alt="nshki" width="32" />
<img src="https://avatars.githubusercontent.com/rainerborene?s=64" alt="rainerborene" width="32" />
<img src="https://avatars.githubusercontent.com/rdavid1099?s=64" alt="rdavid1099" width="32" />
<img src="https://avatars.githubusercontent.com/rmacklin?s=64" alt="rmacklin" width="32" />
<img src="https://avatars.githubusercontent.com/ryogift?s=64" alt="ryogift" width="32" />
<img src="https://avatars.githubusercontent.com/sammyhenningsson?s=64" alt="sammyhenningsson" width="32" />
<img src="https://avatars.githubusercontent.com/seanpdoyle?s=64" alt="seanpdoyle" width="32" />
<img src="https://avatars.githubusercontent.com/simonrand?s=64" alt="simonrand" width="32" />
<img src="https://avatars.githubusercontent.com/skryukov?s=64" alt="skryukov" width="32" />
<img src="https://avatars.githubusercontent.com/smashwilson?s=64" alt="smashwilson" width="32" />
<img src="https://avatars.githubusercontent.com/spdawson?s=64" alt="spdawson" width="32" />
<img src="https://avatars.githubusercontent.com/spone?s=64" alt="Spone" width="32" />
<img src="https://avatars.githubusercontent.com/stiig?s=64" alt="stiig" width="32" />
<img src="https://avatars.githubusercontent.com/swanson?s=64" alt="swanson" width="32" />
<img src="https://avatars.githubusercontent.com/tbroad-ramsey?s=64" alt="tbroad-ramsey" width="32" />
<img src="https://avatars.githubusercontent.com/tclem?s=64" alt="tclem" width="32" />
<img src="https://avatars.githubusercontent.com/tenderlove?s=64" alt="tenderlove" width="32" />
<img src="https://avatars.githubusercontent.com/tonkpils?s=64" alt="tonkpils" width="32" />
<img src="https://avatars.githubusercontent.com/traels?s=64" alt="traels" width="32" />
<img src="https://avatars.githubusercontent.com/vinistock?s=64" alt="vinistock" width="32" />
<img src="https://avatars.githubusercontent.com/wdrexler?s=64" alt="wdrexler" width="32" />
<img src="https://avatars.githubusercontent.com/websebdev?s=64" alt="websebdev" width="32" />
<img src="https://avatars.githubusercontent.com/xkraty?s=64" alt="xkraty" width="32" />
<img src="https://avatars.githubusercontent.com/xronos-i-am?s=64" alt="xronos-i-am" width="32" />
<img src="https://avatars.githubusercontent.com/yykamei?s=64" alt="yykamei" width="32" />

## Who uses ViewComponent?

* [Brightline](https://hellobrightline.com)
* [City of Paris](https://www.paris.fr/)
* [Cometeer](https://cometeer.com/)
* [Cults.](https://cults3d.com/)
* [Framework](https://frame.work/)
* [GitHub](https://github.com/) (900+ components used 15k+ times)
* [Litmus](https://litmus.engineering/)
* [Orbit](https://orbit.love)
* [Podia](https://www.podia.com/)
* [Shogun](https://getshogun.com/)
* [Wecasa](https://www.wecasa.fr/)
* [Wrapbook](https://wrapbook.com/)

If your team starts using ViewComponent, [send a pull request](https://github.com/github/view_component/edit/main/docs/index.md) to let us know!
You can also check out [how various projects use ViewComponent](https://github.com/github/view_component/network/dependents?package_id=UGFja2FnZS0xMDEwNjQxMzYx).

<hr />

[Getting started →](/guide/getting-started.html)
