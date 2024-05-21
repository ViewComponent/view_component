---
layout: default
title: Previews
parent: How-to guide
---

# Previews

`ViewComponent::Preview`, like `ActionMailer::Preview`, provides a quick way to preview components in isolation:

```ruby
# test/components/previews/example_component_preview.rb
class ExampleComponentPreview < ViewComponent::Preview
  def with_default_title
    render(ExampleComponent.new(title: "Example component default"))
  end

  def with_content_block
    render(ExampleComponent.new(title: "This component accepts a block of content")) do
      tag.div do
        content_tag(:span, "Hello")
      end
    end
  end
end
```

Then access the resulting previews at:

* `/rails/view_components/example_component/with_default_title`
* `/rails/view_components/example_component/with_content_block`

_For a more interactive experience, consider using [Lookbook](https://lookbook.build) or [ViewComponent::Storybook](https://github.com/jonspalmer/view_component_storybook)._

## Passing parameters

Set dynamic values from URL parameters by setting them as arguments:

```ruby
# test/components/previews/example_component_preview.rb
class ExampleComponentPreview < ViewComponent::Preview
  def with_dynamic_title(title: "Example component default")
    render(ExampleComponent.new(title: title))
  end
end
```

Then pass in a value: `/rails/view_components/example_component/with_dynamic_title?title=Custom+title`.

## Previews as test cases

Since 2.56.0
{: .label }

Use `render_preview(name)` to render previews in ViewComponent unit tests:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_render_preview
    render_preview(:with_default_title)

    assert_text("Example component default")
  end
end
```

Parameters can also be passed:

```ruby
class ExampleComponentTest < ViewComponent::TestCase
  def test_render_preview
    render_preview(:with_default_title, params: {message: "Hello, world!"})

    assert_text("Hello, world!")
  end
end
```

By default, the preview class is inferred from the name of the current test file. Use `from` to set it explicitly:

```ruby
class ExampleTest < ViewComponent::TestCase
  def test_render_preview
    render_preview(:with_default_title, from: ExampleComponentPreview)

    assert_text("Hello, world!")
  end
end
```

## Helpers

The `ViewComponent::Preview` base class includes
[`ActionView::Helpers::TagHelper`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html), which provides the [`tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-tag)
and [`content_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-content_tag) view helper methods.

## Layouts

Previews render with the application layout by default, but can use a specific layout with the `layout` option:

```ruby
# test/components/previews/example_component_preview.rb
class ExampleComponentPreview < ViewComponent::Preview
  layout "admin"
end
```

To set a custom layout for individual previews and the previews index page, set: `default_preview_layout`:

```ruby
# config/application.rb
# Set the default layout to app/views/layouts/component_preview.html.erb
config.view_component.default_preview_layout = "component_preview"
```

## Preview paths

Preview classes live in `test/components/previews`, which can be configured using the `preview_paths` option:

```ruby
# config/application.rb
config.view_component.preview_paths << "#{Rails.root}/lib/component_previews"
```

## Previews route

Previews are served from `/rails/view_components` by default. To use a different endpoint, set the `preview_route` option:

```ruby
# config/application.rb
config.view_component.preview_route = "/previews"
```

## Preview templates

Given a preview `test/components/previews/cell_component_preview.rb`, template files can be defined at `test/components/previews/cell_component_preview/`:

```ruby
# test/components/previews/cell_component_preview.rb
class CellComponentPreview < ViewComponent::Preview
  def default
  end
end
```

```erb
<%# test/components/previews/cell_component_preview/default.html.erb %>
<table class="table">
  <tbody>
    <tr>
      <%= render CellComponent.new %>
    </tr>
  </tbody>
</div>
```

To use a different location for preview templates, pass the `template` argument:
(the path should be relative to `config.view_component.preview_paths`):

```ruby
# test/components/previews/cell_component_preview.rb
class CellComponentPreview < ViewComponent::Preview
  def default
    render_with_template(template: "custom_cell_component_preview/my_preview_template")
  end
end
```

Values from `params` can be accessed through `locals`:

```ruby
# test/components/previews/cell_component_preview.rb
class CellComponentPreview < ViewComponent::Preview
  def default(title: "Default title", subtitle: "A subtitle")
    render_with_template(locals: {
      title: title,
      subtitle: subtitle
    })
  end
end
```

Which enables passing in a value: `/rails/view_components/cell_component/default?title=Custom+title&subtitle=Another+subtitle`.

## Configuring preview controller

Extend previews to add authentication, authorization, before actions, etc. using the `preview_controller` option:

```ruby
# config/application.rb
config.view_component.preview_controller = "MyPreviewController"
```

Then include `PreviewActions` in the controller:

```ruby
class MyPreviewController < ActionController::Base
  include ViewComponent::PreviewActions
end
```

## Enabling previews

Previews are enabled by default in test and development environments. To enable or disable previews, use the `show_previews` option:

```ruby
# config/environments/test.rb
config.view_component.show_previews = false
```

## Source previews

A source preview is a syntax highlighted source code example of the usage of a view component, shown below the preview.
Source previews are disabled by default. To enable or disable source previews, use the `show_previews_source` option:

```ruby
# config/environments/test.rb
config.view_component.show_previews_source = true
```

To render the source preview in a different location, use the view helper `preview_source` from within the preview template or preview layout.

## Use with RSpec

When using previews with RSpec,  replace `test/components` with `spec/components` and update `preview_paths`:

```ruby
# config/application.rb
config.view_component.preview_paths << "#{Rails.root}/spec/components/previews"
```
