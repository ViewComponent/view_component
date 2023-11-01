# frozen_string_literal: true

class SlottedContentParentComponent < ViewComponent::Base
  renders_many :children, SlottedContentChildComponent
end
