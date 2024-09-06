# frozen_string_literal: true

class SubTemplatesComponent < ViewComponent::Base
  attr_reader :number
  attr_reader :string

  def initialize number: 1, string: "foo"
    super()
    @items = ["Apple", "Banana", "Pear"]
    @number = number
    @string = string
  end
end
