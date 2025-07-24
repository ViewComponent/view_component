# frozen_string_literal: true

module ViewComponent
  module VERSION
    MAJOR = 4
    MINOR = 0
    PATCH = 0
    PRE = nil

    STRING = [MAJOR, MINOR, PATCH, PRE].compact.join(".")
  end
end

puts ViewComponent::VERSION::STRING if __FILE__ == $PROGRAM_NAME
