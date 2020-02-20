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
    with_required_content { run_generator }

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      assert_match(/validates :content, presence: true/, component)
    end
  end

  def test_component_without_required_content
    without_required_content { run_generator }

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      refute_match(/validates :content, presence: true/, component)
    end
  end

  def test_component_with_namespace
    with_required_content { run_generator %w[admins/user] }

    assert_file "app/components/admins/user_component.rb", /class Admins::UserComponent < /
  end

  def test_invoking_erb_template_engine
    without_required_content { run_generator %w[user --template-engine erb] }

    assert_file "app/components/user_component.html.erb"
  end

  def test_invoking_slim_template_engine
    without_required_content { run_generator %w[user --template-engine slim] }

    assert_file "app/components/user_component.html.slim"
  end

  def test_invoking_haml_template_engine
    without_required_content { run_generator %w[user --template-engine haml] }

    assert_file "app/components/user_component.html.haml"
  end

  private

  def with_required_content
    Thor::LineEditor.stub :readline, "Y" do
      yield
    end
  end

  def without_required_content
    Thor::LineEditor.stub :readline, "n" do
      yield
    end
  end
end
