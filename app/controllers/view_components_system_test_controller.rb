# frozen_string_literal: true

class ViewComponentsSystemTestController < ActionController::Base # :nodoc:
  TEMP_DIR = FileUtils.mkdir_p("./tmp/view_components/").first

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
    base_path = ::File.realpath(TEMP_DIR)
    @path = ::File.realpath(params.permit(:file)[:file], base_path)
    unless @path.start_with?(base_path)
      raise ArgumentError, "Invalid file path"
    end
  end
end
