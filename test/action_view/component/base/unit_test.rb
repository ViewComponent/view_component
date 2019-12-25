# frozen_string_literal: true

require "test_helper"

class ActionView::Component::Base::UnitTest < Minitest::Test
  def test_templates_parses_all_types_of_paths
    file_path = [
      "/Users/fake.user/path/to.templates/component/test_component.html+phone.erb",
      "/_underscore-dash./component/test_component.html+desktop.slim",
      "/tilda~/component/test_component.html.haml"
    ]
    expected = [
      {variant: :phone, handler: "erb"},
      {variant: :desktop, handler: "slim"},
      {variant: nil, handler: "haml"}
    ]

    ActionView::Component::Base.stub(:matching_views_in_source_location, file_path) do
      templates = ActionView::Component::Base.send(:templates)

      templates.each_with_index do |template, index|
        assert_equal(template[:path], file_path[index])
        assert_equal(template[:variant], expected[index][:variant])
        assert_equal(template[:handler], expected[index][:handler])
      end
    end
  end
end
