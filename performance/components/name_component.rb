# frozen_string_literal: true

class Performance::NameComponent < ViewComponent::Base
  def initialize(name:)
    ('a'...'z').to_a.each do |c|
      instance_variable_set("@rand_var_#{c}", true)
    end
    @name = name
  end
end
