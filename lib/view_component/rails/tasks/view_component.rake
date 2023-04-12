# frozen_string_literal: true

task stats: "view_component:statsetup"

namespace :view_component do
  task :statsetup do
    require "rails/code_statistics"

    ::STATS_DIRECTORIES << ["ViewComponents", ViewComponent::Base.view_component_path]
  end
end
