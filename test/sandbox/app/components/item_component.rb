require "dry-initializer"

class ItemComponent < ViewComponent::Base
  extend Dry::Initializer

  option :item

  erb_template <<~ERB
    <%= item.name %>
  ERB
end
