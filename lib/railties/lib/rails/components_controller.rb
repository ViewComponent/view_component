# frozen_string_literal: true

require "rails/application_controller"

class Rails::ComponentsController < Rails::ApplicationController # :nodoc:
  prepend_view_path ActionDispatch::DebugView::RESCUES_TEMPLATE_PATH
  prepend_view_path File.expand_path("templates", __dir__)

  around_action :set_locale, only: :preview
  before_action :find_preview, only: [:preview, :example]
  before_action :require_local!, unless: :show_previews?

  content_security_policy(false)

  def index
    @previews = ActionView::Component::Preview.all
    @page_title = "Component Previews"
    render template: "components/index"
  end

  def preview
    @component_name = File.basename(params[:path]).camelize

    if params[:path] == @preview.preview_name
      @page_title = "Component Previews for #{@preview.preview_name}"
      render template: "components/examples"
    else
      @example_preview = File.basename(params[:path])

      if @preview.example_exists?(@example_preview)
        render template: "components/preview"
      else
        raise AbstractController::ActionNotFound, "Component preview '#{@component_preview}' not found in #{@preview.name}"
      end
    end
  end

  def example
    @example_preview = File.basename(params[:path])
    @example = @preview.call(@example_preview, params)
    render template: "components/example", layout: @preview.layout
  end

  private

  def show_previews? # :doc:
    ActionView::Component::Base.show_previews
  end

  def find_preview # :doc:
    candidates = []
    params[:path].to_s.scan(%r{/|$}) { candidates << $` }
    preview = candidates.detect { |candidate| ActionView::Component::Preview.exists?(candidate) }

    if preview
      @preview = ActionView::Component::Preview.find(preview)
    else
      raise AbstractController::ActionNotFound, "Component preview '#{params[:path]}' not found"
    end
  end

  def set_locale
    I18n.with_locale(params[:locale] || I18n.default_locale) do
      yield
    end
  end
end
