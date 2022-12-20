# frozen_string_literal: true

require "rails/application_controller"

class ViewComponentsSystemTestController < Rails::ApplicationController # :nodoc:
  def system_test_entrypoint
    render file: "./tmp/view_components/#{params.permit(:file)[:file]}"
  end
end
