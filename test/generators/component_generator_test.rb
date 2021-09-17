# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "rails/generators/component/component_generator"

Rails.application.load_generators

class ComponentGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  arguments %w[user]

  def test_component
    run_generator

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      assert_no_match(/def initialize/, component)
    end
  end

  def test_component_tests
    run_generator %w[user --test-framework test_unit]

    assert_file "test/components/user_component_test.rb" do |component|
      assert_match(/class UserComponentTest < /, component)
      assert_match(/def test_component_renders_something_useful/, component)
    end
  end

  def test_component_preview
    with_preview_paths([]) do
      run_generator %w[user --preview]

      assert_file "test/components/previews/user_component_preview.rb" do |component|
        assert_match(/class UserComponentPreview < /, component)
        assert_match(/render\(UserComponent.new\)/, component)
      end
    end
  end

  def test_component_preview_with_one_overridden_preview_path
    with_preview_paths(%w[spec/components/previews]) do
      run_generator %w[user --preview]

      assert_file "spec/components/previews/user_component_preview.rb" do |component|
        assert_match(/class UserComponentPreview < /, component)
        assert_match(/render\(UserComponent.new\)/, component)
      end
    end
  end

  def test_component_preview_with_two_overridden_preview_paths
    with_preview_paths(%w[spec/components/previews some/other/directory]) do
      run_generator %w[user --preview]

      assert_no_file "test/components/previews/user_component_preview.rb"
      assert_no_file "spec/components/previews/user_component_preview.rb"
      assert_no_file "some/other/directory/user_component_preview.rb"
    end
  end

  def test_component_with_arguments
    run_generator %w[user name]

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      assert_match(/def initialize\(name:\)/, component)
    end
  end

  def test_component_with_inline
    run_generator %w[user name --inline]

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/def call/, component)
    end

    assert_no_file "app/components/user_component.html.erb"
    assert_no_file "component.html.erb"
  end

  def test_component_with_parent
    run_generator %w[user --parent BaseComponent]

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < BaseComponent/, component)
    end
  end

  def test_component_with_namespace
    run_generator %w[admins/user]

    assert_file "app/components/admins/user_component.rb", /class Admins::UserComponent < /
  end

  def test_component_tests_with_namespace
    run_generator %w[admins/user --test-framework test_unit]

    assert_file "test/components/admins/user_component_test.rb" do |component|
      assert_match(/class Admins::UserComponentTest < /, component)
      assert_match(/def test_component_renders_something_useful/, component)
    end
  end

  def test_component_preview_with_namespace
    with_preview_paths([]) do
      run_generator %w[admins/user --preview]

      assert_file "test/components/previews/admins/user_component_preview.rb" do |component|
        assert_match(/class Admins::UserComponentPreview < /, component)
        assert_match(/render\(Admins::UserComponent.new\)/, component)
      end
    end
  end

  def test_invoking_erb_template_engine
    run_generator %w[user --template-engine erb]

    assert_file "app/components/user_component.html.erb"
  end

  def test_invoking_slim_template_engine
    run_generator %w[user --template-engine slim]

    assert_file "app/components/user_component.html.slim"
  end

  def test_invoking_haml_template_engine
    run_generator %w[user --template-engine haml]

    assert_file "app/components/user_component.html.haml"
  end

  def test_generating_components_with_custom_component_path
    with_custom_component_path("app/parts") do
      run_generator %w[user]

      assert_file "app/parts/user_component.rb"
      assert_file "app/parts/user_component.html.erb"
    end
  end

  def test_generating_components_with_custom_component_parent_class
    with_custom_component_parent_class("BaseComponent") do
      run_generator %w[user]

      assert_file "app/components/user_component.rb" do |component|
        assert_match(/class UserComponent < BaseComponent/, component)
      end
    end
  end

  def test_component_with_stimulus
    run_generator %w[user --stimulus]

    assert_file "app/components/user_component.html.erb" do |component|
      assert_match(/data-controller="user-component"/, component)
    end

    assert_file "app/components/user_component_controller.js"
  end

  def test_component_with_stimulus_and_inline
    run_generator %w[user --stimulus --inline]

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/data: { controller: "user-component" }/, component)
    end

    assert_file "app/components/user_component_controller.js"
  end

  def test_component_with_stimulus_and_sidecar
    run_generator %w[user --stimulus --sidecar]

    assert_file "app/components/user_component/user_component_controller.js"
  end

  def test_component_with_stimulus_and_sidecar_and_inline
    run_generator %w[user --stimulus --sidecar --inline]

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/data: { controller: "user-component--user-component" }/, component)
    end

    assert_file "app/components/user_component/user_component_controller.js"
  end
end
