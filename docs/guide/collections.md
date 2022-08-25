---
layout: default
title: Collections
parent: How-to guide
---

# Collections

Since 2.1.0
{: .label }

Like [Rails partials](https://guides.rubyonrails.org/layouts_and_rendering.html#rendering-collections), it's possible to render a collection with ViewComponents, using `with_collection`:

```erb
<%# app/view/products/index.html.erb %>
<%= render(ProductComponent.with_collection(@products)) %>
```

```ruby
# app/components/product_component.rb
class ProductComponent < ViewComponent::Base
  def initialize(product:)
    @product = product
  end
end
```

[By default](https://github.com/viewcomponent/view_component/blob/89f8fab4609c1ef2467cf434d283864b3c754473/lib/view_component/base.rb#L249), the component name is used to define the parameter passed into the component from the collection.

## `with_collection_parameter`

Use `with_collection_parameter` to change the name of the collection parameter:

```ruby
# app/components/product_component.rb
class ProductComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:)
    @item = item
  end
end
```

## Additional arguments

Additional arguments besides the collection are passed to each component instance:

```erb
<%# app/view/products/index.html.erb %>
<%= render(ProductComponent.with_collection(@products, notice: "hi")) %>
```

```ruby
# app/components/product_component.rb
class ProductComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:, notice:)
    @item = item
    @notice = notice
  end
end
```

```erb
<%# app/components/product_component.html.erb %>
<li>
  <h2><%= @item.name %></h2>
  <span><%= @notice %></span>
</li>
```

## Collection counter

Since 2.5.0
{: .label }

ViewComponent defines a counter variable matching the parameter name above, followed by `_counter`. To access the variable, add it to `initialize` as an argument:

```ruby
# app/components/product_component.rb
class ProductComponent < ViewComponent::Base
  def initialize(product:, product_counter:)
    @product = product
    @counter = product_counter
  end
end
```

```erb
<%# app/components/product_component.html.erb %>
<li>
  <%= @counter %> <%= @product.name %>
</li>
```

## Collection iteration context

Since 2.33.0
{: .label }

ViewComponent defines an iteration variable matching the parameter name above, followed by `_iteration`. This gives contextual information about the iteration to components within the collection (`#size`, `#index`, `#first?`, and `#last?`).

To access the variable, add it to `initialize` as an argument:

```ruby
# app/components/product_component.rb
class ProductComponent < ViewComponent::Base
  def initialize(product:, product_iteration:)
    @product = product
    @iteration = product_iteration
  end
end
```

```erb
<%# app/components/product_component.html.erb %>
<li class="<%= "featured" if @iteration.first? %>">
  <%= @product.name %>
</li>
```
