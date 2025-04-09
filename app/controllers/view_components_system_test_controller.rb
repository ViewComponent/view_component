# frozen_string_literal: true

if Rails.env.test?
  class ViewComponentsSystemTestController < ActionController::Base # :nodoc:
    before_action :validate_file_path

    def self.temp_dir
      @_tmpdir ||= FileUtils.mkdir_p("./tmp/view_components/").first
    end

    def system_test_entrypoint
      render file: @path
    end

    private

    # Ensure that the file path is valid and doesn't target files outside
    # the expected directory (e.g. via a path traversal or symlink attack)
    def validate_file_path
      base_path = ::File.realpath(self.class.temp_dir)
      @path = ::File.realpath(params.permit(:file)[:file], base_path)
      unless @path.start_with?(base_path)
        raise ViewComponent::SystemTestControllerNefariousPathError
      end
    end
  end
else
  class ViewComponentsSystemTestController # :nodoc:
    # stub for Zeitwerk to load
  end
end
