# frozen_string_literal: true

require "rails/application_controller"

class ViewComponentsController < Rails::ApplicationController # :nodoc:
  include ViewComponent::PreviewActions

  def system_test_entrypoint
    render file: "./tmp/#{params[:file]}", status: 200
  end
end
