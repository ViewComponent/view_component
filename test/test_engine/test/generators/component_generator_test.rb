# frozen_string_literal: true

require_relative "../../test_helper"
require "rails/generators/component/component_generator"

class ComponentGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  def test_component
    run_generator %w[example]

    assert_file "app/components/test_engine/example_component.rb" do |component|
      assert_match(/module TestEngine/, component)
      assert_match(/class ExampleComponent < ViewComponent::Base/, component)
      assert_no_match(/def initialize/, component)
    end
  end

  def test_component_without_suffix
    run_generator %w[example --skip-suffix]

    assert_file "app/components/test_engine/example.rb" do |component|
      assert_match(/module TestEngine/, component)
      assert_match(/class Example < ViewComponent::Base/, component)
      assert_no_match(/def initialize/, component)
    end
  end
end
