# frozen_string_literal: true

require "test_helper"
require "rails/generators/stimulus/component_generator"

Rails.application.load_generators

class StimulusGeneratorTest < Rails::Generators::TestCase
  tests Stimulus::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  arguments %w[user]

  def test_component_generator
    run_generator

    assert_file "app/components/user_component_controller.js" do |view|
      assert_match(/Hello, Stimulus!/, view)
    end
  end

  def test_component_generator_with_sidecar
    run_generator %w[user --sidecar]

    assert_file "app/components/user_component/user_component_controller.js" do |view|
      assert_match(/Hello, Stimulus!/, view)
    end
  end

  def test_component_with_namespace
    run_generator %w[admins/user]

    assert_file "app/components/admins/user_component_controller.js"
  end

  def test_component_with_namespace_and_sidecar
    run_generator %w[admins/user --sidecar]

    assert_file "app/components/admins/user_component/user_component_controller.js"
  end

  def test_component_with_generate_sidecar
    with_generate_sidecar(true) do
      run_generator %w[user]

      assert_file "app/components/user_component/user_component_controller.js"
    end
  end
end
