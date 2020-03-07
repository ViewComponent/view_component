# frozen_string_literal: true

class ActionView::InvalidComponentTest < ViewComponent::TestCase
  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises ActionView::MissingTemplate do
      render_inline(MissingTemplateComponent.new)
    end

    assert_includes exception.message, "Missing template /missing_template_component"
  end

  # FIXME: this is manage by ActionView now
  def test_raises_error_when_more_than_one_sidecar_template_is_present
    error = assert_raises ActionView::MissingTemplate do
      render_inline(TooManySidecarFilesComponent.new)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  # FIXME: this is manage by ActionView now
  def test_raises_error_when_more_than_one_sidecar_template_for_a_variant_is_present
    error = assert_raises ActionView::MissingTemplate do
      render_inline(TooManySidecarFilesForVariantComponent.new)
    end

    assert_includes error.message, "More than one template found for variants 'test' and 'testing' in TooManySidecarFilesForVariantComponent"
  end

  def test_backtrace_returns_correct_file_and_line_number
    error = assert_raises ActionView::Template::Error do
      render_inline(ExceptionInTemplateComponent.new)
    end

    assert_match %r[app/components/exception_in_template_component\.html\.erb:2], error.backtrace[0]
  end
end
