# frozen_string_literal: true

require "test_helper"
require "rails/generators/translations/component_generator"

Rails.application.load_generators

class TranslationsGeneratorTest < Rails::Generators::TestCase
  tests Translations::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  arguments %w[user]

  def test_component_generator
    run_generator

    assert_file "app/components/user_component.yml"
  end

  def test_component_generator_with_sidecar
    run_generator %w[user --sidecar]

    assert_file "app/components/user_component/user_component.yml"
  end

  def test_component_with_namespace
    run_generator %w[admins/user]

    assert_file "app/components/admins/user_component.yml"
  end

  def test_component_with_namespace_and_sidecar
    run_generator %w[admins/user --sidecar]

    assert_file "app/components/admins/user_component/user_component.yml"
  end
end
