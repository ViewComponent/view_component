# frozen_string_literal: true

require "test_helper"
require "rake"

module ViewComponent
  class RakeTest < TestCase
    def test_statsetup_task
      load "Rakefile"

      assert_nothing_raised do
        Rake::Task["docs:build"].invoke
      end
    end
  end
end
