# frozen_string_literal: true

class SuperBaseComponent < ViewComponent::Base
  renders_one :parent_slot, lambda { |text:|
    content_tag(:p) { text }
  }
end
