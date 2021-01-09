# CHANGELOG

## main

## 2.24.0

- Add `--inline` option to the erb generator. Prevents default erb template from being created.

  _Nachiket Pusalkar_

- Add test case for checking presence of `content` in `#render?`.

  _Joel Hawksley_

- Rename `master` branch to `main`.

  _Joel Hawksley_

## 2.23.2

- Fix bug where rendering a component `with_collection` from a controller raised an error.

  _Joel Hawksley_

## 2.23.1

- Fixed out-of-order rendering bug in `ActionView::SlotableV2`

  _Blake Williams_

## 2.23.0

- Add `ActionView::SlotableV2`

  - `with_slot` becomes `renders_one`.
  - `with_slot collection: true` becomes `renders_many`.
  - Slot definitions now accept either a component class, component class name, or a lambda instead of a `class_name:` keyword argument.
  - Slots now support positional arguments.
  - Slots no longer use the `content` attribute to render content, instead relying on `to_s`. e.g. `<%= my_slot %>`.
  - Slot values are no longer set via the `slot` method, and instead use the name of the slot.

    _Blake Williams_

- Add `frozen_string_literal: true` to generated component template.

  _Max Beizer_

## 2.22.1

- Revert refactor that broke rendering for some users.

  _Joel Hawksley_

## 2.22.0

- Add #with_variant to enable inline component variant rendering without template files.

  _Nathan Jones_

## 2.21.0

- Only compile components at application initialization if eager loading is enabled.

  _Joel Hawksley_

## 2.20.0

- Don't add `/test/components/previews` to preview_paths if directory doesn't exist.

  _Andy Holland_

- Add `preview_controller` option to override the controller used for component previews.

  _Matt Swanson, Blake Williams, Juan Manuel Ramallo_

## 2.19.1

- Check if `Rails.application` is loaded.

  _Gleydson Tavares_

- Add documentation for webpack configuration when using Stimulus controllers.

  _Ciprian Redinciuc_

## 2.19.0

- Extend documentation for using Stimulus within sidecar directories.

  _Ciprian Redinciuc_

- Subclassed components inherit templates from parent.

  _Blake Williams_

- Fix uninitialized constant error from `with_collection` when `eager_load` is disabled.

  _Josh Gross_

## 2.18.2

- Raise an error if controller or view context is accessed during initialize as they are only available in render.

  _Julian Nadeau_

- Collate test coverage across CI builds, ensuring 100% test coverage.

  _Joel Hawksley_

## 2.18.1

- Fix bug where previews didn't work when monkey patch was disabled.

  _Mixer Gutierrez_

## 2.18.0

- Fix auto-loading of previews (changes no longer require a server restart)

  _Matt Brictson_

- Add `default_preview_layout` configuration option to load custom app/views/layouts.

  _Jared White, Juan Manuel Ramallo_

- Calculate virtual_path once for all instances of a component class to improve performance.

  _Brad Parker_

## 2.17.1

- Fix bug where rendering Slot with empty block resulted in error.

  _Joel Hawksley_

## 2.17.0

- Slots return stripped HTML, removing leading and trailing whitespace.

  _Jason Long, Joel Hawksley_

## 2.16.0

- Add `--sidecar` option to the erb, haml and slim generators. Places the generated template in the sidecar directory.

  _Michael van Rooijen_

## 2.15.0

- Add support for templates as ViewComponent::Preview examples.

  \*Juan Manuel Ramallo

## 2.14.1

- Allow using `render_inline` in test when the render monkey patch is disabled with `config.view_component.render_monkey_patch_enabled = false` in versions of Rails < 6.1.

  _Clément Joubert_

- Fix kwargs warnings in slotable.

  Fixes:

  ```console
  view_component/lib/view_component/slotable.rb:98: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
  view_component/test/app/components/slots_component.rb:18: warning: The called method `initialize' is defined here
  ```

  _Eileen M. Uchitelle_

## 2.14.0

- Add `config.preview_paths` to support multiple locations of component preview files. Deprecate `config.preview_path`.

  _Tomas Celizna_

- Only print warning about a missing capybara dependency if the `DEBUG` environment variable is set.

  _Richard Macklin_

## 2.13.0

- Add the ability to disable the render monkey patch with `config.view_component.render_monkey_patch_enabled`. In versions of Rails < 6.1, add `render_component` and `render_component_to_string` methods which can be used for rendering components instead of `render`.

  _Johannes Engl_

## 2.12.0

- Implement Slots as potential successor to Content Areas.

  _Jens Ljungblad, Brian Bugh, Jon Palmer, Joel Hawksley_

## 2.11.1

- Fix kwarg warnings in Ruby 2.7.

  _Joel Hawksley_

## 2.11.0

- Ensure Rails configuration is available within components.

  _Trevor Broaddus_

- Fix bug where global Rails helpers are inaccessible from nested components. Before, `helpers` was pointing to parent component.

  _Franco Sebregondi_

## 2.10.0

- Raise an `ArgumentError` with a helpful message when Ruby cannot parse a component class.

  _Max Beizer_

## 2.9.0

- Cache components per-request in development, preventing unnecessary recompilation during a single request.

  _Felipe Sateler_

## 2.8.0

- Add `before_render`, deprecating `before_render_check`.

  _Joel Hawksley_

## 2.7.0

- Add `rendered_component` method to `ViewComponent::TestHelpers` which exposes the raw output of the rendered component.

  _Richard Macklin_

- Support sidecar directories for views and other assets.

  _Jon Palmer_

## 2.6.0

- Add `config.view_component.preview_route` to set the endpoint for component previews. By default `/rails/view_components` is used.

  _Juan Manuel Ramallo_

- Raise error when initializer omits with_collection_parameter.

  _Joel Hawksley_

## 2.5.1

- Compile component before rendering collection.

  _Rainer Borene_

## v2.5.0

- Add counter variables when rendering collections.

  _Frank S_

- Add the ability to access params from preview examples.

  _Fabio Cantoni_

## v2.4.0

- Add `#render_to_string` support.

  _Jarod Reid_

