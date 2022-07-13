# frozen_string_literal: true

module Primer
  class StateComponent < ViewComponent::Base
    COLOR_CLASS_MAPPINGS = {
      default: "",
      green: "State--green",
      red: "State--red",
      purple: "State--purple"
    }.freeze

    attr_reader :color, :title

    def initialize(title:, color: :default)
      @color, @title = color, title
    end
  end
end
