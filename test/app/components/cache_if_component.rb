# frozen_string_literal: true

class CacheIfComponent < ActionView::Component::Base
  attr_reader :version
  private :version

  def initialize(version:)
    @version = version
  end
end
