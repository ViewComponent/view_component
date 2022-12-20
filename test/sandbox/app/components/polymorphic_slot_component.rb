# frozen_string_literal: true

class PolymorphicSlotComponent < ViewComponent::Base
  renders_one :header, types: {
    standard: lambda { |&block| content_tag(:div, class: "standard", &block) },
    special: lambda { |&block| content_tag(:div, class: "special", &block) }
  }

  renders_many :items, types: {
    foo: "FooItem",
    bar: lambda { |class_names: "", **_system_arguments|
      classes = (class_names.split(" ") + ["bar"]).join(" ")
      content_tag(:div, class: classes) do
        "bar item"
      end
    }
  }

  class FooItem < ViewComponent::Base
    def initialize(class_names: "", **_system_arguments)
      @class_names = class_names
    end

    def call
      classes = (@class_names.split(" ") + ["foo"]).join(" ")
      content_tag(:div, class: classes) do
        "foo item"
      end
    end
  end
end
