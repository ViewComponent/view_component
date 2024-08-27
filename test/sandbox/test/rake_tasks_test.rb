# frozen_string_literal: true

require "test_helper"

if Rails.version.to_f < 8.0
  module ViewComponent
    class RakeTasksTest < TestCase
      def setup
        Kernel.silence_warnings do
          Sandbox::Application.load_tasks
        end
      end

      def test_statsetup_task
        Rake::Task["view_component:statsetup"].invoke
        assert_includes ::STATS_DIRECTORIES, ["ViewComponents", "app/components"]
      end
    end
  end
end
