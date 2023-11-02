# frozen_string_literal: true

class RequestUrlComponent < ViewComponent::Base
  def call
    content_tag(:span, request.path, class: "path") + content_tag(:span, request.fullpath, class: "fullpath")
  end
end
