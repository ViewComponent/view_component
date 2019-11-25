# frozen_string_literal: true

class ActiveRecord::Base
  def to_component_class
    class_name = "#{self.class.name}Component"

    class_name.constantize if defined?(class_name)
  end
end
