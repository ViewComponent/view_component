# frozen_string_literal: true

module PreviewHelper
  AVAILABLE_PRISM_LANGUAGES = ["ruby", "erb", "haml"]
  FALLBACK_LANGUAGE = "ruby"

  def prism_language_name(template:)
    language = template.identifier.split(".").last
    return FALLBACK_LANGUAGE unless AVAILABLE_PRISM_LANGUAGES.include? language

    language
  end

  def preview_source
    return if @render_args.nil?

    render "preview_source" # rubocop:disable GitHub/RailsViewRenderPathsExist
  end
end
