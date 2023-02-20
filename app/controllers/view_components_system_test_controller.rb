# frozen_string_literal: true

class ViewComponentsSystemTestController < ActionController::Base # :nodoc:
  BASE_VIEW_COMPONENT_PATH = ::File.realpath("./tmp/view_components/").freeze

  before_action :validate_test_env
  before_action :validate_file_path

  def system_test_entrypoint
    render file: @path
  end

  private

  def validate_test_env
    raise "ViewComponentsSystemTestController must only be called in a test environment" unless Rails.env.test?
  end

  # Ensure that the file path is valid and doesn't target files outside
  # the expected directory (e.g. via a path traversal or symlink attack)
  def validate_file_path
    @path = ::File.realpath(params.permit(:file)[:file], BASE_VIEW_COMPONENT_PATH)
    unless @path.start_with?(BASE_VIEW_COMPONENT_PATH)
      raise ArgumentError, "Invalid file path"
    end
  end
end
