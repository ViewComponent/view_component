# frozen_string_literal: true

class ExtendingWithOwnTemplateComponent < BaseComponent
  def initialize(message:)
    super(message: "extended #{message}")
  end
end
