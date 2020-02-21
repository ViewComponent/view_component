# frozen_string_literal: true

class NoValidationsComponent < ActionView::Component::Base
  validates :content, presence: true

  def initialize(*); end

  def before_render_check
    #noop
  end
end
