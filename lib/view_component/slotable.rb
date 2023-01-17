# frozen_string_literal: true

require "active_support/concern"

require "view_component/slot"

module ViewComponent
  module Slotable
    extend ActiveSupport::Concern

    included do
      # Hash of registered Slots
      class_attribute :slots
      self.slots = {}
    end

    class_methods do
      def inherited(child)
        # Clone slot configuration into child class
        # see #test_slots_pollution
        child.slots = slots.clone

        super
      end
    end

    # Build a Slot instance on a component,
    # exposing it for use inside the
    # component template.
    #
    # slot: Name of Slot, in symbol form
    # **args: Arguments to be passed to Slot initializer
    #
    # For example:
    # <%= render(SlotsComponent.new) do |component| %>
    #   <% component.slot(:footer, class_names: "footer-class") do %>
    #     <p>This is my footer!</p>
    #   <% end %>
    # <% end %>
    #
    def slot(slot_name, **args, &block)
      # Raise ArgumentError if `slot` doesn't exist
      unless slots.key?(slot_name)
        raise ArgumentError.new "Unknown slot '#{slot_name}' - expected one of '#{slots.keys}'"
      end

      slot = slots[slot_name]

      # The class name of the Slot, such as Header
      slot_class = self.class.const_get(slot[:class_name])

      unless slot_class <= ViewComponent::Slot
        raise ArgumentError.new "#{slot[:class_name]} must inherit from ViewComponent::Slot"
      end

      # Instantiate Slot class, accommodating Slots that don't accept arguments
      slot_instance = args.present? ? slot_class.new(**args) : slot_class.new

      # Capture block and assign to slot_instance#content
      slot_instance.content = view_context.capture(&block).to_s.strip.html_safe if block

      if slot[:collection]
        # Initialize instance variable as an empty array
        # if slot is a collection and has yet to be initialized
        unless instance_variable_defined?(slot[:instance_variable_name])
          instance_variable_set(slot[:instance_variable_name], [])
        end

        # Append Slot instance to collection accessor Array
        instance_variable_get(slot[:instance_variable_name]) << slot_instance
      else
        # Assign the Slot instance to the slot accessor
        instance_variable_set(slot[:instance_variable_name], slot_instance)
      end

      # Return nil, as this method shouldn't output anything to the view itself.
      nil
    end
  end
end
