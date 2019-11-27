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
