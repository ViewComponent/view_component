# frozen_string_literal: true

class UrlHelperComponent < ViewComponent::Base
  def initialize(url: root_path)
    @url = url
  end
end