- Declare explicit dependency on `activesupport`.

  _Richard Macklin_

- Remove `autoload`s of internal modules (`Previewable`, `RenderMonkeyPatch`, `RenderingMonkeyPatch`).

  _Richard Macklin_

- Remove `capybara` dependency.

  _Richard Macklin_

## v2.3.0

- Allow using inline render method(s) defined on a parent.

  _Simon Rand_

- Fix bug where inline variant render methods would never be called.

  _Simon Rand_

- ViewComponent preview index views use Rails internal layout instead of application's layout

  _Juan Manuel Ramallo_

## v2.2.2

- Add `Base.format` for better compatibility with `ActionView::Template`.

  _Joel Hawksley_

## v2.2.1

- Fix bug where template could not be found if `inherited` was redefined.

  _Joel Hawksley_

## v2.2.0

- Add support for `config.action_view.annotate_template_file_names` (coming in Rails 6.1).

  _Joel Hawksley_

- Remove initializer requirement from the component.

  _Vasiliy Ermolovich_

## v2.1.0

- Support rendering collections (e.g., `render(MyComponent.with_collection(@items))`).

  _Tim Clem_

## v2.0.0

- Move to `ViewComponent` namespace, removing all references to `ActionView`.

  - The gem name is now `view_component`.
  - ViewComponent previews are now accessed at `/rails/view_components`.
  - ViewComponents can _only_ be rendered with the instance syntax: `render(MyComponent.new)`. Support for all other syntaxes has been removed.
  - ActiveModel::Validations have been removed. ViewComponent generators no longer include validations.
  - In Rails 6.1, no monkey patching is used.
  - `to_component_class` has been removed.
  - All gem configuration is now in `config.view_component`.

## v1.17.0

- Support Ruby 2.4 in CI.

  _Andrew Mason_

- ViewComponent generators do not not prompt for content requirement.

  _Joel Hawksley_

- Add post-install message that gem has been renamed to `view_component`.

  _Joel Hawksley_

## v1.16.0

- Add `refute_component_rendered` test helper.

  _Joel Hawksley_

- Check for Rails before invocation.

  _Dave Paola_

- Allow components to be rendered without a template file (aka inline component).

  _Rainer Borene_

## v1.15.0

- Re-introduce ActionView::Component::TestHelpers.

  _Joel Hawksley_

- Bypass monkey patch on Rails 6.1 builds.

  _Joel Hawksley_

- Make `ActionView::Helpers::TagHelper` available in Previews.

  ```ruby
  def with_html_content
    render(MyComponent.new) do
      tag.div do
        content_tag(:span, "Hello")
      end
    end
  end
  ```

  _Sean Doyle_

## v1.14.1

- Fix bug where generator created invalid test code.

  _Joel Hawksley_

## v1.14.0

- Rename ActionView::Component::Base to ViewComponent::Base

  _Joel Hawksley_

## v1.13.0

- Allow components to be rendered inside controllers.

  _Joel Hawksley_

- Improve backtraces from exceptions raised in templates.

  _Blake Williams_

## v1.12.0

- Revert: Remove initializer requirement for Ruby 2.7+

  _Joel Hawksley_

- Restructure Railtie into Engine

  _Sean Doyle_

- Allow components to override before_render_check

  _Joel Hawksley_

## v1.11.1

- Relax Capybara requirement.

  _Joel Hawksley_

## v1.11.0

- Add support for Capybara matchers.

  _Joel Hawksley_

- Add erb, haml, & slim template generators

  _Asger Behncke Jacobsen_

## v1.10.0

- Deprecate all `render` syntaxes except for `render(MyComponent.new(foo: :bar))`

  _Joel Hawksley_

## v1.9.0

- Remove initializer requirement for Ruby 2.7+

  _Dylan Clark_

## v1.8.1

- Run validation checks before calling `#render?`.

  _Ash Wilson_

