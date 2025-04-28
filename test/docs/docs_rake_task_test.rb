# frozen_string_literal: true

require "test_helper"

class DocsRakeTaskTest < ActiveSupport::TestCase
  def test_rake_task
    load "Rakefile"

    assert_nothing_raised do
      Rake::Task["docs:build"].invoke
    end

    Rake::Task.clear
  end
end
