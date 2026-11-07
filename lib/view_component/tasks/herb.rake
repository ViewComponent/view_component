# frozen_string_literal: true

namespace :view_component do
  namespace :herb do
    # Prints the component templates Herb fails to compile and returns them.
    check_components = lambda do
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
      end

      failures
    end

    failure_message = lambda do |failures|
      "#{failures.size} component #{"HTML+ERB template".pluralize(failures.size)} failed to compile through Herb."
    end

    desc "Check that component HTML+ERB templates compile through Herb"
    task check: :environment do
      failures = check_components.call
      abort failure_message.call(failures) if failures.any?
    end

    # Runs before `herb:check`, and fails only once it has finished, so the
    # views are checked even when a component template fails.
    task report: :environment do
      failures = check_components.call
      at_exit { abort failure_message.call(failures) } if failures.any?
    end
  end
end

# `herb:check` reads the view paths, which don't hold component templates.
task "herb:check" => "view_component:herb:report" unless Rails.application.config.api_only
