# frozen_string_literal: true

require "test_helper"
require "i18n/backend/cache"

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

  def test_nil_keys_use_defaults
    assert_equal "fallback", translate(nil, default: "fallback")
    assert_equal "fallback", TranslatableComponent.translate(nil, default: "fallback")
    assert_equal "fallback", TranslatableComponent.translate(nil, scope: ".from", default: "fallback")
    assert_equal "fallback", MyComponent.translate(nil, default: "fallback")
  end

  def test_symbolic_defaults_resolve_sidecar_translations
    assert_equal "Hello from sidecar translations!", translate(".missing", default: :".hello")
    assert_equal "Hello from sidecar translations!", TranslatableComponent.t(".missing", default: :".hello")
    assert_equal "Hello from sidecar translations!", translate(nil, default: :".hello")
    assert_equal "Hello from sidecar translations!", TranslatableComponent.t(nil, default: :".hello")
  end

  def test_symbolic_defaults_preserve_primary_and_default_precedence
    defaults = [nil, :".not_found", :".hello", "literal"].freeze
    assert_equal "Hello from sidecar translations!", translate(".missing", default: defaults)
    assert_equal "Hello from sidecar translations!", TranslatableComponent.t(".missing", default: defaults)
    assert_equal [nil, :".not_found", :".hello", "literal"], defaults

    assert_equal "Hello from Rails translations!", translate("hello", default: :".hello")
    assert_equal "Hello from Rails translations!", TranslatableComponent.t("hello", default: :".hello")
    assert_equal "This is coming from Rails", translate(".missing", default: [:"from.rails", :".hello"])
    assert_equal "This is coming from Rails", TranslatableComponent.t(".missing", default: [:"from.rails", :".hello"])
    assert_equal "literal", translate(".missing", default: ["literal", :".hello"])
    assert_equal false, translate(".missing", default: [false, :".hello"])
  end

  def test_symbolic_defaults_work_with_a_caching_i18n_backend
    backend = I18n.backend.dup.extend(I18n::Backend::Cache)
    with_config_option(:backend, backend, config_entrypoint: I18n) do
      with_config_option(:cache_store, ActiveSupport::Cache::MemoryStore.new, config_entrypoint: I18n) do
        2.times do
          assert_equal "Hello from sidecar translations!", translate(".missing", default: :".hello")
          assert_equal "Hello from sidecar translations!", TranslatableComponent.t(".missing", default: :".hello")
        end
      end
    end
  end

  def test_symbolic_defaults_preserve_scope_and_locale
    assert_equal "This is coming from the sidecar", translate(:missing, scope: ".from", default: :sidecar)
    assert_equal "This is coming from the sidecar", TranslatableComponent.t(:missing, scope: ".from", default: :sidecar)
    assert_equal "French fallback", translate(".missing", locale: :fr, default: [:".hello", "French fallback"])
    assert_equal "French fallback", TranslatableComponent.t(".missing", locale: :fr, default: [:".hello", "French fallback"])
  end

  def test_symbolic_defaults_use_the_resolved_keys_html_safety
    translation = translate(".missing", default: :".interpolated_html", horse_count: "<em>4</em>")
    assert_predicate translation, :html_safe?
    assert_includes translation, "&lt;em&gt;4&lt;/em&gt;"
    assert_includes translation, "<strong>barn</strong>"
    refute_predicate translate(".missing_html", default: :".hello"), :html_safe?
    refute_predicate TranslatableComponent.t(".missing", default: :".hello_html"), :html_safe?
  end

  def test_symbolic_defaults_only_evaluate_necessary_procs_once
    calls = 0
    defaults = [->(*) {
      calls += 1
      nil
    }, :".hello"]
    assert_equal "Hello from sidecar translations!", translate(".missing", default: defaults)
    assert_equal 1, calls
    assert_equal "Hello from sidecar translations!", TranslatableComponent.t(".missing", default: defaults)
    assert_equal 2, calls
    assert_equal "Hello from sidecar translations!", translate(".hello", default: defaults)
    assert_equal 2, calls

    assert_equal "Hello world", translate(".missing", default: [->(*) { "Hello %{name}" }, :".hello"], name: "world")
  end

  def test_unresolved_symbolic_defaults_raise_for_the_original_key
    error = assert_raises(I18n::MissingTranslationData) do
      translate(".missing", default: [:".not_found", :".also_missing"], raise: true)
    end
    assert_includes error.message, "translatable_component.missing"

    error = assert_raises(I18n::MissingTranslationData) do
      TranslatableComponent.t(".missing", default: [:".not_found", :".also_missing"], raise: true)
    end
    assert_includes error.message, "translatable_component.missing"
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

  def test_translating_from_the_class_falls_back_to_global_translations
    assert_equal "This is coming from Rails", TranslatableComponent.t("from.rails")
    assert_equal "Relative key from Rails", TranslatableComponent.t(".relative_rails_key")
    assert_equal "Translation missing: en.translatable_component.missing", TranslatableComponent.t(".missing")
    assert_equal "Default", TranslatableComponent.t(".missing", default: "Default")

    assert_raises(I18n::MissingTranslationData) do
      TranslatableComponent.t(".missing", raise: true)
    end
  end

  def test_translating_from_the_class_without_sidecar_translations
    assert_equal "OH NO! (you shouldn't see me)", MyComponent.t(".message")
    assert_equal "This is coming from Rails", MyComponent.translate("from.rails")
  end

  def test_default_does_not_shadow_global_translations
    assert_equal "This is coming from Rails", TranslatableComponent.t("from.rails", default: "Default")
    assert_equal "Relative key from Rails", TranslatableComponent.t(".relative_rails_key", default: "Default")
    assert_equal "Default", TranslatableComponent.t(".missing", default: "Default")

    assert_equal "This is coming from Rails", translate("from.rails", default: "Default")
    assert_equal "Relative key from Rails", translate(".relative_rails_key", default: "Default")
    assert_equal "Default", translate(".missing", default: "Default")
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
