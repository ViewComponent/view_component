# frozen_string_literal: true

require "test_helper"

class ViewComponent::EngineTest < ActionDispatch::IntegrationTest
  def test_serve_static_previews?
    app.config.public_file_server.enabled = false
    refute ViewComponent::Engine.instance.serve_static_preview_assets?(app.config)
  end
end
