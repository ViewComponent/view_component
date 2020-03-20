# frozen_string_literal: true

class InvalidComponentTest < ViewComponent::TestCase
  def test_raises_error_when_initializer_is_not_defined
    exception = assert_raises ViewComponent::TemplateError do
      render_inline(MissingInitializerComponent.new)
    end

    assert_includes exception.message, "must implement #initialize"
  end

  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises ViewComponent::TemplateError do
      render_inline(MissingTemplateComponent.new)
    end

    assert_includes exception.message, "Could not find a template file for MissingTemplateComponent"
  end

  def test_raises_error_when_more_than_one_sidecar_template_is_present
    error = assert_raises ViewComponent::TemplateError do
      render_inline(TooManySidecarFilesComponent.new)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  def test_raises_error_when_more_than_one_sidecar_template_for_a_variant_is_present
    error = assert_raises ViewComponent::TemplateError do
      render_inline(TooManySidecarFilesForVariantComponent.new)
    end

    assert_includes error.message, "More than one template found for variants 'test' and 'testing' in TooManySidecarFilesForVariantComponent"
  end

  def test_backtrace_returns_correct_file_and_line_number
    error = assert_raises NameError do
      render_inline(ExceptionInTemplateComponent.new)
    end

    assert_match %r[app/components/exception_in_template_component\.html\.erb:2], error.backtrace[0]
  end
end
