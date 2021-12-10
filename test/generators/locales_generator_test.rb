# frozen_string_literal: true

require "test_helper"
require "rails/generators/locales/component_generator"

Rails.application.load_generators

class LocalesGeneratorTest < Rails::Generators::TestCase
  tests Locales::Generators::ComponentGenerator
  destination Dir.mktmpdir
  setup :prepare_destination

  arguments %w[user]

  def test_component_generator
    run_generator

    I18n.available_locales.each do |locale|
      assert_file "app/components/user_component.#{locale}.yml" do |content|
        assert_match(/\A#{locale}:\n/, content)
      end
    end
  end

  def test_component_generator_with_sidecar
    run_generator %w[user --sidecar]

    I18n.available_locales.each do |locale|
      assert_file "app/components/user_component/user_component.#{locale}.yml" do |content|
        assert_match(/\A#{locale}:\n/, content)
      end
    end
  end

  def test_component_with_namespace
    run_generator %w[admins/user]

    I18n.available_locales.each do |locale|
      assert_file "app/components/admins/user_component.#{locale}.yml" do |content|
        assert_match(/\A#{locale}:\n/, content)
      end
    end
  end

  def test_component_with_namespace_and_sidecar
    run_generator %w[admins/user --sidecar]

    I18n.available_locales.each do |locale|
      assert_file "app/components/admins/user_component/user_component.#{locale}.yml" do |content|
        assert_match(/\A#{locale}:\n/, content)
      end
    end
  end
end
