---
layout: default
title: Forms
parent: Practical Examples
---

# Forms

## Table of contents

1. [Before you start](#before-you-start)
2. [Using form helpers inside a `ViewComponent`](#using-form-helpers-inside-a-view-component)
3. [Creating your own input elements](#creating-your-own-input-elements)
    1. [Writing input elements in vanilla html](#writing-input-elements-in-vanilla-html)
4. [Gotchas and known issues](#gotchas-and-known-issues)

## Before you start
It's important to understand the building blocks of forms in Ruby on Rails before attempting to use `ViewComponent` to enhance them.

Please refer to the official documentation and Rails Guides to get up to speed.

- `ActionView` form helpers [visit](https://guides.rubyonrails.org/form_helpers.html)
- `ActionView::Helpers::FormBuilder` [visit](https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html){:target="_blank"}

After reading these, you should have a good understanding of:
- The `form_with` helper used to create an HTML `<form>`
- `FormBuilder` and the instance yielded to the `form_with` block
- The different helper methods you can call on the `FormBuilder` instance to create input fields (e.g. `form.text_field`)
- The conventions set by Rails to [name parameters](https://guides.rubyonrails.org/form_helpers.html#understanding-parameter-naming-conventions){:target="_blank"}

## Using form helpers inside a `ViewComponent`

If your component needs to render a form, you can use the `form_with` helpers just as you would in a Rails template or patial

```ruby
# app/components/comment_form_component.rb
class CommentFormComponent < ApplicationComponent
  def initialize(comment:)
    @comment = comment
  end
  attr_reader :comment
end
```


```erb
<!-- app/components/comment_form_component.html.erb -->
<%= form_with(model: comment) do |form| %>
  <%= form.label :content %>
  <%= form.text_area :content %>
<% end %>
```

## Creating your own input elements

Let's imagine you want to abstract the `label` and `text_area` into a single reusable class or method. Rails has done forms for quite a while now and they have a very stable API. Because of this, it's better to leverage the framework's conventions for extending the dsl available to create forms.

### ⛔️ Bad: Passing the `FormBuilder` instance to a component

```erb
<!-- app/components/comment_form_component.html.erb -->
<%= form_with(model: comment) do |form| %>
  <%= render TextAreaWithLabelComponent.new(form: form) %>
<% end %>
```


### ✅ Good: Use `FormBuilder` methods

💡 To understand how `FormBuilder` works, it's a good idea to see how the [default class](https://github.com/rails/rails/blob/main/actionview/lib/action_view/helpers/form_helper.rb){:target="_blank"} in Rails defines helper

```ruby
class YourCustomFormBuilder < ActionView::Helpers::FormBuilder
  def text_area_with_label(attribute, **options)
    @template.capture do
      @template.concat label(attribute, options.merge(class: 'your-css-classes')
      @template.concat text_area(attribute, options.merge(class: 'your-css-classes')
    end
  end
end
```
👀 Note that you need to define the `builder` that `form_with` should use

```erb
<!-- app/components/comment_form_component.html.erb -->
<%= form_with(model: comment, builder: YourCustomFormBuilder) do |form| %>
  <%= form.text_area_with_label :content %>
<% end %>
```

### ✅ Best: Abstract the markup into a `ViewComponent`

In order to clean up your `FormBuilder` and be able to test the markup in isolation, you can extract the code inside the form builder method into a `ViewComponent`. This is very similar to what [Rails' internals](https://github.com/rails/rails/blob/d3f4db9e95a475822c02b29241a5d07cbcff6fd5/actionview/lib/action_view/helpers/form_helper.rb#L1151){:target="_blank"} do to create it's default form helpers.

Let's extract the code from the previous example into a `ViewComponent`

```ruby
class YourCustomFormBuilder < ActionView::Helpers::FormBuilder
  # Note: (attribute, **options) is an oversimplification of the arguments passed into
  # a form builder method and a ViewComponent. Take a look at the links above to understand
  # how default form builder methods work, which arguments they receive, etc.
  def text_area_with_label(attribute, **options)
    @template.render TextAreaWithLabelComponent.new(attribute: attribute, **options)
  end
end
```

```ruby
class TextAreaWithLabelComponent < ApplicationComponent
  def initialize(attribute:, **options)
    @attribute = attribute
  end
  attr_reader :attribute
end
```

```erb
<!-- app/components/text_area_with_label_component.html.erb -->
<div class='maybe-some-wrapper-class'>
  label_tag attribute, class: 'your-label-css-classes'
  text_area_tag attribute, class: 'your-text-area-classes'
</div>
```

```erb
<!-- app/components/comment_form_component.html.erb -->
<%= form_with(model: comment, builder: YourCustomFormBuilder) do |form| %>
  <%= form.text_area_with_label :content %>
<% end %>
```

#### Writing input elements in vanilla HTML

Nothing is really stopping you from using regular `<input>` tags instead of Rails' helper methods. However, is important for your own implementations to follow the conventions set by other form helpers. If you plan to do so, please read the [Understanding Parameter Naming Conventions](https://guides.rubyonrails.org/form_helpers.html#understanding-parameter-naming-conventions){:target="_blank"} section of the `form_helpers` Rails guide.

## Gotchas and Known Issues

### Using multiple `FormBuilder`s in your application
In a typical Rails application, all views renderred by controllers that intherit from your `ApplicationController` will use the default `FormBuilder` provided by the framework. However you are able to override the which `FormBuilder` a section of your application uses. We previously saw that you can do so using the `builder` argument in `form_with` but you can also configure it at a [`controller` level](https://edgeapi.rubyonrails.org/classes/ActionController/FormBuilder.html){:target="_blank"}.

This is currently *not supported* by `ViewComponent`. To overcome this, apply the correct form builder each time to the `form_with` method.
### Passing the form builder object to a `ViewComponent`
In the previous section we discouraged passing an instance of a `FormBuilder` to a `ViewComponent` to create new input types. However, there are legitimate cases to do this. For example, is common in some Rails applications to extract the fields of a form into their own patial:
```console
/app
  /views
    /comments
      new.html.erb
      edit.html.erb
      _form.html.erb
      _fields.html.erb
```

```erb
# form.html.erb
<%= form_with(model: comment) do |form| =>
  <%= render 'fields', form: form%>
<% end %>
```

```erb
# fields.html.erb
<%= form.label :content %>
<%= form.text_area :content %>
```

This is currently *not supported* by `ViewComponent`. Please refer to the following [issue](https://github.com/github/view_component/issues/241){:target="_blank"} to track support for this.

