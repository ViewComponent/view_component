# frozen_string_literal: true

require "prism"

module ViewComponent
  class PrismRenderDependencyExtractor
    def initialize(code)
      @code = code
      @dependencies = []
    end

    def extract
      result = Prism.parse(@code)
      walk(result.value)
      @dependencies
    end

    private

    def walk(node)
      return unless node.respond_to?(:child_nodes)

      if node.is_a?(Prism::CallNode) && render_call?(node)
        extract_render_target(node)
      end

      node.child_nodes.each { |child| walk(child) if child }
    end

    def render_call?(node)
      node.receiver.nil? && node.name == :render
    end

    def extract_render_target(node)
      args = node.arguments&.arguments
      return unless args && !args.empty?

      first_arg = args.first

      if first_arg.is_a?(Prism::CallNode) &&
          first_arg.name == :new &&
          first_arg.receiver.is_a?(Prism::ConstantPathNode) || first_arg.receiver.is_a?(Prism::ConstantReadNode)

        const = extract_constant_path(first_arg.receiver)
        @dependencies << const if const
      end
    end

    def extract_constant_path(const_node)
      parts = []
      current = const_node

      while current
        case current
        when Prism::ConstantPathNode
          parts.unshift(current.child.name)
          current = current.parent
        when Prism::ConstantReadNode
          parts.unshift(current.name)
          break
        else
          break
        end
      end

      parts.join("::")
    end
  end
end
