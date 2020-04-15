# frozen_string_literal: true

module ViewComponent # :nodoc:
  class CollectionIteration

    attr_reader :size

    # The current iteration of the partial.
    attr_reader :index

    def initialize(size)
      @size  = size
      @index = -1
    end

    # Check if this is the first iteration of the partial.
    def first?
      index == 0
    end

    # Check if this is the last iteration of the partial.
    def last?
      index == size - 1
    end

    def iterate! # :nodoc:
      @index += 1
    end

  end
end
