# frozen_string_literal: true

require "test_helper"

class TasksTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks
  end

  teardown do
    Rake.application.clear
  end

  test "adds components to rails stats" do
    Dir.chdir(Rails.root) do
      assert_output(/ViewComponents/) do
        Rake::Task["stats"].invoke
      end
    end
  end
end
