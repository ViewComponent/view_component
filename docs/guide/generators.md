---
layout: default
title: Generators
parent: Building ViewComponents
---

# Generators

The generator accepts a component name and a list of arguments.

This creates an `ExampleComponent` with `title` and `content` attributes:

```console
bin/rails generate component Example title content

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
      create    app/components/example_component.html.erb
```

## Options

The component generator accepts several options to customize its behavior.

### Override the default template engine

ViewComponent includes template generators for the `erb`, `haml`, and `slim` template engines and will default to the template engine specified in `config.generators.template_engine`.

```console
bin/rails generate component Example title --template-engine slim

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  slim
      create    app/components/example_component.html.slim
```

### Override the default test framework

By default, the `config.generators.test_framework` is used.

```console
bin/rails generate component Example title --test-framework rspec

      create  app/components/example_component.rb
      invoke  rspec
      create    spec/components/example_component_spec.rb
      invoke  erb
      create    app/components/example_component.html.erb
```

### Generate a [preview](/guide/previews.html)

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

### Place the view and assets in a [sidecar directory](/guide/sidecar_assets.html)

```console
bin/rails generate component Example title --sidecar

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
      create    app/components/example_component/example_component.html.erb
```

### Use [inline rendering](/guide/templates.html#inline) (no template file)

```console
bin/rails generate component Example title --inline

      create  app/components/example_component.rb
      invoke  test_unit
      create    test/components/example_component_test.rb
      invoke  erb
```

### Skip collision check

The generator prevents naming collisions with existing components. To skip this check and force the generator to run, use the `--skip-collision-check` or `--force` option.

## Customizing the generator

The best way to tailor the component generator to your project needs, is to create your own.

See [view_component-contrib](https://github.com/palkan/view_component-contrib#installation-and-generating-generators) for a possible approach.