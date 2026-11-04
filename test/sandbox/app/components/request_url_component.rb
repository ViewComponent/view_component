# frozen_string_literal: true

class RequestUrlComponent < ViewComponent::Base
  def call
    content_tag(:span, request.path, class: "path") +
      content_tag(:span, request.fullpath, class: "fullpath") +
      link_to("Request-dependent link", url_for(bar: "baz")) +
      link_to("Absolute request-dependent link", url_for(bar: "baz", only_path: false))
  end
end
