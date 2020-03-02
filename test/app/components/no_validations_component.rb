# frozen_string_literal: true

class NoValidationsComponent < ViewComponent::Base
  def initialize(*); end

  def before_render_check
    #noop
  end
end
