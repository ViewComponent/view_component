# frozen_string_literal: true

module PreviewHelper
  AVAILABLE_PRISM_LANGUAGES = %w[ruby erb haml]
  FALLBACK_LANGUAGE = "ruby"

  def preview_source
    return if @render_args.nil?

    render "preview_source"
  end

  def find_template_data(lookup_context:, template_identifier:)
    template = lookup_context.find_template(template_identifier)

    if Rails.version.to_f >= 6.1 || template.source.present?
      {
        source: template.source,
        prism_language_name: prism_language_name_by_template(template: template)
      }
    else
      # Fetch template source via finding it through preview paths
      # to accomodate source view when exclusively using templates
      # for previews for Rails < 6.1.
      all_template_paths = ViewComponent::Base.config.preview_paths.map do |preview_path|
        Dir.glob("#{preview_path}/**/*")
      end.flatten

      # Search for templates the contain `html`.
      matching_templates = all_template_paths.find_all do |path|
        path =~ /#{template_identifier}*.(html)/
      end

      # In-case of a conflict due to multiple template files with
      # the same name
      raise "found 0 matches for templates for #{template_identifier}." if matching_templates.empty?
      raise "found multiple templates for #{template_identifier}." if matching_templates.size > 1

      template_file_path = matching_templates.first
      template_source = File.read(template_file_path)
      prism_language_name = prism_language_name_by_template_path(template_file_path: template_file_path)

      {
        source: template_source,
        prism_language_name: prism_language_name
      }
    end
  end

  private

  def prism_language_name_by_template(template:)
    language = template.identifier.split(".").last

    return FALLBACK_LANGUAGE unless AVAILABLE_PRISM_LANGUAGES.include? language

    language
  end

  def prism_language_name_by_template_path(template_file_path:)
    language = template_file_path.gsub(".html", "").split(".").last

    return FALLBACK_LANGUAGE unless AVAILABLE_PRISM_LANGUAGES.include? language

    language
  end
end
