# frozen_string_literal: true

require "invalid_components_test_helper"
require "invalid/missing_initializer_component"
require "invalid/missing_template_component"
require "invalid/too_many_sidecar_files_component"
require "invalid/too_many_sidecar_files_for_variant_component"

class ActionView::InvalidComponentTest < ActionView::Component::TestCase
  def test_raises_error_when_initializer_is_not_defined
    exception = assert_raises NotImplementedError do
      render_inline(MissingInitializerComponent)
    end

    assert_includes exception.message, "must implement #initialize"
  end

  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises NotImplementedError do
      render_inline(MissingTemplateComponent)
    end

    assert_includes exception.message, "Could not find a template file for MissingTemplateComponent"
  end

  def test_raises_error_when_more_than_one_sidecar_template_is_present
    error = assert_raises StandardError do
      render_inline(TooManySidecarFilesComponent)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  def test_raises_error_when_more_than_one_sidecar_template_for_a_variant_is_present
    error = assert_raises StandardError do
      render_inline(TooManySidecarFilesForVariantComponent)
    end

    assert_includes error.message, "More than one template found for variant 'test' in TooManySidecarFilesForVariantComponent"
  end
end
