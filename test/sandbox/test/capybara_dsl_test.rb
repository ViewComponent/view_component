# frozen_string_literal: true

require "test_helper"

class CapybaraDslTest < ViewComponent::TestCase
  setup do
    render_inline(CapybaraDslComponent.new)
  end

  def table
    @table ||= find("table")
  end

  test "within" do
    within(table) do
      assert_selector("thead")
    end
  end

  test "within with no matching selector" do
    within(table.find("thead")) do
      assert_no_selector("td")
    end
  end

  test "page#native" do
    assert_match(/table/, page.native.serialize)
  end

  test "within_fieldset" do
    within_fieldset "Account" do
      assert_selector("#username")
    end
  end

  test "within_table" do
    within_table "Content" do
      assert_selector("tbody")
    end
  end

  test "text" do
    assert_includes text, "Name"
  end

  %i[all find_all].each do |method|
    test method.to_s do
      assert_not_empty send(method, "table")
    end
  end

  {
    first: "table",
    find: "table",
    find_button: "my_button",
    find_by_id: "my_button",
    find_field: "Checked field",
    find_link: "My link"
  }.each do |method, argument|
    test method.to_s do
      assert_not_nil send(method, argument)
    end
  end

  {
    has_content?: "Name",
    has_text?: "Name",
    has_css?: "table",
    has_no_content?: "non existing",
    has_no_text?: "non existing",
    has_no_css?: "non-existing-element",
    has_no_xpath?: "//non-existing-element",
    has_xpath?: "//table",
    has_link?: "My link",
    has_no_link?: "non existing",
    has_button?: "My button",
    has_no_button?: "non existing",
    has_field?: "Checked field",
    has_no_field?: "non existing",
    has_no_table?: "non existing",
    has_table?: "Content",
    has_select?: "Select field",
    has_no_select?: "non existing",
    has_selector?: "table",
    has_no_selector?: "non-existing-element",
    has_checked_field?: "Checked field",
    has_unchecked_field?: "Unchecked field",
    has_no_checked_field?: "non existing",
    has_no_unchecked_field?: "non existing"
  }.each do |method, argument|
    test method.to_s do
      assert send(method, argument)
    end
  end

  test "assert_link" do
    assert_link "My link"
  end
end
