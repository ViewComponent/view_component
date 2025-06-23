---
layout: default
title: Configuration
parent: How-to guide
---

# Configuration

To configure ViewComponent, set options in `config/ENVIRONMENT.rb`:

```ruby
MyApplication.configure do
  config.view_component.instrumentation_enabled = true
  config.view_component.generate.path = "app/custom_components"
  config.view_component.previews.controller = "MyPreviewController"
end
```

For a list of available options, see [/api](/api#configuration).
