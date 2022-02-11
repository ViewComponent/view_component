---
layout: default
title: Previews
parent: Guide
---

# Previews

`ViewComponent::Preview`, like `ActionMailer::Preview`, provides a quick way to preview components in isolation.

_For a more interactive experience, consider using [ViewComponent::Storybook](https://github.com/jonspalmer/view_component_storybook) or [Lookbook](https://github.com/allmarkedup/lookbook)._

Define a `ViewComponent::Preview`:

```ruby
# test/components/previews/example_component_preview.rb
class ExampleComponentPreview < ViewComponent::Preview
  def with_default_title
    render(ExampleComponent.new(title: "Example component default"))
  end

  def with_long_title
    render(ExampleComponent.new(title: "This is a really long title to see how the component renders this"))
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

* <http://localhost:3000/rails/view_components/example_component/with_default_title>
* <http://localhost:3000/rails/view_components/example_component/with_long_title>
* <http://localhost:3000/rails/view_components/example_component/with_content_block>

It's also possible to set dynamic values from the params by setting them as arguments:

```ruby
# test/components/previews/example_component_preview.rb
class ExampleComponentPreview < ViewComponent::Preview
  def with_dynamic_title(title: "Example component default")
    render(ExampleComponent.new(title: title))
  end
end
```

Which enables passing in a value with <http://localhost:3000/rails/view_components/example_component/with_dynamic_title?title=Custom+title>.

The `ViewComponent::Preview` base class includes
[`ActionView::Helpers::TagHelper`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html), which provides the [`tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-tag)
and [`content_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-content_tag) view helper methods.

Previews use the application layout by default, but can use a specific layout with the `layout` option:

```ruby
# test/components/previews/example_component_preview.rb
class ExampleComponentPreview < ViewComponent::Preview
  layout "admin"

  ...
end
```

To set a custom layout for previews and the previews index page, set: `default_preview_layout`:

```ruby
# config/application.rb
# Set the default layout to app/views/layouts/component_preview.html.erb
config.view_component.default_preview_layout = "component_preview"
```

Preview classes live in `test/components/previews`, which can be configured using the `preview_paths` option:

```ruby
# config/application.rb
config.view_component.preview_paths << "#{Rails.root}/lib/component_previews"
```

Previews are served from <http://localhost:3000/rails/view_components> by default. To use a different endpoint, set the `preview_route` option:

```ruby
# config/application.rb
config.view_component.preview_route = "/previews"
```

This example will make the previews available from <http://localhost:3000/previews>.

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
(the path should be relative to `config.view_component.preview_path`):

```ruby
# test/components/previews/cell_component_preview.rb
class CellComponentPreview < ViewComponent::Preview
  def default
    render_with_template(template: 'custom_cell_component_preview/my_preview_template')
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

Which enables passing in a value with <http://localhost:3000/rails/view_components/cell_component/default?title=Custom+title&subtitle=Another+subtitle>.

## Configuring preview controller

Previews can be extended to allow users to add authentication, authorization, before actions, or anything that the end user would need to meet their needs using the `preview_controller` option:

```ruby
# config/application.rb
config.view_component.preview_controller = "MyPreviewController"
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

To render a source preview in a different place, use the view helper `preview_source` from within your preview template or preview layout.

## Using with rspec

When using previews with rspec,  replace `test/components` with `spec/components` and update `preview_paths`:

```ruby
# config/application.rb
config.view_component.preview_paths << "#{Rails.root}/spec/components/previews"
```
