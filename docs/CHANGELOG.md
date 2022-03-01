---
layout: default
title: Changelog
---

# Changelog

## main

* Support returning Arrays from i18n files, and support marking them as HTML-safe translations.

    *foca*

* Add Cometeer and Framework to users list.

    *Elia Schito*

* Update Microsoft Vale styles.

    *Simon Fish*

* Fix example in testing guide for how to setup default Rails tests.

    *Steven Hansen*

* Update benchmark script to render multiple components/partials instead of a single instance per-run.

    *Blake Williams*

* Add predicate methods `#{slot_name}?` to slots.

    *Hans Lemuet*

* Use a dedicated deprecation instance, silence it while testing.

    *Max Beizer, Hans Lemuet, Elia Schito*

* Fix Ruby warnings.

    *Hans Lemuet*

* Place all generator options under `config.generate` namespace.

    *Simon Fish*

* Allow preview generator to use provided component attributes.
* Add config option `config.view_component.generate.preview` to enable project-wide preview generation.
* Ensure all generated `.rb` files include `# frozen_string_literal: true` statement.

    *Bob Maerten*

* Add Shogun to users list.

    *Bernie Chiu*

## 2.49.0

* Fix path handling for evaluated view components that broke in Ruby 3.1.

    *Adam Hess*

* Fix support for the `default:` option for a global translation.

    *Elia Schito*

* Ensure i18n scope is a symbol to protect lookups.

    *Simon Fish*

* Small update to preview docs to include rspec mention.

    *Leigh Halliday*

* Small improvements to collection iteration docs.

    *Brian O'Rourke*

* Add good and bad examples to `ViewComponents in practice`.

    *Joel Hawksley*

* Add Ruby 3.1 and Rails 7.0 to CI

    *Peter Goldstein*

## 2.48.0

* Correct path in example test command in Contributing docs.

    *Mark Wilkinson*

* Update link to GOV.UK Components library in the resources list.

    *Peter Yates*

* Add Lookbook to Resources docs page.

    *Mark Perkins*

* Add blocking compiler mode for use in Rails development and testing modes, improving thread safety.

    *Horia Radu*

* Add generators to support `tailwindcss-rails`.

    *Dino Maric*, *Hans Lemuet*

* Add a namespaced component example to docs.

    *Hans Lemuet*

* Setup `Appraisal` to add flexibility when testing ViewComponent against multiple Rails versions.

    *Hans Lemuet*

* Return correct values for `request.path` and `request.query_string` methods when using the `with_request_url` test helper.

    *Vasiliy Matyushin*

* Improve style in generators docs.

    *Hans Lemuet*

* Correctly type Ruby version strings and update Rails versions used in CI configuration.

    *Hans Lemuet*

* Make `ViewComponent::Collection` act like a collection of view components.

    *Sammy Henningsson*

* Update `@param` of `#render_inline` to include `ViewComponent::Collection`.

    *Yutaka Kamei*

* Add Wecasa to users list.

    *Mohamed Ziata*

## 2.47.0

* Display preview source on previews that exclusively use templates.

    *Edwin Mak*

* Add a test to ensure trailing newlines are stripped when rendering with `#render_in`.

    *Simon Fish*

* Add WEBrick as a depenency to the application.

    *Connor McQuillan*

* Update Ruby version in `.tool-versions`.

    *Connor McQuillan*

* Add a test to ensure blocks can be passed into lambda slots without the need for any other arguments.

    *Simon Fish*

* Add linters for file consistency.

    *Simon Fish*

* Add @boardfish to docs/index.md and sort contributors.

    *Simon Fish*

* Set up Codespaces for bug replication.

    *Simon Fish*

* Add instructions for replicating bugs and failures.

    *Simon Fish*

* Make @boardfish a committer.

    *Joel Hawksley*

* Validate collection parameter with Active Model attribute names.

    *Simon Fish*

* Fix `helpers` not working with component slots when rendered more than 2 component levels deep.

    *Blake Williams*

