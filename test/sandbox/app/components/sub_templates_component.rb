# frozen_string_literal: true

class SubTemplatesComponent < ViewComponent::Base
  include ViewComponent::Subtemplate

  attr_reader :number
  attr_reader :string

  def initialize(number:, string:)
    @items = ["Apple", "Banana", "Pear"]
    @number = number
    @string = string
  end
end