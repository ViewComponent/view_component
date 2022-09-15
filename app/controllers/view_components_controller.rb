# frozen_string_literal: true

require "rails/application_controller"

class ViewComponentsController < Rails::ApplicationController # :nodoc:
  include ViewComponent::PreviewActions

  if Rails.env.test?
    def system_test_entrypoint
      render file: "./tmp/view_component_integrations/#{file_param[:file]}", status: 200
    end
  end

  private

  def file_param
    params.permit(:file)
  end
end
