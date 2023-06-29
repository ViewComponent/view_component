# frozen_string_literal: true

class UrlForComponent < ViewComponent::Base
  def initialize(only_path: true)
    @only_path = only_path
  end
end
