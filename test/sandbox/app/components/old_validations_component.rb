# frozen_string_literal: true

# TODO: Remove in v3.0.0
class OldValidationsComponent < ViewComponent::Base
  include ActiveModel::Validations

  validates :content, presence: true

  def before_render_check
    validate!
  end
end
