# frozen_string_literal: true

module ViewComponent
  module Serializable
    # A proxy that wraps a component class and its initialization arguments, deferring
    # component instantiation until render time. This allows slot calls and other
    # post-initialize configuration to be captured and replayed, and enables the
    # proxy itself (rather than a live component instance) to be serialized for
    # background jobs (e.g. ActiveJob / Turbo Streams).
    class Proxy
      # Rebuilds a Proxy from a serialized hash produced by +serialize+
      def self.deserialize(hash)
        klass = hash["component_class"].safe_constantize
        raise ArgumentError, "Cannot deserialize unknown component: #{hash["component_class"]}" unless klass

        args = ActiveJob::Arguments.deserialize(hash["initialize_args"] || [])
        proxy = new(klass, *args)

        Array(hash["slot_calls"]).each do |call|
          method_name = call["method"].to_sym
          slot_args = ActiveJob::Arguments.deserialize(call["args"])
          proxy.public_send(method_name, *slot_args)
        end

        proxy
      end

      attr_reader :component_class, :initialize_args, :slot_calls

      def initialize(component_class, *args)
        @component_class = component_class
        @initialize_args = args
        @slot_calls = []
      end
      ruby2_keywords :initialize

      # Implements the Rails renderable interface
      def render_in(view_context, &block)
        if block
          raise UnserializableError, "Cannot serialize render_in with a block"
        end
        build_component.render_in(view_context)
      end

      def method_missing(method_name, *args, &block)
        if slot_method?(method_name)
          if block
            raise UnserializableError, "Cannot serialize slot call '#{method_name}' with a block"
          end
          @slot_calls << {method: method_name, args: args}
          self
        else
          super
        end
      end
      ruby2_keywords :method_missing

      def respond_to_missing?(method_name, include_private = false)
        slot_method?(method_name) || super
      end

      # Returns a hash that can be rebuilt into a Proxy instance using +deserialize+
      def serialize
        serialized_slot_calls = @slot_calls.map do |call|
          {
            "method" => call[:method].to_s,
            "args" => ActiveJob::Arguments.serialize(call[:args])
          }
        end

        {
          "component_class" => @component_class.name,
          "initialize_args" => ActiveJob::Arguments.serialize(@initialize_args),
          "slot_calls" => serialized_slot_calls
        }
      end

      private

      def slot_method?(method_name)
        method_name.to_s.start_with?("with_") && @component_class.method_defined?(method_name)
      end

      def build_component
        @component_class.new(*@initialize_args).tap do |instance|
          @slot_calls.each do |call|
            instance.public_send(call[:method], *call[:args])
          end
        end
      end
    end
  end
end
