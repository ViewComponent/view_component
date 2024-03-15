# frozen_string_literal: true

class TemplateExtensionDefinedComponent < ViewComponent::Base
  VC_TEMPLATE_EXTENSION = "html"

  def initialize(message:)
    @message = message
  end
end
