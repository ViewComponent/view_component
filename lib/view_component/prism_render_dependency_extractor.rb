# frozen_string_literal: true

require "prism"

module ViewComponent
  class PrismRenderDependencyExtractor
    def initialize(code)
      @code = code
      @dependencies = []
    end

    def extract
      root = Prism.parse(@code).value
      walk(root) if root
      @dependencies
    end

    private

    def walk(node)
      stack = [node]

      until stack.empty?
        current = stack.pop
        next unless current.is_a?(Prism::Node)

        extract_render_target(current) if current.is_a?(Prism::CallNode) && render_call?(current)

        children = current.child_nodes
        next if children.empty?

        children.reverse_each { |child| stack << child if child }
      end
    end

    def render_call?(node)
      node.receiver.nil? && node.name == :render
    end

    def extract_render_target(node)
      first_arg = node.arguments&.arguments&.first
      return unless first_arg.is_a?(Prism::CallNode) && first_arg.name == :new

      receiver = first_arg.receiver
      return unless receiver.is_a?(Prism::ConstantPathNode) || receiver.is_a?(Prism::ConstantReadNode)

      @dependencies << extract_constant_path(receiver)
    end

    def extract_constant_path(const_node)
      const_node.location.slice
    end
  end
end
