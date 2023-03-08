# frozen_string_literal: true

require "test_helper"
# rubocop:disable Style/MixinUsage
include PreviewHelper
# rubocop:enable Style/MixinUsage
class PreviewHelperTest < ActiveSupport::TestCase
  def test_returns_template_data_with_no_template
    template_identifier = "preview/no_template"

    expected_template_source = "expected_template"
    mock_template = Minitest::Mock.new
    mock_template.expect(:source, expected_template_source)
    mock_template.expect(:source, expected_template_source)
    mock_template.expect(:identifier, "unknown")

    lookup_context = Minitest::Mock.new
    lookup_context.expect(:find_template, mock_template, [template_identifier])

    template_data = PreviewHelper.find_template_data(
      lookup_context: lookup_context,
      template_identifier: template_identifier
    )

    assert_equal(template_data[:source], "expected_template")
    assert_equal(template_data[:prism_language_name], "ruby")
  end

  def test_returns_template_data_with_template_of_different_languages
    template_identifier = "preview/template"

    expected_template_source = "expected_template"

    PreviewHelper::AVAILABLE_PRISM_LANGUAGES.each do |language|
      mock_template = Minitest::Mock.new
      mock_template.expect(:source, expected_template_source)
      mock_template.expect(:source, expected_template_source)
      mock_template.expect(:identifier, "html.#{language}")

      lookup_context = Minitest::Mock.new
      lookup_context.expect(:find_template, mock_template, [template_identifier])

      template_data = PreviewHelper.find_template_data(
        lookup_context: lookup_context,
        template_identifier: template_identifier
      )

      assert_equal(template_data[:source], "expected_template")
      assert_equal(template_data[:prism_language_name], language)
    end
  end

  if Rails.version.to_f < 6.1
    def test_returns_template_data_without_dedicated_template
      template_identifier = "preview/template"
      expected_source = "<%= PreviewTest %>"

      PreviewHelper::AVAILABLE_PRISM_LANGUAGES.each do |language|
        mock_template = Minitest::Mock.new
        mock_template.expect(:source, expected_source)
        mock_template.expect(:source, expected_source)
        mock_template.expect(:identifier, "html.#{language}")

        lookup_context = Minitest::Mock.new
        expected_template_path = "some/path/#{template_identifier}.html.haml"
        lookup_context.expect(:find_template, mock_template, [template_identifier])

        mock = Minitest::Mock.new
        mock.expect :map, [expected_template_path]
        ViewComponent::Base.stub(:preview_paths, mock) do
          template_data = PreviewHelper.find_template_data(
            lookup_context: lookup_context,
            template_identifier: template_identifier
          )

          assert_equal(template_data[:source], expected_source)
          assert_equal(template_data[:prism_language_name], language)
        end
      end
    end

    def test_returns_template_data_with_dedicated_template
      template_identifier = "preview/template"
      expected_source = "<%= PreviewTest %>"

      PreviewHelper::AVAILABLE_PRISM_LANGUAGES.each do |language|
        mock_template = Minitest::Mock.new
        mock_template.expect(:source, "")
        mock_template.expect(:source, "")

        lookup_context = Minitest::Mock.new
        expected_template_path = "some/path/#{template_identifier}.html.#{language}"
        lookup_context.expect(:find_template, mock_template, [template_identifier])

        mock = Minitest::Mock.new
        mock.expect :map, [expected_template_path]
        Rails.application.config.view_component.stub(:preview_paths, mock) do
          File.stub(:read, expected_source, [expected_template_path]) do
            template_data = PreviewHelper.find_template_data(
              lookup_context: lookup_context,
              template_identifier: template_identifier
            )

            assert_equal(template_data[:source], expected_source)
            assert_equal(template_data[:prism_language_name], language)
          end
        end
      end
    end

    def test_raises_with_no_matching_template
      template_identifier = "preview/template"

      mock_template = Minitest::Mock.new
      mock_template.expect(:source, "")
      mock_template.expect(:source, "")

      lookup_context = Minitest::Mock.new
      lookup_context.expect(:find_template, mock_template, [template_identifier])

      mock = Minitest::Mock.new
      mock.expect :map, []
      Rails.application.config.view_component.stub :preview_paths, mock do
        exception = assert_raises RuntimeError do
          PreviewHelper.find_template_data(
            lookup_context: lookup_context,
            template_identifier: template_identifier
          )
        end

        assert_equal("found 0 matches for templates for #{template_identifier}.", exception.message)
      end
    end

    def test_raises_with_conflict_in_template_resolution
      template_identifier = "preview/template"

      mock_template = Minitest::Mock.new
      mock_template.expect(:source, "")
      mock_template.expect(:source, "")

      lookup_context = Minitest::Mock.new
      lookup_context.expect(:find_template, mock_template, [template_identifier])

      mock = Minitest::Mock.new
      mock.expect :map, [template_identifier + ".html.haml", template_identifier + ".html.erb"]
      Rails.application.config.view_component.stub :preview_paths, mock do
        exception = assert_raises RuntimeError do
          PreviewHelper.find_template_data(
            lookup_context: lookup_context,
            template_identifier: template_identifier
          )
        end

        assert_equal("found multiple templates for #{template_identifier}.", exception.message)
      end
    end
  end
end
