module ViewComponent
  module SlotableDefault
    def get_slot(slot_name)
      @__vc_set_slots ||= {}

      return super unless !@__vc_set_slots[slot_name] && (default_method = registered_slots[slot_name][:default_method])

      renderable_value = send(default_method)
      slot = Slot.new(self)

      if renderable_value.respond_to?(:render_in)
        slot.__vc_component_instance = renderable_value
      else
        slot.__vc_content = renderable_value
      end

      slot
    end
  end
end
