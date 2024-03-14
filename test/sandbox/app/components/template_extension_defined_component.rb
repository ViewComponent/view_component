# frozen_string_literal: true

class TemplateExtensionDefinedComponent < ViewComponent::Base
  def initialize(message:)
    self.template_extension = "html"

    @message = message
  end
end
