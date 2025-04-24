# frozen_string_literal: true

class ObjectShapesComponent < ViewComponent::Base
  def initialize(name:)
    ('a'...'z').to_a.shuffle.each do |c|
        instance_variable_set("@rand_var_#{c}", true)
    end
    @name = name
  end

  def call
    @name.to_s.html_safe
  end
end
