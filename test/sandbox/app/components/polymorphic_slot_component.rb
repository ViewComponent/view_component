# frozen_string_literal: true

class PolymorphicSlotComponent < ViewComponent::Base
  renders_many :items, {
    foo: "FooItem",
    bar: lambda { |class_names: "", **_system_arguments|
      classes = (class_names.split(" ") + ["bar"]).join(" ")
      "<div class=\"#{classes}\">bar item</div>".html_safe  # rubocop:disable Rails/OutputSafety
    }
  }

  class FooItem < ViewComponent::Base
    def initialize(class_names: "", **_system_arguments)
      @class_names = class_names
    end

    def call
      classes = (@class_names.split(" ") + ["foo"]).join(" ")
      content_tag("div", class: classes) do
        "foo item"
      end
    end
  end
end
