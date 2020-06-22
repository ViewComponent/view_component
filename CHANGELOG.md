# master

# 3.0.0

* Change counter variable to start iterating from `0` instead of `1`.

    *Frank S*

# 2.11.1

* Fix kwarg warnings in Ruby 2.7.

    *Joel Hawksley*

# 2.11.0

* Ensure Rails configuration is available within components.

    *Trevor Broaddus*

* Fix bug where global Rails helpers are inaccessible from nested components. Before, `helpers` was pointing to parent component.

    *Franco Sebregondi*

# 2.10.0

* Raise an `ArgumentError` with a helpful message when Ruby cannot parse a component class.

    *Max Beizer*

# 2.9.0

* Cache components per-request in development, preventing unnecessary recompilation during a single request.

    *Felipe Sateler*

# 2.8.0

* Add `before_render`, deprecating `before_render_check`.

    *Joel Hawksley*

# 2.7.0

* Add `rendered_component` method to `ViewComponent::TestHelpers` which exposes the raw output of the rendered component.

    *Richard Macklin*

* Support sidecar directories for views and other assets.

    *Jon Palmer*

# 2.6.0

* Add `config.view_component.preview_route` to set the endpoint for component previews. By default `/rails/view_components` is used.

    *Juan Manuel Ramallo*

* Raise error when initializer omits with_collection_parameter.

    *Joel Hawksley*

# 2.5.1

* Compile component before rendering collection.

    *Rainer Borene*

# v2.5.0

* Add counter variables when rendering collections.

    *Frank S*

* Add the ability to access params from preview examples.

    *Fabio Cantoni*

# v2.4.0

* Add `#render_to_string` support.

   *Jarod Reid*

* Declare explicit dependency on `activesupport`.

    *Richard Macklin*

* Remove `autoload`s of internal modules (`Previewable`, `RenderMonkeyPatch`, `RenderingMonkeyPatch`).

    *Richard Macklin*

* Remove `capybara` dependency.

    *Richard Macklin*

# v2.3.0

* Allow using inline render method(s) defined on a parent.

    *Simon Rand*

* Fix bug where inline variant render methods would never be called.

    *Simon Rand*

* ViewComponent preview index views use Rails internal layout instead of application's layout

    *Juan Manuel Ramallo*

# v2.2.2

* Add `Base.format` for better compatibility with `ActionView::Template`.

    *Joel Hawksley*

# v2.2.1

* Fix bug where template could not be found if `inherited` was redefined.

    *Joel Hawksley*

# v2.2.0

* Add support for `config.action_view.annotate_template_file_names` (coming in Rails 6.1).

    *Joel Hawksley*

* Remove initializer requirement from the component.

    *Vasiliy Ermolovich*

# v2.1.0

* Support rendering collections (e.g., `render(MyComponent.with_collection(@items))`).

    *Tim Clem*

# v2.0.0

* Move to `ViewComponent` namespace, removing all references to `ActionView`.

    * The gem name is now `view_component`.
    * ViewComponent previews are now accessed at `/rails/view_components`.
    * ViewComponents can _only_ be rendered with the instance syntax: `render(MyComponent.new)`. Support for all other syntaxes has been removed.
    * ActiveModel::Validations have been removed. ViewComponent generators no longer include validations.
    * In Rails 6.1, no monkey patching is used.
    * `to_component_class` has been removed.
    * All gem configuration is now in `config.view_component`.

# v1.17.0

* Support Ruby 2.4 in CI.

    *Andrew Mason*

* ViewComponent generators do not not prompt for content requirement.

    *Joel Hawksley*

* Add post-install message that gem has been renamed to `view_component`.

    *Joel Hawksley*

# v1.16.0

* Add `refute_component_rendered` test helper.

    *Joel Hawksley*

* Check for Rails before invocation.

    *Dave Paola*

* Allow components to be rendered without a template file (aka inline component).

    *Rainer Borene*

# v1.15.0

* Re-introduce ActionView::Component::TestHelpers.

    *Joel Hawksley*

* Bypass monkey patch on Rails 6.1 builds.

    *Joel Hawksley*

* Make `ActionView::Helpers::TagHelper` available in Previews.

    ```ruby
    def with_html_content
      render(MyComponent.new) do
        tag.div do
          content_tag(:span, "Hello")
        end
      end
    end
    ```

    *Sean Doyle*

# v1.14.1

* Fix bug where generator created invalid test code.

    *Joel Hawksley*

# v1.14.0

* Rename ActionView::Component::Base to ViewComponent::Base

    *Joel Hawksley*

# v1.13.0

* Allow components to be rendered inside controllers.

    *Joel Hawksley*

* Improve backtraces from exceptions raised in templates.

    *Blake Williams*

# v1.12.0

* Revert: Remove initializer requirement for Ruby 2.7+

    *Joel Hawksley*

* Restructure Railtie into Engine

    *Sean Doyle*

* Allow components to override before_render_check

    *Joel Hawksley*

# v1.11.1

* Relax Capybara requirement.

    *Joel Hawksley*

# v1.11.0

* Add support for Capybara matchers.

    *Joel Hawksley*

* Add erb, haml, & slim template generators

    *Asger Behncke Jacobsen*

# v1.10.0

