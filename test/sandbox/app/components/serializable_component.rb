# frozen_string_literal: true

class SerializableComponent < ViewComponent::Base
  include ViewComponent::Serializable

  def initialize(title:, count: 0)
    @title = title
    @count = count
  end

  erb_template <<~ERB
    <div class="serializable">
      <h1><%= @title %></h1>
      <span><%= @count %></span>
    </div>
  ERB
end
