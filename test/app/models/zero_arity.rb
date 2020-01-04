# frozen_string_literal: true

class ZeroArity
  # Used to test components that have initializers that take no arguments (arity == 0).

  include ActiveModel::Model

  attr_accessor :title
end
