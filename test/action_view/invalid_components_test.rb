# frozen_string_literal: true

class ActionView::InvalidComponentTest < ActionView::Component::TestCase
  def test_raises_error_when_initializer_is_not_defined
    skip if const_source_location_supported?

    exception = assert_raises ActionView::Component::TemplateError do
      render_inline(MissingInitializerComponent)
    end

    assert_includes exception.message, "must implement #initialize"
  end

  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises ActionView::Component::TemplateError do
      render_inline(MissingTemplateComponent)
    end

    assert_includes exception.message, "Could not find a template file for MissingTemplateComponent"
  end

  def test_raises_error_when_more_than_one_sidecar_template_is_present
    error = assert_raises ActionView::Component::TemplateError do
      render_inline(TooManySidecarFilesComponent)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  def test_raises_error_when_more_than_one_sidecar_template_for_a_variant_is_present
    error = assert_raises ActionView::Component::TemplateError do
      render_inline(TooManySidecarFilesForVariantComponent)
    end

    assert_includes error.message, "More than one template found for variants 'test' and 'testing' in TooManySidecarFilesForVariantComponent"
  end
end
