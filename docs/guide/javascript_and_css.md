---
layout: default
title: JavaScript and CSS
parent: How-to guide
---

# JavaScript and CSS

While ViewComponent doesn't provide any built-in tooling to do so, it’s possible to include JavaScript and CSS alongside components.

## Propshaft / Stimulus

To use a [transpiler-less and bundler-less approach to JavaScript](https://world.hey.com/dhh/modern-web-apps-without-javascript-bundling-or-transpiling-a20f2755) (the default for Rails 8), Stimulus and CSS can be used inside ViewComponents one of two ways:

### Upgrading a pre-Rails 8 app

```ruby
# Gemfile (then run `bundle install`)
gem "importmap-rails" # JavaScript version/digests without transpiling/bundling
gem "propshaft" # Load static assets like JavaScript/CSS/images without transpilation/webpacker
gem "stimulus-rails" # Hotwire JavaScript approach
```

```js
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

const application = Application.start()

application.debug = false
window.Stimulus   = application

export { application }
```

```js
// app/javascript/controllers/index.js
import { application } from "controllers/application"
```

```ruby
# config/importmap.rb
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "application", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
```

### Approach 1 - Default _app/components_ ViewComponent directory using named Stimulus controllers, no autoloading

Locate CSS and Stimulus js with a ViewComponent. This example demonstrates a _HelloWorldComponent_ in an _examples_ namespace with a sidecar file naming approach:

```console
app/components
├── ...
├── examples
|   ├── hello_world_component
|   |   ├── hello_world_component_controller.js
|   |   ├── hello_world_component.css
|   |   └── hello_world_component.html.erb
|   └── hello_world_component.rb
├── ...
```

#### 1. Prepare _app/components_ as an asset path for css and ensure hot reloads of Stimulus JavaScript

```ruby
# config/application.rb
config.assets.paths << "app/components"
config.importmap.cache_sweepers << config.root.join("app/components")
```

#### 2. Pin ViewComponent Stimulus import map entries

```ruby
# config/importmap.rb
pin_all_from "app/components"
```

#### 3. Expose the Stimulus controller with a named key:

```ruby
# app/javascript/controllers/index.js
import HelloWorldComponentController from "examples/hello_world_component/hello_world_component_controller"
application.register("examples--hello-world-component", HelloWorldComponentController)
```

#### 4. Implement the ViewComponent with custom CSS and Stimulus behaviour:

```ruby
# app/components/examples/hello_world_component.rb
class Examples::HelloWorldComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
    super
  end
end
```

```erb
<!-- app/components/examples/hello_world_component/hello_world_component.html.erb -->
<%= stylesheet_link_tag "examples/hello_world_component/hello_world_component" %>

<h1><%= @title %></h1>
<p><%= content %></p>

<div data-controller="examples--hello-world-component">
  <p class="hello-world" id="<%= @id %>" data-examples--hello-world-component-target="output">
    This div will be updated by the controller
  </p>

  <button data-action="click->examples--hello-world-component#greet">Toggle Greeting</button>
</div>
```

```css
/* app/components/examples/hello_world_component/hello_world_component.css */
.hello-world {
  color: blue;
}
```

```js
// app/components/examples/hello_world_component/hello_world_component_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"]

  initialize() {
    console.log("Component initialized!");
  }

  connect() {
    console.log("Component connected!");

    this.outputTarget.textContent = "This div has been initialised by stimulus and will be updated when you click the button"
  }

  greet() {
    const currentText = this.outputTarget.textContent;
    this.outputTarget.textContent = currentText === "Hello from Stimulus!"
      ? "Goodbye from Stimulus!"
      : "Hello from Stimulus!";
  }
}
```

#### 5. Render the component in a rails view (or a [ViewComponent preview](previews.md)) to see the end result:

```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  ...
    <%= render(Examples::HelloWorldComponent.new(title: "Hello World!")) {
      "<em>This</em> will demonstrate the use of <b>Stimulus</b> and <b>CSS</b> in a ViewComponent".html_safe
      }
    %>
  ...
```

### Approach 2 - Autoloaded ViewComponents in a sub-directory

Stimulus controllers [won't currently autoload](https://github.com/ViewComponent/view_component/issues/1064#issuecomment-1163314487) if ViewComponents are located at:

```console
app/components
```

a workaround is to put ViewComponents in a subdirectory:

```console
app/frontend/components
```

and then autoload them in import map:

```ruby
# config/importmap.rb
pin_all_from "app/frontend/components", under: "controllers", to: "components"
```

which also requires adjustment of the ViewComponent defaults to account for the sub-directory path:

```ruby
# config/application.rb
config.autoload_paths << Rails.root.join("app/frontend/components")
config.importmap.cache_sweepers << Rails.root.join("app/frontend")
config.assets.paths << Rails.root.join("app/frontend")
config.view_component.view_component_path = "app/frontend/components"
```

allowing the autoloaded Stimulus controllers in views eg.

```erb
<!-- app/components/examples/hello_world_component/hello_world_component.html.erb -->
...
<div data-controller="examples--hello-world-component--hello-world-component">
...
```

## Webpacker

To use the Webpacker gem to compile assets located in `app/components`:

1. In `config/webpacker.yml`, add `"app/components"` to the `additional_paths` array (for example `additional_paths: ["app/components"]`).
2. In the Webpack entry file (often `app/javascript/packs/application.js`), add an import statement to a helper file, and in the helper file, import the components' JavaScript:

```js
import "../components"
```

Then, in `app/javascript/components.js`, add:

```js
function importAll(r) {
  r.keys().forEach(r)
}

importAll(require.context("../components", true, /[_\/]component\.js$/))
```

Any file with the `_component.js` suffix (such as `app/components/widget_component.js`) will be compiled into the Webpack bundle. If that file itself imports another file, for example `app/components/widget_component.css`, it will also be compiled and bundled into Webpack's output stylesheet if Webpack is being used for styles.

## Encapsulating assets

Ideally, JavaScript and CSS should be scoped to the associated component.

One approach is to use Web Components which contain all JavaScript functionality, internal markup, and styles within the shadow root of the Web Component.

For example:

```ruby
# app/components/comment_component.rb
class CommentComponent < ViewComponent::Base
  def initialize(comment:)
    @comment = comment
  end

  def commenter
    @comment.user
  end

  def commenter_name
    commenter.name
  end

  def avatar
    commenter.avatar_image_url
  end

  def formatted_body
    simple_format(@comment.body)
  end

  private

  attr_reader :comment
end
```

```erb
<%# app/components/comment_component.html.erb %>
<my-comment comment-id="<%= comment.id %>">
  <time slot="posted" datetime="<%= comment.created_at.iso8601 %>"><%= comment.created_at.strftime("%b %-d") %></time>

  <div slot="avatar"><img src="<%= avatar %>" /></div>

  <div slot="author"><%= commenter_name %></div>

  <div slot="body"><%= formatted_body %></div>
</my-comment>
```

```js
// app/components/comment_component.js
class Comment extends HTMLElement {
  styles() {
    return `
      :host {
        display: block;
      }
      ::slotted(time) {
        float: right;
        font-size: 0.75em;
      }
      .commenter { font-weight: bold; }
      .body { … }
    `
  }

  constructor() {
    super()
    const shadow = this.attachShadow({mode: 'open'});
    shadow.innerHTML = `
      <style>
        ${this.styles()}
      </style>
      <slot name="posted"></slot>
      <div class="commenter">
        <slot name="avatar"></slot> <slot name="author"></slot>
      </div>
      <div class="body">
        <slot name="body"></slot>
      </div>
    `
  }
}
customElements.define('my-comment', Comment)
```
