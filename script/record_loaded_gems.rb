# frozen_string_literal: true

# Loaded via RUBYOPT by `rake all_tests` so every test process records which
# gems it required files from. See the `unused_gems_check` task.
at_exit do
  loaded = Gem.loaded_specs.values.select do |spec|
    $LOADED_FEATURES.any? { _1.start_with?("#{spec.full_gem_path}/") }
  end

  File.write(
    File.join(ENV.fetch("LOADED_GEMS_DIR"), "#{Process.pid}.txt"),
    loaded.map(&:name).join("\n")
  )
end
