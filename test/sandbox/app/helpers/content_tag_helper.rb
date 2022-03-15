# frozen_string_literal: true

module ContentTagHelper
  def my_helper_method(options, &block)
    content_tag(:div, options, &block)
  end
end
