# frozen_string_literal: true

require "test_helper"
require "fileutils"

class ViewComponent::I18nTest < ViewComponent::TestCase
  def setup
    FileUtils.mkdir_p "#{components_root}/greeting"

    File.write "#{components_root}/greeting/component.yml", <<~YAML
      en:
        hello: Hello!
    YAML

    File.write "#{components_root}/widget_component.yml", <<~YAML
      en:
        title: I'm a widget!
        sub:
          key: foobar
    YAML
  end

  def test_multiple_translation_files
    translations = ViewComponent::I18n.load components_root: components_root, glob: "**/*component.yml"

    assert_equal({
      "en" => {
        "greeting" => {
          "component" => {"hello" => "Hello!"}
        },
        "widget_component" => {
          "title" => "I'm a widget!",
          "sub" => { "key" => "foobar" }
        }
      }
    }, translations)
  end

  def test_a_custom_glob
    translations = ViewComponent::I18n.load components_root: components_root, glob: "**/*_component.yml"

    assert_equal({
      "en" => {
        "widget_component" => {
          "title" => "I'm a widget!",
          "sub" => { "key" => "foobar" }
        }
      }
    }, translations)
  end

  private

  def components_root
    @components_root ||= Dir.mktmpdir
  end
end
