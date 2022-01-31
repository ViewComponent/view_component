# frozen_string_literal: true

module FormHelper
  def form_tag_html(options = {})
    safe_join [
      "<span>Hello, World!</span>".html_safe,
      super(options),
    ]
  end
end
