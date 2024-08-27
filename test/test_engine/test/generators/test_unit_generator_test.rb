# frozen_string_literal: true

require_relative "../../test_helper"
require "rails/generators/test_unit/component_generator"

class TestUnitGeneratorTest < Rails::Generators::TestCase
  tests TestUnit::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  def test_component_tests
    run_generator %w[example --test-framework test_unit]

    assert_file "test/components/test_engine/example_component_test.rb" do |component|
      assert_no_match(/module/, component)
      assert_match(/class TestEngine::ExampleComponentTest < /, component)
      assert_match(/def test_component_renders_something_useful/, component)
    end
  end
end
