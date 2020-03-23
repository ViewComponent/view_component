# frozen_string_literal: true

class ValidationsComponent < ViewComponent::Base
  include ActiveModel::Validations

  validates :content, presence: true

  def initialize(*); end

  def before_render_check
    validate!
  end
end
