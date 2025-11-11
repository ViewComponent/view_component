# frozen_string_literal: true

require "test_helper"

# `rails stats` command has been removed in Rails 8.1
if Rails.version.to_f < 8.1
  class TasksTest < ActiveSupport::TestCase
    setup do
      Kernel.silence_warnings do
        Rails.application.load_tasks
      end
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
end
