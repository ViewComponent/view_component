# frozen_string_literal: true

class SlotsRequiredComponent < ViewComponent::Base
  renders_one :child1, "SlotsRequiredChildComponent", required: true
  renders_one :child2, ->(**system_arguments) do
    SlotsRequiredChildComponent.new(class_names: "child2", **system_arguments)
  end, required: true
  renders_one :child3, types: {
    icon: {renders: "SlotsRequiredChildComponent"},
    avatar: {
      renders: lambda { |**system_arguments| SlotsRequiredChildComponent.new(class_names: "child3", **system_arguments) },
      required: true
    }
  }
  renders_one :child4, "SlotsRequiredChildComponent", required: false

  class SlotsRequiredChildComponent < ViewComponent::Base
    def initialize(class_names: "")
      @class_names = class_names
    end

    def call
      content_tag(:div, "Child", class: "child #{@class_names}")
    end
  end
end
