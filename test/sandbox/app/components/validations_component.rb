# frozen_string_literal: true

class ValidationsComponent < ViewComponent::Base
  include ActiveModel::Validations

  validates :content, presence: true

  def before_render
    validate!
  end
end
