# frozen_string_literal: true

class ViewComponentsSystemTestController < ActionController::Base # :nodoc:
  def system_test_entrypoint
    render file: "./tmp/view_components/#{params.permit(:file)[:file]}"
  end
end
