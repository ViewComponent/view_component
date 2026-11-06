# frozen_string_literal: true

namespace :view_component do
  namespace :herb do
    desc "Check that component HTML+ERB templates compile through Herb"
    task check: :environment do
      # Components are only known once loaded.
      Rails.application.eager_load!

      failures = ViewComponent::HerbChecker.check

      if failures.empty?
        puts "All component HTML+ERB templates compile through Herb."
      else
        failures.each do |failure|
          puts "#{failure.identifier}:"
          failure.error.message.strip.lines.first(10).each { |line| puts "  #{line}" }
          puts
        end

        abort "#{failures.size} component #{"HTML+ERB template".pluralize(failures.size)} failed to compile through Herb."
      end
    end
  end
end

# `herb:check` reads the view paths, which don't hold component templates.
task "herb:check" => "view_component:herb:check" unless Rails.application.config.api_only
