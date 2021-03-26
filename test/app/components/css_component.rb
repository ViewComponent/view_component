# frozen_string_literal: true

class CssComponent < ViewComponent::Base
  include ViewComponent::Stylable

  def call
    content_tag(:div, "Hello, World!", class: styles["foo"])
  end
end
