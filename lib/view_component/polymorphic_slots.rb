# frozen_string_literal: true

module ViewComponent
  module PolymorphicSlots
    extend ActiveSupport::Concern

    class_methods do
      def register_slot(slot_name, collection:, callable:)
        if callable.is_a?(Hash)
          # If callable is a hash, we assume it's a polymorphic slot
          self.registered_slots[slot_name] = {
            collection: collection,
            renderable_hash: callable.each_with_object({}) do |(poly_name, poly_callable), memo|
              memo[poly_name] = define_slot(
                "#{slot_name}_#{poly_name}",
                collection: collection, callable: poly_callable
              )
            end
          }
        else
          super
        end
      end
    end

    def set_slot(slot_name, *args, **kwargs, &block)
      slot_definition = self.class.registered_slots[slot_name]

      if (renderable = slot_definition[:renderable_hash])
        poly_name, *rest = args

        if (poly_def = renderable[poly_name])
          super(slot_name, *rest, slot_definition: poly_def, **kwargs, &block)
        else
          raise ArgumentError.new(
            "'#{poly_name}' is not a member of the polymorphic slot '#{slot_name}'. "\
            "Members are: #{renderable.keys.map { |k| "'#{k}'" }.join(", ")}."
          )
        end
      else
        super
      end
    end
  end
end
