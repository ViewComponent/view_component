# frozen_string_literal: true

module ViewComponent
  module VERSION
    MAJOR = 2
    MINOR = 43
    PATCH = 1

    STRING = [MAJOR, MINOR, PATCH].join(".")
  end
end

puts ViewComponent::VERSION::STRING if __FILE__ == $PROGRAM_NAME
