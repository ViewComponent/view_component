# frozen_string_literal: true

require_relative "../../test_helper"
require "rails/generators/component/component_generator"

class ComponentGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  arguments %w[user]

  def test_component
    run_generator

    assert_file "app/components/dummy/user_component.rb" do |component|
      assert_match(/module Dummy/, component)
      assert_match(/class UserComponent < ViewComponent::Base/, component)
      assert_no_match(/def initialize/, component)
    end
  end

  def test_component_tests
    run_generator %w[user --test-framework test_unit]

    assert_file "test/components/dummy/user_component_test.rb" do |component|
      assert_match(/module Dummy/, component)
      assert_match(/class UserComponentTest < /, component)
      assert_match(/def test_component_renders_something_useful/, component)
    end
  end

  def test_component_preview
    run_generator %w[user --preview]

    assert_file "test/components/previews/dummy/user_component_preview.rb" do |component|
      assert_match(/module Dummy/, component)
      assert_match(/class UserComponentPreview < /, component)
      assert_match(/render\(UserComponent.new\)/, component)
    end
  end
end
