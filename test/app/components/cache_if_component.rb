# frozen_string_literal: true

class CacheIfComponent < ViewComponent::Base
  attr_reader :version
  private :version

  def initialize(version:)
    @version = version
  end
end
