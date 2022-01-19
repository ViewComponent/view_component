# frozen_string_literal: true

task stats: "view_component:statsetup"

namespace :view_component do
  task statsetup: :environment do
    require "rails/code_statistics"

    ::STATS_DIRECTORIES << ["ViewComponents", ViewComponent::Base.generate.component_path]
  end
end
