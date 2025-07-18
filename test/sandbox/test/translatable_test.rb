# frozen_string_literal: true

require "test_helper"

class TranslatableTest < ViewComponent::TestCase
  def test_isolated_translations
    render_inline(TranslatableComponent.new)

    assert_selector("p.sidecar.shared-key", text: "Hello from sidecar translations!")
    assert_selector("p.sidecar.nested", text: "This is coming from the sidecar")
    assert_selector("p.sidecar.missing", text: "This is coming from Rails")

    assert_selector("p.helpers.shared-key", text: "Hello from Rails translations!")
    assert_selector("p.helpers.nested", text: "This is coming from Rails")

    assert_selector("p.global.shared-key", text: "Hello from Rails translations!")
    assert_selector("p.global.nested", text: "This is coming from Rails")
  end

  def test_isolated_translations_in_module
    render_inline(ExampleModule::TranslatableModuleComponent.new)

    assert_selector("p.sidecar.shared-key", text: "Hello from sidecar translations!")
    assert_selector("p.sidecar.nested", text: "This is coming from the sidecar")
    assert_selector("p.sidecar.missing", text: "This is coming from Rails")

    assert_selector("p.helpers.shared-key", text: "Hello from Rails translations!")
    assert_selector("p.helpers.nested", text: "This is coming from Rails")
    assert_selector("p.helpers.relative", text: "Relative key from Rails for module")

    assert_selector("p.global.shared-key", text: "Hello from Rails translations!")
    assert_selector("p.global.nested", text: "This is coming from Rails")
  end

  def test_multi_key_support
    assert_equal(
      [
        "Hello from sidecar translations!",
        "This is coming from the sidecar",
        "This is coming from Rails"
      ],
      translate(
        [
          ".hello",
          ".from.sidecar",
          "from.rails"
        ]
      )
    )
  end

  def test_relative_keys_missing_from_component_translations
    assert_equal "Relative key from Rails", translate(".relative_rails_key")
  end

  def test_symbol_keys
    assert_equal "Hello from sidecar translations!", translate(:".hello")
  end

  def test_converts_key_to_string_as_necessary
    klass = Struct.new(:to_s)
    key = klass.new(".hello")
    assert_equal "Hello from sidecar translations!", translate(key)
  end

  def test_translate_marks_translations_named_html_as_safe_html
    assert_equal "hello <em>world</em>!", translate(".html")
    assert_predicate translate(".html"), :html_safe?
  end

  def test_translate_marks_translations_with_a_html_suffix_as_safe_html
    assert_equal "Hello from <strong>sidecar translations</strong>!", translate(".hello_html")
    assert_predicate translate(".hello_html"), :html_safe?
  end

  def test_translate_with_html_suffix_escapes_interpolated_arguments
    translation = translate(".interpolated_html", horse_count: "<script type='text/javascript'>alert('foo');</script>")
    assert_equal(
      "There are &lt;script type=&#39;text/javascript&#39;&gt;alert(&#39;foo&#39;);&lt;/script&gt; horses in the " \
        "<strong>barn</strong>!",
      translation
    )
  end

  def test_translate_with_html_suffix_does_not_double_escape
    translation = translate(".interpolated_html", horse_count: "> 4")
    assert_equal(
      "There are &gt; 4 horses in the <strong>barn</strong>!",
      translation
    )
  end

  def test_translate_with_html_suffix_applies_reserved_options
    translation = translate(".hello_html", locale: :fr, raise: false)
    assert_equal(
      "Translation missing: fr.translatable_component.hello_html",
      translation
    )
  end

  def test_translate_uses_the_helper_when_no_sidecar_file_is_provided
    # The cache needs to be kept clean for TranslatableComponent, otherwise it will rely on the
    # already created i18n_backend.
    ViewComponent::CompileCache.invalidate_class!(TranslatableComponent)
    original_method = TranslatableComponent.method(:sidecar_files)

    ViewComponent::Base.stub(
      :sidecar_files,
      ->(exts) { exts.include?("yml") ? [] : original_method.call(exts) }
    ) do
      assert_equal "MISSING", translate(".hello", default: "MISSING")
      assert_equal "Hello from Rails translations!", translate("hello")
      assert_nil TranslatableComponent.__vc_i18n_backend
    end
  ensure
    ViewComponent::CompileCache.invalidate_class!(TranslatableComponent)
  end

  def test_default
    default_value = Object.new

    assert_equal default_value, translate(".missing", default: default_value)
    assert_equal default_value, translate("missing", default: default_value)
    assert_equal "Hello from Rails translations!", translate("hello", default: default_value)
    assert_equal "Hello from sidecar translations!", translate(".hello", default: default_value)
  end

  def test_translate_returns_lists
    assert_equal ["This", "returns", "a list"], translate(".list")
  end

  def test_translate_returns_html_safe_lists
    translated_list = translate(".list_html")

    assert_equal(
      [
        "<em>This</em>",
        "returns",
        "a list with <strong>embedded</strong> HTML"
      ],
      translated_list
    )

    translated_list.each do |item|
      assert_predicate item, :html_safe?
    end
  end

  def test_translate_scopes
    assert_equal "This is coming from the sidecar", translate("sidecar", scope: ".from")
    assert_equal "This is coming from Rails", translate("rails", scope: "from")
    assert_equal "This is coming from the sidecar", translate("sidecar", scope: [".from"])
    assert_equal "This is coming from Rails", translate("rails", scope: ["from"])
    assert_equal "This is coming from the sidecar", translate(:sidecar, scope: [:".from"])
    assert_equal "This is coming from Rails", translate(:rails, scope: [:from])
  end

  def test_translating_from_the_class
    assert_equal "This is coming from the sidecar", TranslatableComponent.t(".from.sidecar")
    assert_equal ["This is coming from the sidecar"], TranslatableComponent.t([".from.sidecar"])
    assert_equal({sidecar: "This is coming from the sidecar"}, TranslatableComponent.t(".from"))

    assert_equal "This is coming from the sidecar", TranslatableComponent.translate(".from.sidecar")
    assert_equal ["This is coming from the sidecar"], TranslatableComponent.translate([".from.sidecar"])
    assert_equal({sidecar: "This is coming from the sidecar"}, TranslatableComponent.translate(".from"))
  end

  def test_inheriting_and_overriding_translations
    render_inline(TranslatableSubclassComponent.new)

    assert_selector("p.sidecar.shared-key", text: "Hello from subclass sidecar translations!")
    assert_selector("p.sidecar.nested", text: "This is coming from the sidecar")
    assert_selector("p.sidecar.missing", text: "This is coming from Rails")

    assert_selector("p.helpers.shared-key", text: "Hello from Rails translations!")
    assert_selector("p.helpers.nested", text: "This is coming from Rails")

    assert_selector("p.global.shared-key", text: "Hello from Rails translations!")
    assert_selector("p.global.nested", text: "This is coming from Rails")
  end

  private

  def translate(key, **options)
    component = TranslatableComponent.new
    render_inline(component)
    component
      .instance_variable_get(:@view_context)
      .instance_variable_set(:@virtual_path, component.virtual_path)
    component.translate(key, **options)
  end
end
