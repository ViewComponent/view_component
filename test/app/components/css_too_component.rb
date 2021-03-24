# frozen_string_literal: true

class CssTooComponent < ViewComponent::Base
  include ViewComponent::Stylable

  def call
    content_tag(:div, "Hello, World!", class: styles['foo'])
  end
end
