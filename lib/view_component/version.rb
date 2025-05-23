# frozen_string_literal: true

module ViewComponent
  module VERSION
    MAJOR = 3
    MINOR = 23
    PATCH = 2
    PRE = nil

    STRING = [MAJOR, MINOR, PATCH, PRE].compact.join(".")
  end
end

puts ViewComponent::VERSION::STRING if __FILE__ == $PROGRAM_NAME
