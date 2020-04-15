# frozen_string_literal: true

module ViewComponent # :nodoc:
  class CollectionIteration

    attr_reader :size

    # The current iteration of the collection.
    attr_reader :index

    def initialize(size)
      @size  = size
      @index = -1
    end

    # Check if this is the first iteration of the collection.
    def first?
      index == 0
    end

    # Check if this is the last iteration of the collection.
    def last?
      index == size - 1
    end

    def iterate! # :nodoc:
      @index += 1
    end

  end
end
