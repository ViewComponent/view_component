# frozen_string_literal: true

module ViewComponent
  module PolymorphicSlots
    # In older rails versions, using a concern isn't a good idea here because they appear to not work with
    # Module#prepend and class methods.
    def self.included(base)
      if base != ViewComponent::Base
        # :nocov:
        location = Kernel.caller_locations(1, 1)[0]

        warn(
          "warning: ViewComponent::PolymorphicSlots is now included in ViewComponent::Base by default " \
          "and can be removed from #{location.path}:#{location.lineno}"
        )
        # :nocov:
      end

      base.singleton_class.prepend(ClassMethods)
      base.include(InstanceMethods)
    end

    module ClassMethods
      def renders_one(slot_name, callable = nil)
        return super unless callable.is_a?(Hash) && callable.key?(:types)

        validate_singular_slot_name(slot_name)
        register_polymorphic_slot(slot_name, callable[:types], collection: false)
      end

      def renders_many(slot_name, callable = nil)
        return super unless callable.is_a?(Hash) && callable.key?(:types)

        validate_plural_slot_name(slot_name)
        register_polymorphic_slot(slot_name, callable[:types], collection: true)
      end

      def register_polymorphic_slot(slot_name, types, collection:)
        unless types.empty?
          getter_name = slot_name

          define_method(getter_name) do
            get_slot(slot_name)
          end

          define_method("#{getter_name}?") do
            get_slot(slot_name).present?
          end
        end

        renderable_hash = types.each_with_object({}) do |(poly_type, poly_callable), memo|
          memo[poly_type] = define_slot(
            "#{slot_name}_#{poly_type}", collection: collection, callable: poly_callable
          )

          setter_name =
            if collection
              "#{ActiveSupport::Inflector.singularize(slot_name)}_#{poly_type}"
            else
              "#{slot_name}_#{poly_type}"
            end

          define_method(setter_name) do |*args, &block|
            if _warn_on_deprecated_slot_setter
              ViewComponent::Deprecation.warn(
                "polymorphic slot setters like `#{setter_name}` are deprecated and will be removed in " \
                "ViewComponent v3.0.0.\n\nUse `with_#{setter_name}` instead."
              )
            end

            set_polymorphic_slot(slot_name, poly_type, *args, &block)
          end
          ruby2_keywords(setter_name.to_sym) if respond_to?(:ruby2_keywords, true)

          define_method("with_#{setter_name}") do |*args, &block|
            set_polymorphic_slot(slot_name, poly_type, *args, &block)
          end
          ruby2_keywords(:"with_#{setter_name}") if respond_to?(:ruby2_keywords, true)
        end

        registered_slots[slot_name] = {
          collection: collection,
          renderable_hash: renderable_hash
        }
      end
    end

    module InstanceMethods
      def set_polymorphic_slot(slot_name, poly_type = nil, *args, &block)
        slot_definition = self.class.registered_slots[slot_name]

        if !slot_definition[:collection] && get_slot(slot_name)
          raise ArgumentError, "content for slot '#{slot_name}' has already been provided"
        end

        poly_def = slot_definition[:renderable_hash][poly_type]

        set_slot(slot_name, poly_def, *args, &block)
      end
      ruby2_keywords(:set_polymorphic_slot) if respond_to?(:ruby2_keywords, true)
    end
  end
end
