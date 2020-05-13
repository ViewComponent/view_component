# frozen_string_literal: true

module ViewComponent
  class CollectionSlot
    include ViewComponent::Slotable

    def self.accessor_name
      ActiveSupport::Inflector.pluralize(name.demodulize.downcase).to_sym
    end

    def self.default_accessor_value
      []
    end
  end
end
