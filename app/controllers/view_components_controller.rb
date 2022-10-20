# frozen_string_literal: true

require "rails/application_controller"

class ViewComponentsController < Rails::ApplicationController # :nodoc:
  include ViewComponent::PreviewActions

  if Rails.env.test?
    def system_test_entrypoint
      render file: "./tmp/view_components/#{params.permit(:file)[:file]}"
    end
  end
end