* Deprecate all `render` syntaxes except for `render(MyComponent.new(foo: :bar))`

    *Joel Hawksley*

# v1.9.0

* Remove initializer requirement for Ruby 2.7+

    *Dylan Clark*

# v1.8.1

* Run validation checks before calling `#render?`.

    *Ash Wilson*

# v1.8.0

* Remove the unneeded ComponentExamplesController and simplify preview rendering.

    *Jon Palmer*

* Add `#render?` hook to easily allow components to be no-ops.

    *Kyle Fox*

* Don't assume ApplicationController exists.

    *Jon Palmer*

* Allow some additional checks to overrided render?

    *Sergey Malykh*

* Fix generator placing namespaced components in the root directory.

    *Asger Behncke Jacobsen*

* Fix cache test.

    *Sergey Malykh*

# v1.7.0

* Simplify validation of templates and compilation.

    *Jon Palmer*

* Add support for multiple content areas.

    *Jon Palmer*

# v1.6.2

* Fix Uninitialized Constant error.

    *Jon Palmer*

* Add basic github issue and PR templates.

    *Dylan Clark*

* Update readme phrasing around previews.

    *Justin Coyne*

# v1.6.1

* Allow Previews to have no layout.

    *Jon Palmer*

* Bump rack from 2.0.7 to 2.0.8.

    *Dependabot*

* Compile components on application boot when eager loading is enabled.

    *Joel Hawksley*

* Previews support content blocks.

    *Cesario Uy*

* Follow Rails conventions. (refactor)

    *Rainer Borene*

* Fix edge case issue with extracting variants from less conventional source_locations.

    *Ryan Workman*

# v1.6.0

* Avoid dropping elements in the render_inline test helper.

    *@dark-panda*

* Add test for helpers.asset_url.

    *Christopher Coleman*

* Add rudimentary compatibility with better_html.

    *Joel Hawksley*

* Template-less variants fall back to default template.

    *Asger Behncke Jacobsen*, *Cesario Uy*

* Generated tests use new naming convention.

    *Simon Træls Ravn*

* Eliminate sqlite dependency.

    *Simon Dawson*

* Add support for rendering components via #to_component_class

    *Vinicius Stock*

# v1.5.3

* Add support for RSpec to generators.

    *Dylan Clark, Ryan Workman*

* Require controllers as part of setting autoload paths.

    *Joel Hawksley*

# v1.5.2

* Disable eager loading initializer.

    *Kasper Meyer*

# v1.5.1

* Update railties class to work with Rails 6.

    *Juan Manuel Ramallo*

# v1.5.0

Note: `actionview-component` is now loaded by requiring `actionview/component`, not `actionview/component/base`.

* Fix issue with generating component method signatures.

    *Ryan Workman, Dylan Clark*

* Create component generator.

    *Vinicius Stock*

* Add helpers proxy.

    *Kasper Meyer*

* Introduce ActionView::Component::Previews.

    *Juan Manuel Ramallo*

# v1.4.0

* Fix bug where components broke in application paths with periods.

    *Anton, Joel Hawksley*

* Add support for `cache_if` in component templates.

    *Aaron Patterson, Joel Hawksley*

* Add support for variants.

    *Juan Manuel Ramallo*

* Fix bug in virtual path lookup.

    *Juan Manuel Ramallo*

* Preselect the rendered component in render_inline.

    *Elia Schito*

# v1.3.6

* Allow template file names without format.

    *Joel Hawksley*

* Add support for translations.

    *Juan Manuel Ramallo*

# v1.3.5

* Re-expose `controller` method.

    *Michael Emhofer, Joel Hawksley*

* Gem version numbers are now accessible through `ActionView::Component::VERSION`

    *Richard Macklin*

* Fix typo in README

    *ars moriendi*

# v1.3.4

* Template errors surface correct file and line number.

    *Justin Coyne*

* Allow access to `request` inside components.

    *Joel Hawksley*

# v1.3.3

*   Do not raise error when sidecar files that are not templates exist.

    *Joel Hawksley*

# v1.3.2

*   Support rendering views from inside component templates.

    *Patrick Sinclair*

# v1.3.1

*   Fix bug where rendering nested content caused an error.

    *Joel Hawksley, Aaron Patterson*

# v1.3.0

*   Components are rendered with enough controller context to support rendering of partials and forms.

    *Patrick Sinclair, Joel Hawksley, Aaron Patterson*

# v1.2.1

*   `actionview-component` is now tested against Ruby 2.3/2.4 and Rails 5.0.0.

# v1.2.0

*   The `render_component` test helper has been renamed to `render_inline`. `render_component` has been deprecated and will be removed in v2.0.0.

    *Joel Hawksley*

*   Components are now rendered with `render MyComponent, foo: :bar` syntax. The existing `render MyComponent.new(foo: :bar)` syntax has been deprecated and will be removed in v2.0.0.

    *Joel Hawksley*

# v1.1.0

*   Components now inherit from ActionView::Component::Base

    *Joel Hawksley*

# v1.0.1

*   Always recompile component templates outside production.

    *Joel Hawksley, John Hawthorn*

# v1.0.0

This release extracts the `ActionView::Component` library from the GitHub application.

It will be published on RubyGems under the existing `actionview-component` gem name, as @chancancode has passed us ownership of the gem.
