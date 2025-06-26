# frozen_string_literal: true

class PolymorphicSlotSubclassComponent < PolymorphicSlotComponent
  renders_one :header, types: {
    my: lambda { |&block| content_tag(:div, class: "my", &block) },
  }
end
