# frozen_string_literal: true

module PreviewTemplateHelper
  AVAILABLE_PRISM_LANGUAGES = ["ruby", "erb", "haml"]
  FALLBACK_LANGUAGE = "ruby"

  def prism_language_name(template:)
    language = template.identifier.split(".").last
    return FALLBACK_LANGUAGE unless AVAILABLE_PRISM_LANGUAGES.include? language

    language
  end
end
