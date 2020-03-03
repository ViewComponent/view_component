# frozen_string_literal: true

require "rails/application_controller"

class Rails::ComponentsController < Rails::ApplicationController # :nodoc:
  prepend_view_path File.expand_path("../../../lib/railties/lib/rails/templates/rails", __dir__)
  prepend_view_path "#{Rails.root}/app/views/" if defined?(Rails.root)

  around_action :set_locale, only: :previews
  before_action :find_preview, only: :previews
  before_action :require_local!, unless: :show_previews?

  if respond_to?(:content_security_policy)
    content_security_policy(false)
  end

  def index
    @previews = ViewComponent::Preview.all
    @page_title = "Component Previews"
    # rubocop:disable GitHub/RailsControllerRenderPathsExist
    render "components/index"
    # rubocop:enable GitHub/RailsControllerRenderPathsExist
  end

  def previews
    if params[:path] == @preview.preview_name
      @page_title = "Component Previews for #{@preview.preview_name}"
      # rubocop:disable GitHub/RailsControllerRenderPathsExist
      render "components/previews"
      # rubocop:enable GitHub/RailsControllerRenderPathsExist
    else
      @example_name = File.basename(params[:path])
      @render_args = @preview.render_args(@example_name)
      layout = @render_args[:layout]
      opts = layout.nil? ? {} : { layout: layout }
      # rubocop:disable GitHub/RailsControllerRenderPathsExist
      render "components/preview", **opts
      # rubocop:enable GitHub/RailsControllerRenderPathsExist
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
end
