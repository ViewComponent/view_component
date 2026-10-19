# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def test_set_no_duplicate_autoload_paths
    test_path = "#{Rails.root}/my/components/previews" # set in sandbox/config/application.rb
    assert_equal 1, ActiveSupport::Dependencies.autoload_paths.count(test_path)
  end
end
