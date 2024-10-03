---
layout: default
title: Generators
parent: How-to guide
---

# Generators

The generator accepts a component name and a list of arguments.

To create an `ExampleComponent` with `title` and `content` attributes:

```console
bin/rails generate component Example title content

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
      create    app/components/example_component.html.erb
```

## Generating namespaced components

To generate a namespaced `Sections::ExampleComponent`:

```console
bin/rails generate component Sections::Example title content

      create  app/components/sections/example_component.rb
      invoke  test_unit
      create    test/components/sections/example_component_test.rb
      invoke  erb
      create    app/components/sections/example_component.html.erb
```

## Options

You can specify options when running the generator. To alter the default values project-wide, define the configuration settings described in [API docs](/api.html#configuration).

Generated ViewComponents are added to `app/components` by default. Set `config.view_component.view_component_path` to use a different path. Note that you need to add the same path to `config.eager_load_paths` as well.

```ruby
# config/application.rb
config.view_component.view_component_path = "app/views/components"
config.eager_load_paths << Rails.root.join("app/views/components")
```

### Override template engine

ViewComponent includes template generators for the `erb`, `haml`, and `slim` template engines and will default to the template engine specified in `config.generators.template_engine`.

```console
bin/rails generate component Example title --template-engine slim

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  slim
      create    app/components/example_component.html.slim
```

### Override test framework

By default, `config.generators.test_framework` is used.

```console
bin/rails generate component Example title --test-framework rspec

      create  app/components/example_component.rb
      invoke  rspec
      create    spec/components/example_component_spec.rb
      invoke  erb
      create    app/components/example_component.html.erb
```

### Generate a [preview](/guide/previews.html)

Since 2.25.0
{: .label }

```console
bin/rails generate component Example title --preview

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  preview
      create    test/components/previews/example_component_preview.rb
      invoke  erb
      create    app/components/example_component.html.erb
```

### Generate a [Stimulus controller](/guide/javascript_and_css.html#stimulus)

Since 2.38.0
{: .label }

```console
bin/rails generate component Example title --stimulus

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  stimulus
      create    app/components/example_component_controller.js
      invoke  erb
      create    app/components/example_component.html.erb
```

To always generate a Stimulus controller, set `config.view_component.generate.stimulus_controller = true`.

To generate a TypeScript controller instead of a JavaScript controller, either:

- Pass the `--typescript` option
- Set `config.view_component.generate.typescript = true`

### Generate [locale files](/guide/translations.html)

Since 2.47.0
{: .label }

```console
bin/rails generate component Example title --locale

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  locale
      create    app/components/example_component.yml
      invoke  erb
      create    app/components/example_component.html.erb
```

To always generate locale files, set `config.view_component.generate.locale = true`.

To generate translations in distinct locale files, set `config.view_component.generate.distinct_locale_files = true` to generate as many files as configured in `I18n.available_locales`.

### Place the view in a sidecar directory

Since 2.16.0
{: .label }

```console
bin/rails generate component Example title --sidecar

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
      create    app/components/example_component/example_component.html.erb
```

To always generate in the sidecar directory, set `config.view_component.generate.sidecar = true`.

### Use [inline rendering](/guide/templates.html#inline) (no template file)

Since 2.24.0
{: .label }

```console
bin/rails generate component Example title --inline

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
```

### Specify the parent class

Since 2.41.0
{: .label }

By default, `ApplicationComponent` is used if defined, `ViewComponent::Base` otherwise.

```console
bin/rails generate component Example title content --parent MyBaseComponent

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
      create    app/components/example_component.html.erb
```

To always use a specific parent class, set `config.view_component.component_parent_class = "MyBaseComponent"`.

### Skip collision check

The generator prevents naming collisions with existing components. To skip this check and force the generator to run, use the `--skip-collision-check` or `--force` option.