* Update ruby to the latest versions

    *Pedro Paiva*

* Fix `vale` linter config options.

    *Hans Lemuet*

* Improve Contributing docs to include how to run tests for a specific version on Rails.

    *Hans Lemuet*

* Add failing test for default form builder and documentation around known issue.

    *Simon Fish*

* Add `--locale` flag to the component generator. Generates as many locale files as defined in `I18n.available_locales`, alongside the component.
* Add config option `config.view_component.generate_locale` to enable project-wide locale generation.
* Add config option `config.view_component.generate_distinct_locale_files` to enable project-wide per-locale translations file generation.

    *Bob Maerten*

* Add config option `config.view_component.generate_sidecar` to always generate in the sidecar directory.

    *Gleydson Tavares*

## 2.46.0

* Add thread safety to the compiler.

    *Horia Radu*

* Add theme-specific logo images to readme.

    *Dylan Smith*

* Add Orbit to users list.

    *Nicolas Goutay*

* Increase clarity around purpose and use of slots.

    *Simon Fish*

* Deprecate loading `view_component/engine` directly.

  **Upgrade notice**: You should update your `Gemfile` like this:

  ```diff
  - gem "view_component", require: "view_component/engine"`
  + gem "view_component"
  ```

    *Yoshiyuki Hirano*

## 2.45.0

* Remove internal APIs from API documentation, fix link to license.

    *Joel Hawksley*

* Add @yhirano55 to triage team.

    *Joel Hawksley*

* Correct a typo in the sample slots code.

    *Simon Fish*

* Add note about `allowed_queries`.

    *Joel Hawksley*

* Add `vale` content linter.

    *Joel Hawksley*

* Remove `require "rails/generators/test_case"` in generator tests.

    *Yoshiyuki Hirano*

* Suppress zeitwerk warning about circular require.

    *Yoshiyuki Hirano*

* Move `test_unit_generator_test.rb` from `test/view_component/` to `test/generators/`.

    *Yoshiyuki Hirano*

* Unify test code of `TestUnitGeneratorTest` with the other generators tests.

    *Yoshiyuki Hirano*

## 2.44.0

* Rename internal accessor to use private naming.

    *Joel Hawksley*, *Blake Williams*, *Cameron Dutro*

* Add Github repo link to docs website header.

    *Hans Lemuet*

* Change logo in README for dark theme readability.

    *Dylan Smith*

* Add Litmus to users list.

    *Dylan Smith*

* Add @dylanatsmith as codeowner of the ViewComponent logo and member of committers team.

    *Joel Hawksley*

* Autoload `CompileCache`, which is optionally called in `engine.rb`.

    *Gregory Igelmund*

* Move frequently asked questions to other pages, add History page.

    *Joel Hawksley*

* Fix typo.

    *James Hart*

* Add `require "method_source"` if it options.show_previews_source is enabled.

    *Yoshiyuki Hirano*

* Move show_previews_source definition to Previewable.

    *Yoshiyuki Hirano*

* Clear cache in MethodSource to apply the change odf preview code without app server restart.

    *Yoshiyuki Hirano*

## 2.43.1

* Remove unnecessary call to `ruby2_keywords` for polymorphic slot getters.

    *Cameron Dutro*

## 2.43.0

* Add note about tests and instance methods.

    *Joel Hawksley*

* Flesh out `ViewComponents in practice`.

    *Joel Hawksley*

* Add CODEOWNERS entries for feature areas owned by community committers.

    *Joel Hawksley*

* Separate lint and CI workflows.

    *Blake Williams*

* Add support for `image_path` helper in previews.

    *Tobias Ahlin*, *Joel Hawksley*

* Add section to docs listing users of ViewComponent. Please submit a PR to add your team to the list!

    *Joel Hawksley*

* Fix loading issue with Stimulus generator and add specs for Stimulus generator.

    *Peter Sumskas*

* Remove dependency on `ActionDispatch::Static` in Rails middleware stack when enabling statics assets for source code preview.

    *Gregory Igelmund*

* Require `view_component/engine` automatically.

    *Cameron Dutro*

## 2.42.0

* Add logo files and page to docs.

    *Dylan Smith*

* Add `ViewComponents in practice` documentation.

    *Joel Hawksley*

* Fix bug where calling lambda slots without arguments would break in Ruby < 2.7.

    *Manuel Puyol*

* Improve Stimulus controller template to import from `stimulus` or `@hotwired/stimulus`.

    *Mario Schüttel*

* Fix bug where `helpers` would instantiate and use a new `view_context` in each component.

    *Blake Williams*, *Ian C. Anderson*

* Implement polymorphic slots as experimental feature. See the Slots documentation to learn more.

    *Cameron Dutro*

## 2.41.0

* Add `sprockets-rails` development dependency to fix test suite failures when using rails@main.

    *Blake Williams*

* Fix Ruby indentation warning.

    *Blake Williams*

* Add `--parent` generator option to specify the parent class.
* Add config option `config.view_component.component_parent_class` to change it project-wide.

    *Hans Lemuet*

* Update docs to add example for using Devise helpers in tests.

    *Matthew Rider*

* Fix bug where `with_collection_parameter` didn't inherit from parent component.

    *Will Drexler*, *Christian Campoli*

* Allow query parameters in `with_request_url` test helper.

    *Javi Martín*

* Add "how to render a component to a string" to FAQ.

    *Hans Lemuet*

* Add `#render_in` to API docs.

    *Hans Lemuet*

