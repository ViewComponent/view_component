# frozen_string_literal: true

class SerializableComponent < ViewComponent::Base
  include ViewComponent::Serializable

  class HeaderComponent < ViewComponent::Base
    def initialize(text:)
      @text = text
    end

    erb_template "<span class=\"header\"><%= @text %></span>"
  end

  class ItemComponent < ViewComponent::Base
    def initialize(label, highlighted: false)
      @label = label
      @highlighted = highlighted
    end

    erb_template "<span class=\"item<%= ' highlighted' if @highlighted %>\"><%= @label %></span>"
  end

  renders_one :header, HeaderComponent
  renders_many :items, ItemComponent

  def initialize(title, count: 0)
    @title = title
    @count = count
  end

  erb_template <<~ERB
    <div class="serializable-component">
      <h1><%= @title %></h1>
      <span><%= @count %></span>
      <%= header %>
      <% items.each do |item| %>
        <div class="item"><%= item %></div>
      <% end %>
    </div>
  ERB
end
