# frozen_string_literal: true

require "rails/application_controller"

class ViewComponentsController < Rails::ApplicationController # :nodoc:
  prepend_view_path File.expand_path("../views", __dir__)

  around_action :set_locale, only: :previews
  before_action :find_preview, only: :previews
  before_action :require_local!, unless: :show_previews?

  delegate :preview_component_path, to: :url_helpers

  if respond_to?(:content_security_policy)
    content_security_policy(false)
  end

  def index
    @previews = ViewComponent::Preview.all
    @page_title = "Component Previews"
  end

  def previews
    if params[:path] == @preview.preview_name
      @page_title = "Component Previews for #{@preview.preview_name}"
      render "view_components/previews"
    else
      prepend_application_view_paths
      @example_name = File.basename(params[:path])
      @render_args = @preview.render_args(@example_name, params: params.permit!)
      layout = @render_args[:layout]
      opts = layout.nil? ? {} : { layout: layout }
      render "view_components/preview", **opts
    end
  end

  private

  def show_previews? # :doc:
    ViewComponent::Base.show_previews
  end

  def find_preview # :doc:
    candidates = []
    params[:path].to_s.scan(%r{/|$}) { candidates << $` }
    preview = candidates.detect { |candidate| ViewComponent::Preview.exists?(candidate) }

    if preview
      @preview = ViewComponent::Preview.find(preview)
    else
      raise AbstractController::ActionNotFound, "Component preview '#{params[:path]}' not found"
    end
  end

  def set_locale
    I18n.with_locale(params[:locale] || I18n.default_locale) do
      yield
    end
  end

  def prepend_application_view_paths
    prepend_view_path Rails.root.join("app/views") if defined?(Rails.root)
  end

  def preview_component_path
    Rails.application.routes.url_helpers.preview_component_path
  end
end