* Forward keyword arguments from slot wrapper to component instance using ruby2_keywords.

    *Cameron Dutro*

## 2.40.0

* Replace antipatterns section in the documentation with best practices.

    *Blake Williams*

* Add components to `rails stats` task.

    *Nicolas Brousse*

* Fix bug when using Slim and writing a slot whose block evaluates to `nil`.

    *Yousuf Jukaku*

* Add documentation for test helpers.

    *Joel Hawksley*

## 2.39.0

* Clarify documentation of `with_variant` as an override of Action Pack.

    *Blake Williams*, *Cameron Dutro*, *Joel Hawksley*

* Update docs page to be called Javascript and CSS, rename Building ViewComponents to Guide.

    *Joel Hawksley*

* Deprecate `Base#with_variant`.

    *Cameron Dutro*

* Error out in the CI if docs/api.md has to be regenerated.

    *Dany Marcoux*

## 2.38.0

* Add `--stimulus` flag to the component generator. Generates a Stimulus controller alongside the component.
* Add config option `config.view_component.generate_stimulus_controller` to always generate a Stimulus controller.

    *Sebastien Auriault*

## 2.37.0

* Clarify slots example in docs to reduce naming confusion.

    *Joel Hawksley*, *Blake Williams*

* Fix error in documentation for `render_many` passthrough slots.

    *Ollie Nye*

* Add test case for conflict with internal `@variant` variable.

    *David Backeus*

* Document decision to not change naming convention recommendation to remove `-Component` suffix.

    *Joel Hawksley*

* Fix typo in documentation.

    *Ryo.gift*

* Add inline template example to benchmark script.

    *Andrew Tait*

* Fix benchmark scripts.

    *Andrew Tait*

* Run benchmarks in CI.

    *Joel Hawksley*

## 2.36.0

* Add `slot_type` helper method.

    *Jon Palmer*

* Add test case for rendering a ViewComponent with slots in a controller.

    *Simon Fish*

* Add example ViewComponent to documentation landing page.

    *Joel Hawksley*

* Set maximum line length to 120.

    *Joel Hawksley*

* Setting a collection slot with the plural setter (`component.items(array)` for `renders_many :items`)  returns the array of slots.

    *Jon Palmer*

* Update error messages to be more descriptive and helpful.

    *Joel Hawksley*

* Raise an error if the slot name for renders_many is :contents

    *Simon Fish*

