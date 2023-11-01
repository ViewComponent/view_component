# frozen_string_literal: true

class PolymorphicWrapperComponent < ViewComponent::Base
  def initialize
    @sections = []
  end

  def section
    s = PolymorphicContentSlotComponent.new
    s.with_content("the truth is out there")
    s.with_leading_visual_icon("wow")

    @sections << s
  end

  def call
    content
    safe_join(@sections.map { |c| capture { render(c) } })
  end
end
