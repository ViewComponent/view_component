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

  def test_component
    run_generator

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      assert_no_match(/def initialize/, component)
    end
  end

  def test_component_with_arguments
    run_generator %w[user name]

    assert_file "app/components/user_component.rb" do |component|
      assert_match(/class UserComponent < /, component)
      assert_match(/def initialize\(name:\)/, component)
    end
  end

  def test_component_with_namespace
    run_generator %w[admins/user]

    assert_file "app/components/admins/user_component.rb", /class Admins::UserComponent < /
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
end