## 2.35.0

* Only load assets for Preview source highlighting if previews are enabled.

    *Joel Hawksley*

* Fix references to moved documentation files.

    *Richard Macklin*

* Ensure consistent indentation with Rubocop.

    *Joel Hawksley*

* Bump `activesupport` upper bound from `< 7.0` to `< 8.0`.

    *Richard Macklin*

* Add ERB Lint for a few basic rules.

    *Joel Hawksley*

* Sort `gemspec` dependencies alphabetically.

    *Joel Hawksley*

* Lock `method_source` at `1.0` to avoid open-ended dependency.

    *Joel Hawksley*

* Require all PRs to include changelog entries.

    *Joel Hawksley*

* Rename test app and move files under /test/sandbox.

    *Matt-Yorkley*

* Make view_component_path config option available on ViewComponent::Base.

    *Matt-Yorkley*

* Add @boardfish to Triage.

    *Joel Hawksley*

* Adds support to change default components path (app/components) with `config.view_component.view_component_path`.

    *lfalcao*

* Rename private instance variables (such as @variant) to reduce potential conflicts with subclasses.

    *Joel Hawksley*

* Add documentation for configuration options.

    *Joel Hawksley*

* Add view helper `preview_source` for rendering a source code preview below previews.
* Add config option `config.view_component.show_previews_source` for enabling the source preview.

    *Johannes Engl*

* Add documentation for compatibility with ActionText.

    *Jared Planter*

## 2.34.0

* Add the ability to enable ActiveSupport notifications (`!render.view_component` event) with `config.view_component.instrumentation_enabled`.

    *Svyatoslav Kryukov*

