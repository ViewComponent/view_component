# frozen_string_literal: true

class ProtocolComponent < ViewComponent::Base
  def call
    content_tag(:div, "Protocol: #{request.scheme}, SSL: #{request.ssl?}", class: "protocol")
  end
end
