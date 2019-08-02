require "test_helper"
require_relative "../fixtures/components/test_component"

class ActionView::ComponentTest < Minitest::Test
  def test_render_component
    result = render_component(TestComponent.new)

    assert_equal trim_result(result.css("div").first.to_html), "<div>hello,world!</div>"
  end

  def trim_result(html)
    html.delete(" \t\r\n")
  end
end
