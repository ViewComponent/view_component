# frozen_string_literal: true

require "rails/application_controller"

class Rails::ComponentsController < Rails::ApplicationController # :nodoc:
  prepend_view_path File.expand_path("templates/rails", __dir__)
  prepend_view_path "#{Rails.root}/app/views/" if defined?(Rails.root)

  around_action :set_locale, only: :previews
  before_action :find_preview, only: :previews
  before_action :require_local!, unless: :show_previews?

  if respond_to?(:content_security_policy)
    content_security_policy(false)
  end

  def index
    @previews = ActionView::Component::Preview.all
    @page_title = "Component Previews"
    render template: "components/index"
  end

  def previews
    if params[:path] == @preview.preview_name
      @page_title = "Component Previews for #{@preview.preview_name}"
      render template: "components/previews"
    else
      @example_name = File.basename(params[:path])
      @render_args = @preview.render_args(@example_name)
      layout = @render_args[:layout]
      opts = layout.nil? ? {} : { layout: layout }
      render template: "components/preview", **opts
    end
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
