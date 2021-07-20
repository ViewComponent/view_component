# frozen_string_literal: true

require "test_helper"
require_relative File.expand_path("../../../lib/rails/generators/test_unit/component_generator", __FILE__)

class ViewComponent::TestUnitGeneratorTest < ::Rails::Generators::TestCase
  tests TestUnit::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  setup do
    run_generator %w(Dummy data)
  end

  def test_generates_component
    assert_file "test/components/dummy_component_test.rb" do |content|
      assert_match(
        /render_inline\(DummyComponent.new\(message: "Hello, components!"\)\).css\("span"\).to_html/, content
      )
    end
  end
end
