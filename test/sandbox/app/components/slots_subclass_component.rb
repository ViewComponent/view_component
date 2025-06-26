# frozen_string_literal: true

class SlotsSubclassComponent < SlotsComponent
  renders_one :title, ->(&block) do
    content_tag :h1 do
      block.call
    end
  end
end
