# frozen_string_literal: true

require "json"
require "minitest"

file, selection_path, result_path = ARGV
ARGV.clear
selection = JSON.parse(File.read(selection_path))
root = Dir.pwd
$LOAD_PATH.unshift(File.join(root, "lib"))
$LOAD_PATH.unshift(File.join(root, file.start_with?("test_engine/") ? "test_engine" : "test"))
$LOAD_PATH.unshift(File.join(root, "test_engine/lib")) if file.start_with?("test_engine/")
require File.join(root, file)

definitions = {}
Minitest.seed = 0
selected_methods = Minitest::Runnable.runnables.to_h do |klass|
  selected = klass.runnable_methods.select do |name|
    source_file, line = klass.instance_method(name).source_location
    next unless source_file && File.expand_path(source_file) == File.join(root, file)

    definition = selection.find { |test| test["name"] == name && (test["line"]..test["end_line"]).cover?(line) }
    definitions["#{klass.name}##{name}"] = definition["definition"] if definition
    definition
  end
  [klass, selected]
end
selected_methods.each { |klass, methods| klass.define_singleton_method(:runnable_methods) { methods } }

reporter_class = Class.new(Minitest::AbstractReporter) do
  define_method(:initialize) do
    @results = []
  end

  define_method(:record) do |result|
    id = "#{result.class_name}##{result.name}"
    status = if result.skipped?
      "skipped"
    elsif result.failures.any? { |failure| failure.is_a?(Minitest::UnexpectedError) }
      "error"
    elsif result.passed?
      "passed"
    else
      "failed"
    end
    @results << {
      "id" => id, "definition" => definitions.fetch(id), "status" => status,
      "assertions" => result.assertions,
      "failures" => result.failures.map { |failure| {"class" => failure.class.name, "message" => failure.message} }
    }
    write_results(false)
  end

  define_method(:report) do
    write_results(true)
  end

  define_method(:write_results) do |completed|
    File.write("#{result_path}.tmp", JSON.pretty_generate("tests" => @results, "completed" => completed))
    File.rename("#{result_path}.tmp", result_path)
  end
end

File.write(result_path, JSON.generate("tests" => []))
Minitest.singleton_class.define_method(:plugin_regression_check_init) do |_options|
  reporter << reporter_class.new
end
Minitest.extensions << "regression_check"
ARGV.replace(["--seed", "0"])
Minitest.autorun
