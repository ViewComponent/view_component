# frozen_string_literal: true

module ViewComponent
  module PreviewActions
    extend ActiveSupport::Concern

    included do
      prepend_view_path File.expand_path("../../../views", __dir__)

      around_action :set_locale, only: :previews
      before_action :require_local!, unless: :previews_enabled?

      content_security_policy(false)

      # Including helpers here ensures that we're loading the
      # latest version of helpers if code-reloading is enabled
      helper :all if include_all_helpers
    end

    def index
      @previews = ViewComponent::Preview.all
      @page_title = "Component Previews"
      render "view_components/index", **determine_layout
    end

    def previews
      find_preview

      if params[:path] == @preview.preview_name
        @page_title = "Component Previews for #{@preview.preview_name}"
        render "view_components/previews", **determine_layout
      else
        prepend_application_view_paths
        prepend_preview_examples_view_path
        @example_name = File.basename(params[:path])
        @render_args = @preview.render_args(@example_name, params: params.permit!)
        layout = determine_layout(@render_args[:layout], prepend_views: false)[:layout]
        locals = @render_args[:locals]
        opts = {}
        opts[:layout] = layout if layout.present? || layout == false
        opts[:locals] = locals if locals.present?
        render "view_components/preview", opts
      end
    end

    private

    # :doc:
    def default_preview_layout
      ViewComponent::Base.config.previews.default_layout
    end

    # :doc:
    def previews_enabled?
      ViewComponent::Base.config.previews.enabled
    end

    # :doc:
    def find_preview
      candidates = []
      params[:path].to_s.scan(%r{/|$}) { candidates << Regexp.last_match.pre_match }
      preview = candidates.sort_by(&:length).reverse_each.detect { |candidate| ViewComponent::Preview.exists?(candidate) }

      if preview
        @preview = ViewComponent::Preview.find(preview)
      else
        # TODO: This branch is covered in #test_returns_404_when_preview_does_not_exist,
        # but Simplecov doesn't always mark it as covered.
        # :nocov:
        raise AbstractController::ActionNotFound, "Component preview '#{params[:path]}' not found."
        # :nocov:
      end
    end

    def set_locale(&block)
      I18n.with_locale(params[:locale] || I18n.default_locale, &block)
    end

    # Returns either {} or {layout: value} depending on configuration
    def determine_layout(layout_override = nil, prepend_views: true)
      return {} unless defined?(Rails.root)

      layout_declaration = {}

      if !layout_override.nil?
        # Allow component-level override, even if false (thus no layout rendered)
        layout_declaration[:layout] = layout_override
      elsif default_preview_layout.present?
        layout_declaration[:layout] = default_preview_layout
      end

      prepend_application_view_paths if layout_declaration[:layout].present? && prepend_views

      layout_declaration
    end

    def prepend_application_view_paths
      prepend_view_path Rails.root.join("app/views") if defined?(Rails.root)
    end

    def prepend_preview_examples_view_path
      prepend_view_path(ViewComponent::Base.previews.paths)
    end
  end
end
