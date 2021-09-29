# frozen_string_literal: true

class PolymorphicSlotComponent < ViewComponent::Base
  renders_many :items, {
    foo: "FooItem",
    bar: lambda { |**system_arguments|
      classes = class_names("bar", **system_arguments)
      "<div class=\"#{classes}\">bar item</div>".html_safe  # rubocop:disable Rails/OutputSafety
    }
  }

  class FooItem < ViewComponent::Base
    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end

    def call
      content_tag("div", class: class_names("foo", **@system_arguments)) do
        "foo item"
      end
    end
  end
end
