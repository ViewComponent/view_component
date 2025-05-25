# frozen_string_literal: true

module ViewComponent
  module ContextProvider
    class EmptyContext
      include Singleton

      def [](_key)
        nil
      end
    end

    class Context
      def initialize(stack)
        @stack = stack
      end

      def [](key)
        @stack.reverse_each do |context_hash|
          if context_hash.include?(key)
            return context_hash[key]
          end
        end

        nil
      end
    end

    class ContextStack
      attr_reader :context

      def initialize
        @stack = []
        @context = Context.new(@stack)
      end

      def push(context_hash)
        @stack << context_hash
      end

      def pop
        @stack.pop
      end
    end

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
      base.prepend(InstanceMethodOverrides)
    end

    module ContextMethods
      attr_accessor :__vc_context

      def provide_context(name, context_hash)
        @__vc_context ||= {}
        @__vc_context[name] ||= ContextStack.new
        @__vc_context[name].push(context_hash)
        yield
      ensure
        @__vc_context[name].pop
      end

      def use_context(name)
        @__vc_context ||= {}
        yield @__vc_context[name]&.context || EmptyContext.instance
      end
    end

    module ClassMethods
      include ContextMethods

      def new(*args, **kwargs, &block)
        super.tap do |instance|
          instance.__vc_context = __vc_context
        end
      end
    end

    # :nodoc:
    module InstanceMethods
      include ContextMethods

      def around_render
        yield
      end
    end

    # :nodoc:
    module InstanceMethodOverrides
      def render_in(*args, &block)
        result = nil
        around_render_yielded = false

        around_render do
          result = super
          around_render_yielded = true
        end

        unless around_render_yielded
          warn "WARNING: `around_render' did not yield in #{self.class}"
        end

        result
      end

      def render(component = nil, *args, **kwargs, &block)
        if component.respond_to?(:__vc_context)
          component.__vc_context = __vc_context
        end

        if component
          super
        else
          super(*args, **kwargs, &block)
        end
      end

      def content
        super.tap do
          self.class.registered_slots.each do |slot_name, _slot_def|
            slots = Array((@__vc_set_slots || {})[slot_name])
            slots.each do |slot|
              if slot.respond_to?(:__vc_context=)
                slot.__vc_context = __vc_context
              end
            end
          end
        end
      end
    end
  end
end
