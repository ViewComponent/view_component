# frozen_string_literal: true

module ViewComponent
  module DelegatedSlots
    SlotTarget = Struct.new(:target, :block, :collection, keyword_init: true) do
      alias collection? collection
    end

    SlotTargetRef = Struct.new(:slot_target, :singular_name, :plural_name, keyword_init: true) do
      delegate :target, :block, :collection?, to: :slot_target
    end

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module Utils
      class << self
        def find_slot_target(component, slot_name)
          singular_name = slot_name.to_s.singularize.to_sym
          plural_name = slot_name.to_s.pluralize.to_sym

          slot_target =
            component.class.__vc_delegated_slot_targets[singular_name] ||
            component.class.__vc_delegated_slot_targets[plural_name]

          return unless slot_target

          SlotTargetRef.new(
            slot_target: slot_target,
            singular_name: singular_name,
            plural_name: plural_name
          )
        end
      end
    end

    module InstanceMethods
      def method_missing(method_name, *args, &slot_block)
        slot_target = Utils.find_slot_target(self, method_name)
        return super unless slot_target

        # collection/non-collection setter containing with_* prefix
        self.class.define_method(:"with_#{slot_target.singular_name}") do |*args|
          set_delegated_slot(slot_target, *args, &slot_block)
        end
        if self.class.respond_to?(:ruby2_keywords, true)
          self.class.send(:ruby2_keywords, :"with_#{slot_target.singular_name}")
        end

        if slot_target.collection?
          # collection setter
          self.class.define_method(slot_target.singular_name) do |*args|
            # Deprecated: Will remove in 3.0
            set_delegated_slot(slot_target, *args, &slot_block)
          end

          # collection getter
          self.class.define_method(slot_target.plural_name) do
            get_delegated_slot(slot_target)
          end
        else
          # non-collection getter/setter combo
          self.class.define_method(slot_target.singular_name) do |*args|
            if args.empty? && slot_block.nil?
              get_delegated_slot(slot_target)
            else
              # Deprecated: Will remove in 3.0
              set_delegated_slot(slot_target, *args, &slot_block)
            end
          end
        end
        self.class.send(:ruby2_keywords, slot_target.singular_name) if self.class.respond_to?(:ruby2_keywords, true)

        send(method_name, *args, &slot_block)
      end
      ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

      def respond_to?(method_name, _include_private = false)
        Utils.find_slot_target(self, method_name) || super
      end

      def respond_to_missing?(method_name, _include_private = false)
        Utils.find_slot_target(self, method_name) || super
      end

      private

      def get_delegated_slot(slot_target)
        content unless content_evaluated? # ensure content is loaded so slots will be defined
        target_obj = instance_eval(slot_target.target.to_s)

        if slot_target.collection?
          target_obj.send(slot_target.plural_name)
        else
          target_obj.send(slot_target.singular_name)
        end
      end

      def set_delegated_slot(slot_target, *args, &slot_block)
        callback_block = ->(*mod_args) {
          target_obj = instance_eval(slot_target.target.to_s)
          target_obj.send(slot_target.singular_name, *mod_args, &slot_block)
        }
        callback_block.send(:ruby2_keywords)

        slot_target.block.call(*args, &callback_block)
      end
    end

    module ClassMethods
      def __vc_delegated_slot_targets
        @__vc_delegated_slot_targets ||= {}
      end

      def delegate_renders_one(slot, to:, &block)
        block.ruby2_keywords if block.respond_to?(:ruby2_keywords, true)
        __vc_delegated_slot_targets[slot] = SlotTarget.new(target: to, block: block, collection: false)
      end

      def delegate_renders_many(slot, to:, &block)
        block.ruby2_keywords if block.respond_to?(:ruby2_keywords, true)
        __vc_delegated_slot_targets[slot] = SlotTarget.new(target: to, block: block, collection: true)
      end
    end
  end
end
