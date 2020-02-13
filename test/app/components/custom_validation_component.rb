# frozen_string_literal: true

module CustomValidations
  def validate!
    raise RuntimeError.new("validate! was called")
  end
end

ActionView::Component::Base.validation_module = "CustomValidations"

class CustomValidationComponent < ActionView::Component::Base
  def initialize(*); end
end

ActionView::Component::Base.validation_module = ActiveModel::Validations.name
