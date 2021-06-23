# frozen_string_literal: true

require "test_helper"

class LocalizedTest < ViewComponent::TestCase
  def test_render_component_in_two_languages
    render_inline(MyComponent.new)
    assert_text("hello,world!")

    with_custom_config("I18n.locale = :es") do
      render_inline(MyComponent.new)
      assert_text("Hola,mundo!")
    end

    render_inline(MyComponent.new)
    assert_text("hello,world!")
  end

  # some regional locales (pt-BR, en-GB...) contains a dash and
  # and functions names can't have name dashs... :thinking:
  def test_render_component_with_dashed_language
    render_inline(MyComponent.new)
    assert_text("hello,world!")

    with_custom_config("I18n.locale = 'pt-BR'") do
      render_inline(MyComponent.new)
      assert_text("olá,mundo!")
    end

    render_inline(MyComponent.new)
    assert_text("hello,world!")
  end

  def test_render_component_methods
    methods = MyComponent.new.methods.grep(/call/)
    assert_includes methods, :call
    assert_includes methods, :call_es
    assert_includes methods, :call_pt_br
  end

  # def test_render_component_localized_with_custom_view
  # end

  # def test_render_component_localized_with_variants
  # end

end
