# frozen_string_literal: true

module ViewComponent
  class Slot
    include ViewComponent::Slotable

    def self.accessor_name
      name.demodulize.downcase.to_sym
    end

    def self.default_accessor_value
      nil
    end
  end
end
