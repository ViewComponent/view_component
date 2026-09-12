# frozen_string_literal: true

require "test_helper"

class TemplateAnnotationTest < ViewComponent::TestCase
  # Rails only prepends the `<!-- BEGIN ... -->` annotation, and the newline it
  # contains, when annotations are enabled *and* the template's format is HTML.
  # The line number compensation ViewComponent applies has to match those same
  # conditions, otherwise backtraces point at the wrong line and, when coverage
  # is running, template source is stripped away.
  def setup
    skip unless Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR > 0
  end

  def teardown
    [RaisingFormatsComponent, MultipleFormatsComponent].each { |c| c.__vc_compile(force: true) }
  end

  def test_backtrace_line_number_for_html_template_with_annotations
    RaisingFormatsComponent.__vc_compile(force: true)

    error = assert_raises(ArgumentError) { render_inline(RaisingFormatsComponent.new) }

    assert_equal 2, template_line_number(error, "raising_formats_component.html.erb")
  end

  def test_backtrace_line_number_for_html_template_without_annotations
    error = nil

    without_template_annotations do
      RaisingFormatsComponent.__vc_compile(force: true)
      error = assert_raises(ArgumentError) { render_inline(RaisingFormatsComponent.new) }
    end

    assert_equal 2, template_line_number(error, "raising_formats_component.html.erb")
  end

  def test_backtrace_line_number_for_non_html_template
    RaisingFormatsComponent.__vc_compile(force: true)

    error = assert_raises(ArgumentError) do
      with_format(:text) { render_inline(RaisingFormatsComponent.new) }
    end

    assert_equal 2, template_line_number(error, "raising_formats_component.text.erb")
  end

  def test_non_html_template_renders_its_content_when_coverage_is_running
    with_coverage_running { MultipleFormatsComponent.__vc_compile(force: true) }

    with_format(:css) { render_inline(MultipleFormatsComponent.new) }

    assert_includes @rendered_content, "Hello, CSS!"
  end

  private

  def template_line_number(error, template_file)
    entry = error.backtrace.find { |line| line.include?(template_file) }

    refute_nil entry, "Expected #{template_file} in backtrace:\n#{error.backtrace.first(5).join("\n")}"

    entry[/:(\d+):/, 1].to_i
  end

  def with_coverage_running
    require "coverage"
    already_running = Coverage.running?
    Coverage.start unless already_running
    yield
  ensure
    Coverage.result unless already_running
  end
end
