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

  def test_multi_key_support
    assert_equal [
      "Hello from sidecar translations!",
      "This is coming from the sidecar",
      "This is coming from Rails",
    ], translate([
      ".hello",
      ".from.sidecar",
      "from.rails",
    ])
  end

  def test_relative_keys_missing_from_component_translations
    assert_equal "Relative key from Rails", translate(".relative_rails_key")
  end

  def test_converts_key_to_string_as_necessary
    key = Struct.new(:to_s).new(".hello")
    assert_equal "Hello from sidecar translations!", translate(key)
    assert_equal key, translate(:"translations.missing", default: key)
  end

  private

  def translate(key, **options)
    component = TranslatableComponent.new
    render_inline(component)
    component.translate(key, **options)
  end
end