## v1.8.0

- Remove the unneeded ComponentExamplesController and simplify preview rendering.

  _Jon Palmer_

- Add `#render?` hook to easily allow components to be no-ops.

  _Kyle Fox_

- Don't assume ApplicationController exists.

  _Jon Palmer_

- Allow some additional checks to overrided render?

  _Sergey Malykh_

- Fix generator placing namespaced components in the root directory.

  _Asger Behncke Jacobsen_

- Fix cache test.

  _Sergey Malykh_

## v1.7.0

- Simplify validation of templates and compilation.

  _Jon Palmer_

- Add support for multiple content areas.

  _Jon Palmer_

## v1.6.2

- Fix Uninitialized Constant error.

  _Jon Palmer_

- Add basic github issue and PR templates.

  _Dylan Clark_

- Update readme phrasing around previews.

  _Justin Coyne_

## v1.6.1

- Allow Previews to have no layout.

  _Jon Palmer_

- Bump rack from 2.0.7 to 2.0.8.

  _Dependabot_

- Compile components on application boot when eager loading is enabled.

  _Joel Hawksley_

- Previews support content blocks.

  _Cesario Uy_

- Follow Rails conventions. (refactor)

  _Rainer Borene_

- Fix edge case issue with extracting variants from less conventional source_locations.

  _Ryan Workman_

## v1.6.0

- Avoid dropping elements in the render_inline test helper.

  _@dark-panda_

- Add test for helpers.asset_url.

  _Christopher Coleman_

- Add rudimentary compatibility with better_html.

  _Joel Hawksley_

- Template-less variants fall back to default template.

  _Asger Behncke Jacobsen_, _Cesario Uy_

- Generated tests use new naming convention.

  _Simon Træls Ravn_

- Eliminate sqlite dependency.

  _Simon Dawson_

- Add support for rendering components via #to_component_class

  _Vinicius Stock_

## v1.5.3

- Add support for RSpec to generators.

  _Dylan Clark, Ryan Workman_

- Require controllers as part of setting autoload paths.

  _Joel Hawksley_

## v1.5.2

- Disable eager loading initializer.

  _Kasper Meyer_

## v1.5.1

- Update railties class to work with Rails 6.

  _Juan Manuel Ramallo_

## v1.5.0

Note: `actionview-component` is now loaded by requiring `actionview/component`, not `actionview/component/base`.

- Fix issue with generating component method signatures.

  _Ryan Workman, Dylan Clark_

- Create component generator.

  _Vinicius Stock_

- Add helpers proxy.

  _Kasper Meyer_

- Introduce ActionView::Component::Previews.

  _Juan Manuel Ramallo_

## v1.4.0

- Fix bug where components broke in application paths with periods.

  _Anton, Joel Hawksley_

- Add support for `cache_if` in component templates.

  _Aaron Patterson, Joel Hawksley_

- Add support for variants.

  _Juan Manuel Ramallo_

- Fix bug in virtual path lookup.

  _Juan Manuel Ramallo_

- Preselect the rendered component in render_inline.

  _Elia Schito_

## v1.3.6

- Allow template file names without format.

  _Joel Hawksley_

- Add support for translations.

  _Juan Manuel Ramallo_

## v1.3.5

- Re-expose `controller` method.

  _Michael Emhofer, Joel Hawksley_

- Gem version numbers are now accessible through `ActionView::Component::VERSION`

  _Richard Macklin_

- Fix typo in README

  _ars moriendi_

## v1.3.4

- Template errors surface correct file and line number.

  _Justin Coyne_

- Allow access to `request` inside components.

  _Joel Hawksley_

## v1.3.3

- Do not raise error when sidecar files that are not templates exist.

  _Joel Hawksley_

## v1.3.2

- Support rendering views from inside component templates.

  _Patrick Sinclair_

## v1.3.1

- Fix bug where rendering nested content caused an error.

  _Joel Hawksley, Aaron Patterson_

## v1.3.0

- Components are rendered with enough controller context to support rendering of partials and forms.

  _Patrick Sinclair, Joel Hawksley, Aaron Patterson_

## v1.2.1

- `actionview-component` is now tested against Ruby 2.3/2.4 and Rails 5.0.0.

## v1.2.0

- The `render_component` test helper has been renamed to `render_inline`. `render_component` has been deprecated and will be removed in v2.0.0.

  _Joel Hawksley_

- Components are now rendered with `render MyComponent, foo: :bar` syntax. The existing `render MyComponent.new(foo: :bar)` syntax has been deprecated and will be removed in v2.0.0.

  _Joel Hawksley_

## v1.1.0

- Components now inherit from ActionView::Component::Base

  _Joel Hawksley_

## v1.0.1

- Always recompile component templates outside production.

  _Joel Hawksley, John Hawthorn_

## v1.0.0

This release extracts the `ActionView::Component` library from the GitHub application.

It will be published on RubyGems under the existing `actionview-component` gem name, as @chancancode has passed us ownership of the gem.
