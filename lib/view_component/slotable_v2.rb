# frozen_string_literal: true

require "active_support/concern"
require "view_component/slot_v2"

module ViewComponent
  module SlotableV2
    extend ActiveSupport::Concern

    RESERVED_NAMES = {
      singular: %i[content render].freeze,
      plural: %i[contents renders].freeze
    }.freeze

    # Setup component slot state
    included do
      # Hash of registered Slots
      class_attribute :registered_slots
      self.registered_slots = {}

      class_attribute :_warn_on_deprecated_slot_setter
      self._warn_on_deprecated_slot_setter = false
    end

    class_methods do
      ##
      # Enables deprecations coming to the Slots API in ViewComponent v3
      #
      def warn_on_deprecated_slot_setter
        self._warn_on_deprecated_slot_setter = true
      end

      ##
      # Registers a sub-component
      #
      # = Example
      #
      #   renders_one :header -> (classes:) do
      #     HeaderComponent.new(classes: classes)
      #   end
      #
      #   # OR
      #
      #   renders_one :header, HeaderComponent
      #
      #   where `HeaderComponent` is defined as:
      #
      #   class HeaderComponent < ViewComponent::Base
      #     def initialize(classes:)
      #       @classes = classes
      #     end
      #   end
      #
      #   and has the following template:
      #
      #   <header class="<%= @classes %>">
      #     <%= content %>
      #   </header>
      #
      # = Rendering sub-component content
      #
      # The component's sidecar template can access the sub-component by calling a
      # helper method with the same name as the sub-component.
      #
      #   <h1>
      #     <%= header do %>
      #       My header title
      #     <% end %>
      #   </h1>
      #
      # = Setting sub-component content
      #
      # Consumers of the component can render a sub-component by calling a
      # helper method with the same name as the slot prefixed with `with_`.
      #
      #   <%= render_inline(MyComponent.new) do |component| %>
      #     <% component.with_header(classes: "Foo") do %>
      #       <p>Bar</p>
      #     <% end %>
      #   <% end %>
      def renders_one(slot_name, callable = nil)
        validate_singular_slot_name(slot_name)
        validate_plural_slot_name(ActiveSupport::Inflector.pluralize(slot_name).to_sym)

        define_method :"with_#{slot_name}" do |*args, &block|
          set_slot(slot_name, nil, *args, &block)
        end
        ruby2_keywords(:"with_#{slot_name}") if respond_to?(:ruby2_keywords, true)

        define_method slot_name do |*args, &block|
          if args.empty? && block.nil?
            get_slot(slot_name)
          else
            if _warn_on_deprecated_slot_setter
              stack = caller_locations(3)
              msg = "Setting a slot with `##{slot_name}` is deprecated and will be removed in ViewComponent v3.0.0. " \
                "Use `#with_#{slot_name}` to set the slot instead."

              ViewComponent::Deprecation.warn(msg, stack)
            end

            set_slot(slot_name, nil, *args, &block)
          end
        end
        ruby2_keywords(slot_name.to_sym) if respond_to?(:ruby2_keywords, true)

        define_method "#{slot_name}?" do
          get_slot(slot_name).present?
        end

        register_slot(slot_name, collection: false, callable: callable)
      end

      ##
      # Registers a collection sub-component
      #
      # = Example
      #
      #   renders_many :items, -> (name:) { ItemComponent.new(name: name }
      #
      #   # OR
      #
      #   renders_many :items, ItemComponent
      #
      # = Rendering sub-components
      #
      # The component's sidecar template can access the slot by calling a
      # helper method with the same name as the slot.
      #
      #   <h1>
      #     <% items.each do |item| %>
      #       <%= item %>
      #     <% end %>
      #   </h1>
      #
      # = Setting sub-component content
      #
      # Consumers of the component can set the content of a slot by calling a
      # helper method with the same name as the slot prefixed with `with_`. The
      # method can be called multiple times to append to the slot.
      #
      #   <%= render_inline(MyComponent.new) do |component| %>
      #     <% component.with_item(name: "Foo") do %>
      #       <p>One</p>
      #     <% end %>
      #
      #     <% component.with_item(name: "Bar") do %>
      #       <p>two</p>
      #     <% end %>
      #   <% end %>
      def renders_many(slot_name, callable = nil)
        singular_name = ActiveSupport::Inflector.singularize(slot_name)
        validate_plural_slot_name(slot_name)
        validate_singular_slot_name(ActiveSupport::Inflector.singularize(slot_name).to_sym)

        # Define setter for singular names
        # for example `renders_many :items` allows fetching all tabs with
        # `component.tabs` and setting a tab with `component.tab`

        define_method singular_name do |*args, &block|
          if _warn_on_deprecated_slot_setter
            ViewComponent::Deprecation.warn(
              "Setting a slot with `##{singular_name}` is deprecated and will be removed in ViewComponent v3.0.0. " \
              "Use `#with_#{singular_name}` to set the slot instead."
            )
          end

          set_slot(slot_name, nil, *args, &block)
        end
        ruby2_keywords(singular_name.to_sym) if respond_to?(:ruby2_keywords, true)

        define_method :"with_#{singular_name}" do |*args, &block|
          set_slot(slot_name, nil, *args, &block)
        end
        ruby2_keywords(:"with_#{singular_name}") if respond_to?(:ruby2_keywords, true)

        define_method :"with_#{slot_name}" do |collection_args = nil, &block|
          collection_args.map do |args|
            set_slot(slot_name, nil, **args, &block)
          end
        end

        # Instantiates and and adds multiple slots forwarding the first
        # argument to each slot constructor
        define_method slot_name do |collection_args = nil, &block|
          if collection_args.nil? && block.nil?
            get_slot(slot_name)
          else
            if _warn_on_deprecated_slot_setter
              ViewComponent::Deprecation.warn(
                "Setting a slot with `##{slot_name}` is deprecated and will be removed in ViewComponent v3.0.0. " \
                "Use `#with_#{slot_name}` to set the slot instead."
              )
            end

            collection_args.map do |args|
              set_slot(slot_name, nil, **args, &block)
            end
          end
        end

        define_method "#{slot_name}?" do
          get_slot(slot_name).present?
        end

        register_slot(slot_name, collection: true, callable: callable)
      end

      def slot_type(slot_name)
        registered_slot = registered_slots[slot_name]
        if registered_slot
          registered_slot[:collection] ? :collection : :single
        else
          plural_slot_name = ActiveSupport::Inflector.pluralize(slot_name).to_sym
          plural_registered_slot = registered_slots[plural_slot_name]
          plural_registered_slot&.fetch(:collection) ? :collection_item : nil
        end
      end

      # Clone slot configuration into child class
      # see #test_slots_pollution
      def inherited(child)
        child.registered_slots = registered_slots.clone
        super
      end

      private

      def register_slot(slot_name, **kwargs)
        registered_slots[slot_name] = define_slot(slot_name, **kwargs)
      end

      def define_slot(slot_name, collection:, callable:)
        # Setup basic slot data
        slot = {
          collection: collection
        }
        return slot unless callable

        # If callable responds to `render_in`, we set it on the slot as a renderable
        if callable.respond_to?(:method_defined?) && callable.method_defined?(:render_in)
          slot[:renderable] = callable
        elsif callable.is_a?(String)
          # If callable is a string, we assume it's referencing an internal class
          slot[:renderable_class_name] = callable
        elsif callable.respond_to?(:call)
          # If slot doesn't respond to `render_in`, we assume it's a proc,
          # define a method, and save a reference to it to call when setting
          method_name = :"_call_#{slot_name}"
          define_method method_name, &callable
          slot[:renderable_function] = instance_method(method_name)
        else
          raise(
            ArgumentError,
            "invalid slot definition. Please pass a class, string, or callable (i.e. proc, lambda, etc)"
          )
        end

        slot
      end

      def validate_plural_slot_name(slot_name)
        if RESERVED_NAMES[:plural].include?(slot_name.to_sym)
          raise ArgumentError.new(
            "#{self} declares a slot named #{slot_name}, which is a reserved word in the ViewComponent framework.\n\n" \
            "To fix this issue, choose a different name."
          )
        end

        raise_if_slot_ends_with_question_mark(slot_name)
        raise_if_slot_registered(slot_name)
      end

      def validate_singular_slot_name(slot_name)
        if slot_name.to_sym == :content
          raise ArgumentError.new(
            "#{self} declares a slot named content, which is a reserved word in ViewComponent.\n\n" \
            "Content passed to a ViewComponent as a block is captured and assigned to the `content` accessor without having to create an explicit slot.\n\n" \
            "To fix this issue, either use the `content` accessor directly or choose a different slot name."
          )
        end

        if RESERVED_NAMES[:singular].include?(slot_name.to_sym)
          raise ArgumentError.new(
            "#{self} declares a slot named #{slot_name}, which is a reserved word in the ViewComponent framework.\n\n" \
            "To fix this issue, choose a different name."
          )
        end

        raise_if_slot_ends_with_question_mark(slot_name)
        raise_if_slot_registered(slot_name)
      end

      def raise_if_slot_registered(slot_name)
        if registered_slots.key?(slot_name)
          # TODO remove? This breaks overriding slots when slots are inherited
          raise ArgumentError.new(
            "#{self} declares the #{slot_name} slot multiple times.\n\n" \
            "To fix this issue, choose a different slot name."
          )
        end
      end

      def raise_if_slot_ends_with_question_mark(slot_name)
        if slot_name.to_s.ends_with?("?")
          raise ArgumentError.new(
            "#{self} declares a slot named #{slot_name}, which ends with a question mark.\n\n" \
            "This is not allowed because the ViewComponent framework already provides predicate " \
            "methods ending in `?`.\n\n" \
            "To fix this issue, choose a different name."
          )
        end
      end
    end

    def get_slot(slot_name)
      content unless content_evaluated? # ensure content is loaded so slots will be defined

      slot = self.class.registered_slots[slot_name]
      @__vc_set_slots ||= {}

      if @__vc_set_slots[slot_name]
        return @__vc_set_slots[slot_name]
      end

      if slot[:collection]
        []
      end
    end

    def set_slot(slot_name, slot_definition = nil, *args, &block)
      slot_definition ||= self.class.registered_slots[slot_name]
      slot = SlotV2.new(self)

      # Passing the block to the sub-component wrapper like this has two
      # benefits:
      #
      # 1. If this is a `content_area` style sub-component, we will render the
      # block via the `slot`
      #
      # 2. Since we've to pass block content to components when calling
      # `render`, evaluating the block here would require us to call
      # `view_context.capture` twice, which is slower
      slot.__vc_content_block = block if block

      # If class
      if slot_definition[:renderable]
        slot.__vc_component_instance = slot_definition[:renderable].new(*args)
      # If class name as a string
      elsif slot_definition[:renderable_class_name]
        slot.__vc_component_instance =
          self.class.const_get(slot_definition[:renderable_class_name]).new(*args)
      # If passed a lambda
      elsif slot_definition[:renderable_function]
        # Use `bind(self)` to ensure lambda is executed in the context of the
        # current component. This is necessary to allow the lambda to access helper
        # methods like `content_tag` as well as parent component state.
        renderable_function = slot_definition[:renderable_function].bind(self)
        renderable_value =
          if block
            renderable_function.call(*args) do |*rargs|
              view_context.capture(*rargs, &block)
            end
          else
            renderable_function.call(*args)
          end

        # Function calls can return components, so if it's a component handle it specially
        if renderable_value.respond_to?(:render_in)
          slot.__vc_component_instance = renderable_value
        else
          slot.__vc_content = renderable_value
        end
      end

      @__vc_set_slots ||= {}

      if slot_definition[:collection]
        @__vc_set_slots[slot_name] ||= []
        @__vc_set_slots[slot_name].push(slot)
      else
        @__vc_set_slots[slot_name] = slot
      end

      slot
    end
    ruby2_keywords(:set_slot) if respond_to?(:ruby2_keywords, true)
  end
end
