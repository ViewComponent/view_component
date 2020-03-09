 # frozen_string_literal: true

# This test exists to make sure the old APIs still work while we transition to the new
# name for the gem.

class ActionView::ComponentTest < ActionView::Component::TestCase
  def test_checks_validations
    exception = assert_raises ActiveModel::ValidationError do
      render_inline(ActionViewComponent.new)
    end

    assert_includes exception.message, "Content can't be blank"
  end

  def test_render_inline
    render_inline(ActionViewComponent.new) { "hello,world!" }

    assert_selector("span", text: "hello,world!")
  end

  def test_render_inline_with_class_syntax
    render_inline(ActionViewComponent) { "hello,world!" }

    assert_selector("span", text: "hello,world!")
  end

  def test_render_inline_with_hash_syntax
    render_inline(component: ActionViewComponent) { "hello,world!" }

    assert_selector("span", text: "hello,world!")
  end

  def test_to_component_class
    post = Post.new(title: "Awesome post")

    render_inline(post).to_html

    assert_selector("span", text: "The Awesome post component!")
  end

  def test_render_inline_with_old_helper
    render_component(ActionViewComponent.new)

    assert_selector("div", text: "hello,world!")
  end
end
