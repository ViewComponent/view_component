# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_unit/component_generator"

Rails.application.load_generators

class TestUnitGeneratorTest < Rails::Generators::TestCase
  tests TestUnit::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  def test_generates_component
    run_generator %w[Dummy data]

    assert_file "test/components/dummy_component_test.rb" do |content|
      assert_match(
        /render_inline\(DummyComponent.new\(message: "Hello, components!"\)\).css\("span"\).to_html/, content
      )
    end
  end
end
