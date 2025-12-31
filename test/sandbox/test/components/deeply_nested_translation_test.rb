# frozen_string_literal: true

require "test_helper"

# Tests that translations in deeply nested component blocks (3+ levels) resolve to the
# partial's scope, not an intermediate component's scope.
#
# This pattern is inspired by Primer's ActionMenu → ActionList → Item hierarchy.
class DeeplyNestedTranslationTest < ViewComponent::TestCase
  # Tests 3 levels of nesting with typical ViewComponent slot pattern
  #
  # Structure:
  #   Partial (_action_menu_panel.html.erb)
  #     └─> ActionMenuComponent (Level 1)
  #         └─> menu.with_list → ActionListComponent (Level 2)
  #             └─> list.with_item → MenuItemComponent (Level 3)
  #                 └─> t(".menu_action") ← Translation should resolve to partial's scope
  #
  # This uses the standard ViewComponent slot DSL:
  #   menu.with_list creates an ActionListComponent slot
  #   list.with_item creates a MenuItemComponent slot
  #
  # Without the fix, the translation would incorrectly resolve to ActionListComponent's
  # scope instead of the partial's scope.
  def test_translation_in_3_level_nested_blocks
    result = render_inline(ActionMenuPanelWrapperComponent.new)

    assert_includes result.to_html, "Menu Action from Partial"
  end

  # Tests 5 levels of nesting to prove the fix works for arbitrary depth
  #
  # Structure:
  #   Partial (_deep_navigation.html.erb)
  #     └─> SectionComponent (Level 1)
  #         └─> section.with_nav → NavComponent (Level 2)
  #             └─> nav.with_action_menu → ActionMenuComponent (Level 3)
  #                 └─> menu.with_list → ActionListComponent (Level 4)
  #                     └─> list.with_item → MenuItemComponent (Level 5)
  #                         └─> t(".deep_action") ← Translation should resolve to partial's scope
  #
  # All using typical ViewComponent slot DSL with renders_one/renders_many.
  #
  # This demonstrates that the fix isn't just solving "one level deeper" than the original fix,
  # but works for any depth of nesting.
  def test_translation_in_5_level_nested_blocks
    result = render_inline(DeepNavigationWrapperComponent.new)

    assert_includes result.to_html, "Deep Action from Partial (5 levels!)"
  end
end
