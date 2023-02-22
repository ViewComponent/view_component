# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class RakeTasksTest < TestCase
    def setup
      Sandbox::Application.load_tasks
    end

    def test_statsetup_task
      Rake::Task["view_component:statsetup"].invoke
      assert_includes ::STATS_DIRECTORIES, ["ViewComponents", "app/components"]
    end
  end
end