* Add [Generators](https://viewcomponent.org/guide/generators.html) page to documentation.

    *Hans Lemuet*

* Fix bug where ViewComponents didn't work in ActionMailers.

    *dark-panda*

## 2.33.0

* Add support for `_iteration` parameter when rendering in a collection

    *Will Cosgrove*

* Don't raise an error when rendering empty components.

    *Alex Robbin*

## 2.32.0

* Enable previews by default in test environment.

    *Edouard Piron*

* Fix test helper compatibility with Rails 7.0, TestRequest, and TestSession.

    *Leo Correa*

* Add experimental `_output_postamble` lifecyle method.

    *Joel Hawksley*

* Add compatibility notes on FAQ.

    *Matheus Richard*

* Add Bridgetown on Compatibility documentation.

    *Matheus Richard*

* Are you interested in building the future of ViewComponent? GitHub is looking to hire a Senior Engineer to work on Primer ViewComponents and ViewComponent. Apply here: [US/Canada](https://github.com/careers) / [Europe](https://boards.greenhouse.io/github/jobs/3132294). Feel free to reach out to joelhawksley@github.com with any questions.

    *Joel Hawksley*

## 2.31.1

* Fix `DEPRECATION WARNING: before_render_check` when compiling `ViewComponent::Base`

    *Dave Kroondyk*

## 2.31.0

_Note: This release includes an underlying change to Slots that may affect incorrect usage of the API, where Slots were set on a line prefixed by `<%=`. The result of setting a Slot shouldn't be returned. (`<%`)_

* Add `#with_content` to allow setting content without a block.

    *Jordan Raine, Manuel Puyol*

* Add `with_request_url` test helper.

    *Mario Schüttel*

* Improve feature parity with Rails translations
  * Don't create a translation back end if the component has no translation file
  * Mark translation keys ending with `html` as HTML-safe
  * Always convert keys to String
  * Support multiple keys

    *Elia Schito*

* Fix errors on `asset_url` helpers when `asset_host` has no protocol.

    *Elia Schito*

* Prevent slots from overriding the `#content` method when registering a slot with that name.

    *Blake Williams*

* Deprecate `with_slot` in favor of the new [slots API](https://viewcomponent.org/guide/slots.html).

    *Manuel Puyol*

## 2.30.0

* Deprecate `with_content_areas` in favor of [slots](https://viewcomponent.org/guide/slots.html).

    *Joel Hawksley*

## 2.29.0

* Allow Slot lambdas to share data from the parent component and allow chaining on the returned component.

    *Sjors Baltus, Blake Williams*

* Experimental: Add `ViewComponent::Translatable`
  * `t` and `translate` now will look first into the sidecar YAML translations file.
  * `helpers.t` and `I18n.t` still reference the global Rails translation files.
  * `l` and `localize` will still reference the global Rails translation files.

    *Elia Schito*

* Fix rendering output of pass through slots when using HAML.

    *Alex Robbin, Blake Williams*

* Experimental: call `._sidecar_files` to fetch the sidecar files for a given list of extensions, for example passing `["yml", "yaml"]`.

    *Elia Schito*

* Fix bug where a single `jbuilder` template matched multiple template handlers.

    *Niels Slot*

## 2.28.0

* Include SlotableV2 by default in Base. **Note:** It's no longer necessary to include `ViewComponent::SlotableV2` to use Slots.

    *Joel Hawksley*

* Prepend Preview routes instead of appending, accounting for cases where host application has catchall route.

    *Joel Hawksley*

* Fix bug where blocks passed to lambda slots will render incorrectly in certain situations.

    *Blake Williams*

## 2.27.0

* Allow customization of the controller used in component tests.

    *Alex Robbin*

* Generate preview at overridden path if one exists when using `--preview` flag.

    *Nishiki Liu*

## 2.26.1

* Fix bug that raises when trying to use a collection before the component has been compiled.

    *Blake Williams*

## 2.26.0

* Delay evaluating component `content` in `render?`, preventing the `content` block from being evaluated when `render?` returns false.

    *Blake Williams*

* Don't generate template when using `--inline` flag.

    *Hans Lemuet*

* Add `--inline` option to the Haml and Slim generators

    *Hans Lemuet*

## 2.25.1

* Experimental: call `._after_compile` class method after a component is compiled.

    *Joel Hawksley*

* Fix bug where SlotV2 was rendered as an HTML string when using Slim.

    *Manuel Puyol*

## 2.25.0

* Add `--preview` generator option to create an associated preview file.

    *Bob Maerten*

* Add argument validation to avoid `content` override.

    *Manuel Puyol*

## 2.24.0

* Add `--inline` option to the erb generator. Prevents default erb template from being created and creates a component with a call method.

    *Nachiket Pusalkar*

* Add test case for checking presence of `content` in `#render?`.

    *Joel Hawksley*

* Rename `master` branch to `main`.

    *Joel Hawksley*

## 2.23.2

* Fix bug where rendering a component `with_collection` from a controller raised an error.

    *Joel Hawksley*

## 2.23.1

* Fixed out-of-order rendering bug in `ActionView::SlotableV2`

    *Blake Williams*

## 2.23.0

* Add `ActionView::SlotableV2`
  * `with_slot` becomes `renders_one`.
  * `with_slot collection: true` becomes `renders_many`.
  * Slot definitions now accept either a component class, component class name, or a lambda instead of a `class_name:` keyword argument.
  * Slots now support positional arguments.
  * Slots no longer use the `content` attribute to render content, instead relying on `to_s`. for example `<%= my_slot %>`.
  * Slot values are no longer set via the `slot` method, and instead use the name of the slot.

    *Blake Williams*

* Add `frozen_string_literal: true` to generated component template.

    *Max Beizer*

## 2.22.1

* Revert refactor that broke rendering for some users.

    *Joel Hawksley*

## 2.22.0

* Add #with_variant to enable inline component variant rendering without template files.

    *Nathan Jones*

## 2.21.0

* Only compile components at application initialization if eager loading is enabled.

    *Joel Hawksley*

## 2.20.0

* Don't add `/test/components/previews` to preview_paths if directory doesn't exist.

    *Andy Holland*

* Add `preview_controller` option to override the controller used for component previews.

    *Matt Swanson, Blake Williams, Juan Manuel Ramallo*

## 2.19.1

* Check if `Rails.application` is loaded.

    *Gleydson Tavares*

* Add documentation for webpack configuration when using Stimulus controllers.

    *Ciprian Redinciuc*

## 2.19.0

* Extend documentation for using Stimulus within sidecar directories.

    *Ciprian Redinciuc*

* Subclassed components inherit templates from parent.

    *Blake Williams*

* Fix uninitialized constant error from `with_collection` when `eager_load` is disabled.

    *Josh Gross*

## 2.18.2

* Raise an error if controller or view context is accessed during initialize as they're only available in render.

    *Julian Nadeau*

* Collate test coverage across CI builds, ensuring 100% test coverage.

    *Joel Hawksley*

## 2.18.1

* Fix bug where previews didn't work when monkey patch was disabled.

    *Mixer Gutierrez*

## 2.18.0

* Fix auto loading of previews (changes no longer require a server restart)

    *Matt Brictson*

* Add `default_preview_layout` configuration option to load custom app/views/layouts.

    *Jared White, Juan Manuel Ramallo*

* Calculate virtual_path once for all instances of a component class to improve performance.

    *Brad Parker*

## 2.17.1

* Fix bug where rendering Slot with empty block resulted in error.

    *Joel Hawksley*

## 2.17.0

* Slots return stripped HTML, removing leading and trailing whitespace.

    *Jason Long, Joel Hawksley*

## 2.16.0

* Add `--sidecar` option to the erb, haml and slim generators. Places the generated template in the sidecar directory.

    *Michael van Rooijen*

## 2.15.0

* Add support for templates as ViewComponent::Preview examples.

    *Juan Manuel Ramallo

## 2.14.1

* Allow using `render_inline` in test when the render monkey patch is disabled with `config.view_component.render_monkey_patch_enabled = false` in versions of Rails < 6.1.

    *Clément Joubert*

* Fix kwargs warnings in slotable.

    Fixes:

    ```console
    view_component/lib/view_component/slotable.rb:98: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
    view_component/test/app/components/slots_component.rb:18: warning: The called method `initialize' is defined here
    ```

    *Eileen M. Uchitelle*

## 2.14.0

* Add `config.preview_paths` to support multiple locations of component preview files. Deprecate `config.preview_path`.

    *Tomas Celizna*

* Only print warning about a missing capybara dependency if the `DEBUG` environment variable is set.

    *Richard Macklin*

## 2.13.0

* Add the ability to disable the render monkey patch with `config.view_component.render_monkey_patch_enabled`. In versions of Rails < 6.1, add `render_component` and `render_component_to_string` methods which can be used for rendering components instead of `render`.

    *Johannes Engl*

## 2.12.0

* Implement Slots as potential successor to Content Areas.

    *Jens Ljungblad, Brian Bugh, Jon Palmer, Joel Hawksley*

## 2.11.1

* Fix kwarg warnings in Ruby 2.7.

    *Joel Hawksley*

## 2.11.0

* Ensure Rails configuration is available within components.

    *Trevor Broaddus*

* Fix bug where global Rails helpers are inaccessible from nested components. Before, `helpers` was pointing to parent component.

    *Franco Sebregondi*

## 2.10.0

* Raise an `ArgumentError` with a helpful message when Ruby can't parse a component class.

    *Max Beizer*

## 2.9.0

* Cache components per-request in development, preventing unnecessary recompilation during a single request.

    *Felipe Sateler*

## 2.8.0

* Add `before_render`, deprecating `before_render_check`.

    *Joel Hawksley*

## 2.7.0

* Add `rendered_component` method to `ViewComponent::TestHelpers` which exposes the raw output of the rendered component.

    *Richard Macklin*

* Support sidecar directories for views and other assets.

    *Jon Palmer*

## 2.6.0

* Add `config.view_component.preview_route` to set the endpoint for component previews. By default `/rails/view_components` is used.

    *Juan Manuel Ramallo*

* Raise error when initializer omits with_collection_parameter.

    *Joel Hawksley*

## 2.5.1

* Compile component before rendering collection.

    *Rainer Borene*

## v2.5.0

* Add counter variables when rendering collections.

    *Frank S*

* Add the ability to access params from preview examples.

    *Fabio Cantoni*

## v2.4.0

* Add `#render_to_string` support.

   *Jarod Reid*

* Declare explicit dependency on `activesupport`.

    *Richard Macklin*

* Remove `autoload`s of internal modules (`Previewable`, `RenderMonkeyPatch`, `RenderingMonkeyPatch`).

    *Richard Macklin*

* Remove `capybara` dependency.

    *Richard Macklin*

## v2.3.0

* Allow using inline render method(s) defined on a parent.

    *Simon Rand*

* Fix bug where inline variant render methods would never be called.

    *Simon Rand*

* ViewComponent preview index views use Rails internal layout instead of application's layout

    *Juan Manuel Ramallo*

## v2.2.2

* Add `Base.format` for better compatibility with `ActionView::Template`.

    *Joel Hawksley*

## v2.2.1

* Fix bug where template couldn't be found if `inherited` was redefined.

    *Joel Hawksley*

## v2.2.0

* Add support for `config.action_view.annotate_template_file_names` (coming in Rails 6.1).

    *Joel Hawksley*

* Remove initializer requirement from the component.

    *Vasiliy Ermolovich*

## v2.1.0

* Support rendering collections (for example, `render(MyComponent.with_collection(@items))`).

    *Tim Clem*

## v2.0.0

* Move to `ViewComponent` namespace, removing all references to `ActionView`.

  * The gem name is now `view_component`.
  * ViewComponent previews are now accessed at `/rails/view_components`.
  * ViewComponents can _only_ be rendered with the instance syntax: `render(MyComponent.new)`. Support for all other syntaxes has been removed.
  * ActiveModel::Validations have been removed. ViewComponent generators no longer include validations.
  * In Rails 6.1, no monkey patching is used.
  * `to_component_class` has been removed.
  * All gem configuration is now in `config.view_component`.

## v1.17.0

* Support Ruby 2.4 in CI.

    *Andrew Mason*

* ViewComponent generators don't not prompt for content requirement.

    *Joel Hawksley*

* Add post-install message that gem has been renamed to `view_component`.

    *Joel Hawksley*

## v1.16.0

* Add `refute_component_rendered` test helper.

    *Joel Hawksley*

* Check for Rails before invocation.

    *Dave Paola*

* Allow components to be rendered without a template file (aka inline component).

    *Rainer Borene*

## v1.15.0

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

## v1.14.1

* Fix bug where generator created invalid test code.

    *Joel Hawksley*

## v1.14.0

* Rename ActionView::Component::Base to ViewComponent::Base

    *Joel Hawksley*

## v1.13.0

* Allow components to be rendered inside controllers.

    *Joel Hawksley*

* Improve backtraces from exceptions raised in templates.

    *Blake Williams*

## v1.12.0

* Revert: Remove initializer requirement for Ruby 2.7+

    *Joel Hawksley*

* Restructure Railtie into Engine

    *Sean Doyle*

* Allow components to override before_render_check

    *Joel Hawksley*

## v1.11.1

* Relax Capybara requirement.

    *Joel Hawksley*

## v1.11.0

* Add support for Capybara matchers.

    *Joel Hawksley*

* Add erb, haml, & slim template generators

    *Asger Behncke Jacobsen*

## v1.10.0

* Deprecate all `render` syntaxes except for `render(MyComponent.new(foo: :bar))`

    *Joel Hawksley*

## v1.9.0

* Remove initializer requirement for Ruby 2.7+

    *Dylan Clark*

## v1.8.1

* Run validation checks before calling `#render?`.

    *Ash Wilson*

## v1.8.0

* Remove the unneeded ComponentExamplesController and simplify preview rendering.

    *Jon Palmer*

* Add `#render?` hook to allow components to be no-ops.

    *Kyle Fox*

* Don't assume ApplicationController exists.

    *Jon Palmer*

* Allow some additional checks to overrided render?

    *Sergey Malykh*

* Fix generator placing namespaced components in the root directory.

    *Asger Behncke Jacobsen*

* Fix cache test.

    *Sergey Malykh*

## v1.7.0

* Simplify validation of templates and compilation.

    *Jon Palmer*

* Add support for multiple content areas.

    *Jon Palmer*

## v1.6.2

* Fix Uninitialized Constant error.

    *Jon Palmer*

* Add basic github issue and PR templates.

    *Dylan Clark*

* Update readme phrasing around previews.

    *Justin Coyne*

## v1.6.1

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

<!-- vale proselint.GenderBias = NO -->
    *Ryan Workman*
<!-- vale proselint.GenderBias = YES -->

## v1.6.0

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

## v1.5.3

* Add support for RSpec to generators.

<!-- vale proselint.GenderBias = NO -->
    *Dylan Clark, Ryan Workman*
<!-- vale proselint.GenderBias = YES -->

* Require controllers as part of setting autoload paths.

    *Joel Hawksley*

## v1.5.2

* Disable eager loading initializer.

    *Kasper Meyer*

## v1.5.1

* Update railties class to work with Rails 6.

    *Juan Manuel Ramallo*

## v1.5.0

Note: `actionview-component` is now loaded by requiring `actionview/component`, not `actionview/component/base`.

* Fix issue with generating component method signatures.

<!-- vale proselint.GenderBias = NO -->
    *Ryan Workman, Dylan Clark*
<!-- vale proselint.GenderBias = YES -->

* Create component generator.

    *Vinicius Stock*

* Add helpers proxy.

    *Kasper Meyer*

* Introduce ActionView::Component::Previews.

    *Juan Manuel Ramallo*

## v1.4.0

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

## v1.3.6

* Allow template file names without format.

    *Joel Hawksley*

* Add support for translations.

    *Juan Manuel Ramallo*

## v1.3.5

* Re-expose `controller` method.

    *Michael Emhofer, Joel Hawksley*

* Gem version numbers are now accessible through `ActionView::Component::VERSION`

    *Richard Macklin*

* Fix typo in README

    *ars moriendi*

## v1.3.4

* Template errors surface correct file and line number.

    *Justin Coyne*

* Allow access to `request` inside components.

    *Joel Hawksley*

## v1.3.3

* Don't raise error when sidecar files that aren't templates exist.

    *Joel Hawksley*

## v1.3.2

* Support rendering views from inside component templates.

    *Patrick Sinclair*

## v1.3.1

* Fix bug where rendering nested content caused an error.

    *Joel Hawksley, Aaron Patterson*

## v1.3.0

* Components are rendered with enough controller context to support rendering of partials and forms.

    *Patrick Sinclair, Joel Hawksley, Aaron Patterson*

## v1.2.1

* `actionview-component` is now tested against Ruby 2.3/2.4 and Rails 5.0.0.

## v1.2.0

* The `render_component` test helper has been renamed to `render_inline`. `render_component` has been deprecated and will be removed in v2.0.0.

    *Joel Hawksley*

* Components are now rendered with `render MyComponent, foo: :bar` syntax. The existing `render MyComponent.new(foo: :bar)` syntax has been deprecated and will be removed in v2.0.0.

    *Joel Hawksley*

## v1.1.0

* Components now inherit from ActionView::Component::Base

    *Joel Hawksley*

## v1.0.1

* Always recompile component templates outside production.

    *Joel Hawksley, John Hawthorn*

## v1.0.0

This release extracts the `ActionView::Component` library from the GitHub application.

It will be published on RubyGems under the existing `actionview-component` gem name, as @chancancode has passed us ownership of the gem.
