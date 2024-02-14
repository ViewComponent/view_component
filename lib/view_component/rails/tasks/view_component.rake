# frozen_string_literal: true

task stats: "view_component:statsetup"

namespace :view_component do
  task :statsetup do
    # :nocov:
    require "rails/code_statistics"

    dir = ViewComponent::Base.view_component_path
    ::STATS_DIRECTORIES << ["ViewComponents", dir] if File.directory?(Rails.root + dir)
    # :nocov:
  end
end
