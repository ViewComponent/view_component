# frozen_string_literal: true

require "test_helper"

class JustJoshingReproComponentTest < ViewComponent::TestCase

  # Rendering the following:
  #
  # <%= render JustJoshingReproComponent.new do |c| %>
  #   <% c.with_slot1 do %>
  #     <%= render JustJoshingReproComponent.new do %>
  #       <%= "Content" %>
  #     <% end %>
  #   <% end %>
  # <% end %>
  #
  # in 'index.html.erb' produces the expected output with the following:
  #
  # <div data-test-selector="just-joshing-repro-component">
  #   <span data-test-selector="just-joshing-repro-component-heading">Component</span>
  #   <span data-test-selector="just-joshing-repro-component-slot-1"> -&gt; Slot1: </span>
  #   <div data-test-selector="just-joshing-repro-component">
  #     <span data-test-selector="just-joshing-repro-component-heading">Component</span>
  #     <span data-test-selector="just-joshing-repro-component-slot-2"> -&gt; Slot2: </span>
  #     <div data-test-selector="just-joshing-repro-component">
  #       <span data-test-selector="just-joshing-repro-component-heading">Component</span>
  #       <span data-test-selector="just-joshing-repro-component-content"> -&gt; Content: </span>
  #       Content
  #     </div>
  #   </div>
  # </div>
  #
  # However in the test it only seems to output:
  #
  # <div data-test-selector="just-joshing-repro-component">
  #   <span data-test-selector="just-joshing-repro-component-heading">Component</span>
  #   <span data-test-selector="just-joshing-repro-component-slot-1"> -&gt; Slot1: </span>
  #   <div data-test-selector="just-joshing-repro-component">
  #     <span data-test-selector="just-joshing-repro-component-heading">Component</span>
  #     <span data-test-selector="just-joshing-repro-component-slot-2"> -&gt; Slot2: </span>
  #   </div>
  # </div>
  #
  def test_repro
    render_inline JustJoshingReproComponent.new do |c|
      c.with_slot1 do
        render_inline JustJoshingReproComponent.new do
          "Content"
        end
      end
    end

    assert_selector "body > [data-test-selector='just-joshing-repro-component']", count: 1 do |component|
      component.assert_selector("> [data-test-selector='just-joshing-repro-component-heading']", count: 1)
      component.assert_selector("> [data-test-selector='just-joshing-repro-component-slot-1']", count: 1)
      component.assert_no_selector("> [data-test-selector='just-joshing-repro-component-slot-2']")
      component.assert_no_selector("> [data-test-selector='just-joshing-repro-component-content']")

      component.assert_selector("> [data-test-selector='just-joshing-repro-component']", count: 1) do |sub_component|
        sub_component.assert_selector("> [data-test-selector='just-joshing-repro-component-heading']", count: 1)
        sub_component.assert_no_selector("> [data-test-selector='just-joshing-repro-component-slot-1']")
        sub_component.assert_selector("> [data-test-selector='just-joshing-repro-component-slot-2']", count: 1)
        sub_component.assert_no_selector("> [data-test-selector='just-joshing-repro-component-content']", count: 1)

        # Failing here. We should see a third JustJoshingReproComponent that will render the "Content" string.
        sub_component.assert_selector("> [data-test-selector='just-joshing-repro-component']", count: 1)
      end
    end
  end
end
