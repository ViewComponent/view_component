# frozen_string_literal: true

require_relative "../../test_helper"
require "rails/generators/preview/component_generator"

class PreviewGeneratorTest < Rails::Generators::TestCase
  tests Preview::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  def test_component_preview
    with_preview_paths([]) do
      run_generator %w[example --preview]

      assert_file "test/components/previews/test_engine/example_component_preview.rb" do |component|
        assert_match(/module TestEngine/, component)
        assert_match(/class ExampleComponentPreview < /, component)
        assert_match(/render\(ExampleComponent.new\)/, component)
      end
    end
  end
end
