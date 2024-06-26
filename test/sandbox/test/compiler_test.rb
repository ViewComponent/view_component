# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class CompilerTest < TestCase
    def test_generates_sub_template_methods
      primary_template = SubTemplatesComponent.public_instance_method(:call)
      assert_empty primary_template.parameters

      list_template = SubTemplatesComponent.instance_method(:render_list_template)
      assert_includes SubTemplatesComponent.private_instance_methods, :render_list_template, "Render method is not private"
      assert_equal [[:keyreq, :number]], list_template.parameters

      list_template = SubTemplatesComponent.instance_method(:render_ordered_list_template)
      assert_includes SubTemplatesComponent.private_instance_methods, :render_ordered_list_template, "Render method is not private"
      assert_equal [[:keyreq, :number]], list_template.parameters

      summary_template = SubTemplatesComponent.instance_method(:render_summary_template)
      assert_includes SubTemplatesComponent.private_instance_methods, :render_summary_template, "Render method is not private"
      assert_equal [[:keyreq, :string]], summary_template.parameters
    end
  end
end
