# frozen_string_literal: true

module Primer
  class StateComponent < ActionView::Component::Base
    COLOR_CLASS_MAPPINGS = {
      default: "",
      green: "State--green",
      red: "State--red",
      purple: "State--purple",
    }.freeze

    attr_reader :color, :title
    validates :color, inclusion: {in: COLOR_CLASS_MAPPINGS.keys}
    validates :title, :content, presence: true

    def initialize(color: :default, title:)
      @color, @title = color, title
    end
  end
end
