# frozen_string_literal: true

module PartialHelper
  module State
    def self.calls
      @_calls || 0
    end

    def self.reset
      @_calls = 0
    end

    def self.expensive_query
      @_calls ||= 0
      @_calls += 1
    end
  end

  def expensive_message
    return @_foo if defined?(@_foo)

    @_foo = State.expensive_query
  end
end
