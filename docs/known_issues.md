---
layout: default
title: Known issues
nav_order: 11
---

# Known issues

_There remain several known issues with ViewComponent. We'd be thrilled to see you consider solutions to these thorny bugs!_

## Limited i18n support

ViewComponent currently only supports sidecar translation files. In some cases, it could be useful to support centralized translations using namespacing:

```yml
en:
  view_components:
    login_form:
      submit: "Log in"
    nav:
      user_info:
        login: "Log in"
        logout: "Log out"
```

## Lack of Jekyll support

It would be lovely if we could support rendering ViewComponents in Jekyll, as it would enable the reuse of ViewComponents across static and dynamic (Rails-based) sites.

## Forms don't use the default `FormBuilder`

Calls to form helpers such as `form_with` in ViewComponents [don't use the default form builder](https://github.com/viewcomponent/view_component/pull/1090#issue-753331927). This is by design, as it allows global state to change the rendered output of a component. Instead, consider passing a form builder into form helpers via the `builder` argument:

```html.erb
<%= form_for(record, builder: CustomFormBuilder) do |f| %>
  <%= f.text_field :name %>
<% end %>
```
