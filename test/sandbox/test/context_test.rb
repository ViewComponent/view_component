# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class ContextTest < TestCase
    class SlotComponent < ViewComponent::Base
      def call
        use_context(:test) do |test_context|
          content_tag(:div, data: { kind: "slot" }) do
            "Slot context set: #{test_context[:context_param]}"
          end
        end
      end
    end

    class GrandparentComponent < ViewComponent::Base
      renders_one :slot, SlotComponent

      def call
        content_tag(:div, data: { kind: "grandparent" }) do
          render(ParentComponent.new) + slot.to_s
        end
      end

      private

      def around_render(&block)
        provide_context(:test, { context_param: "foobar" }, &block)
      end
    end

    class ParentComponent < ViewComponent::Base
      def call
        content_tag(:div, data: { kind: "parent" }) do
          render(ChildComponent.new)
        end
      end
    end

    class ChildComponent < ViewComponent::Base
      def call
        use_context(:test) do |test_context|
          content_tag(:div, data: { kind: "child" }) do
            "Test context set: #{test_context[:context_param]}"
          end
        end
      end
    end

    def test_context_passed_multiple_levels
      render_inline(GrandparentComponent.new) do |grandparent|
        grandparent.with_slot
      end

      assert_selector("[data-kind=grandparent]") do |grandparent|
        grandparent.assert_selector("[data-kind=slot]", text: "Slot context set: foobar")

        grandparent.assert_selector("[data-kind=parent]") do |parent|
          parent.assert_selector("[data-kind=child]", text: "Test context set: foobar")
        end
      end
    end

    def test_context_can_be_provided_at_class_level
      ParentComponent.provide_context(:test, { context_param: "context from class" }) do
        render_inline(ParentComponent.new)
      end

      assert_selector("[data-kind=parent]") do |parent|
        parent.assert_selector("[data-kind=child]", text: "Test context set: context from class")
      end
    end
  end
end
