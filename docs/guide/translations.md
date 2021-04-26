---
layout: default
title: Translations
parent: Building ViewComponents
---

# Translations (experimental)

To use experimental support for `I18n` translations, include `ViewComponent::Translatable`:

```ruby
# app/components/example_component.rb
module ExampleComponent < ApplicationComponent
  include ViewComponent::Translatable
end
```

Add a sidecar YAML file with translations for the component:

```yml
# app/components/example_component.yml
en:
  hello: "Hello world!"
```

Access component-local translations with a leading dot:

```erb
<%# app/components/example_component.html.erb %>
<%= t(".hello") %>
```

Global Rails translations are available as well:

```erb
<%# app/components/example_component.html.erb %>
<%= t("my.global.translation") %>
```

Global translations shadowed by sidecar translations can be accessed with `helpers` or `I18n`:

```erb
<%# app/components/example_component.html.erb %>
<%= helpers.t("hello") %>
<%= I18n.t("hello") %>
```
