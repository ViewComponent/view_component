# frozen_string_literal: true

require "test_helper"
require "generators/view_component/slim/slim_generator"

Rails.application.load_generators

class SlimGeneratorTest < Rails::Generators::TestCase
  tests ViewComponent::Generators::SlimGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  arguments %w[user]

  def test_component_generator
    run_generator

    assert_file "app/components/user_component.html.slim" do |view|
      assert_match(/div Add User template here/, view)
    end
  end

  def test_component_generator_with_sidecar
    run_generator %w[user --sidecar]

    assert_file "app/components/user_component/user_component.html.slim" do |view|
      assert_match(/div Add User template here/, view)
    end
  end

  def test_component_with_namespace
    run_generator %w[admins/user]

    assert_file "app/components/admins/user_component.html.slim"
  end

  def test_component_with_namespace_and_sidecar
    run_generator %w[admins/user --sidecar]

    assert_file "app/components/admins/user_component/user_component.html.slim"
  end

  def test_component_with_generate_sidecar
    with_generate_sidecar(true) do
      run_generator %w[user]

      assert_file "app/components/user_component/user_component.html.slim"
    end
  end

  def test_component_with_call
    run_generator %w[user name --call]

    assert_no_file "app/components/user_component.html.slim"
  end
end
