# frozen_string_literal: true

module ViewComponent
  module VERSION # The semantic version of the gem
    MAJOR = 4 # The major version of the gem
    MINOR = 0 # The minor version of the gem
    PATCH = 0 # The patch version of the gem
    PRE = "alpha7" # The prerelease version of the gem

    STRING = [MAJOR, MINOR, PATCH, PRE].compact.join(".") # The semantic version of the gem in string format
  end
end

puts ViewComponent::VERSION::STRING if __FILE__ == $PROGRAM_NAME
