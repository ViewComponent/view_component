# frozen_string_literal: true

class ExtendingWithoutOwnTemplateComponent < BaseComponent
  def initialize(message:)
    super(message: "extended #{message}")
  end
end
