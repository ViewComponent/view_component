# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "rails/generators/component/component_generator"

Rails.application.load_generators

class ComponentGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::ComponentGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  arguments %w[user]

  def test_component_with_required_content
    Thor::LineEditor.stub :readline, "Y" do
      run_generator
    end

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      assert_match(/validates :content, presence: true/, component)
    end

    assert_file "app/components/user_component.html.erb" do |view|
      assert_match(/<%= content %>/, view)
    end
  end

  def test_component_without_required_content
    Thor::LineEditor.stub :readline, "n" do
      run_generator
    end

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      refute_match(/validates :content, presence: true/, component)
    end

    assert_file "app/components/user_component.html.erb" do |view|
      assert_match(/<div>Add User template here<\/div>/, view)
    end
  end

  def test_component_with_namespace
    Thor::LineEditor.stub :readline, "n" do
      run_generator %w[admins/user]
    end

    assert_file "app/components/admins/user_component.rb", /class Admins::UserComponent < /
    assert_file "app/components/admins/user_component.html.erb"
  end
end
