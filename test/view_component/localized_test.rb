# frozen_string_literal: true

require "test_helper"

class LocalizedTest < ViewComponent::TestCase
  def test_render_component_in_two_languages
    render_inline(MyComponent.new)
    assert_text("hello,world!")

    with_locale(:es) do
      render_inline(MyComponent.new)
      assert_text("Hola,mundo!")
    end

    render_inline(MyComponent.new)
    assert_text("hello,world!")
  end

  def test_render_component_with_dashed_regional_locale_name
    with_locale('pt-BR') do
      render_inline(MyComponent.new)
      assert_text("olá,mundo!")
    end
  end

  def test_render_component_fallback
    with_locale('ru') do
      render_inline(MyComponent.new)
      assert_text("hello,world!")
    end
  end

  def test_render_component_with_default_locale
    assert I18n.locale, :en
    assert I18n.default_locale, :en

    with_locale('pt-BR', :es) do
      render_inline(MyComponent.new)
      assert_text("olá,mundo!")
    end

    # if both locale and default_locale are equal, we use 'component_name.html.erb'
    with_locale(:es, :es) do
      render_inline(MiComponente.new)
      assert_text("hola,mundo!")
    end
  end

  def test_render_component_methods
    methods = MyComponent.new.methods.grep(/call/)
    assert_includes methods, :call
    assert_includes methods, :call_es
    assert_includes methods, :call_pt_br
  end

  def test_render_component_localized_with_variant
    with_locale('pt-BR') do
      render_inline(VariantsComponent.new.with_variant(:phone))
      assert_text("Telefone")
    end
  end
end
