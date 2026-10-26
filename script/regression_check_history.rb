#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "regression_check"

options = {limit: 100, output: "tmp/regression-history", timeout: 90}
OptionParser.new do |parser|
  parser.banner = "Usage: ruby script/regression_check_history.rb [options]"
  parser.on("--limit NUMBER", Integer) { |value| options[:limit] = value }
  parser.on("--output DIR") { |value| options[:output] = value }
  parser.on("--timeout SECONDS", Integer) { |value| options[:timeout] = value }
end.parse!
abort "--limit must be between 1 and 100" unless (1..100).cover?(options[:limit])

output = File.expand_path(options[:output])
FileUtils.mkdir_p(output)
metadata = File.join(output, "pull_requests.json")
unless File.exist?(metadata)
  json, status = Open3.capture2e(
    "gh", "api", "--method", "GET", "repos/ViewComponent/view_component/pulls",
    "-f", "state=all", "-f", "sort=created", "-f", "direction=desc", "-f", "per_page=#{options[:limit]}"
  )
  abort json unless status.success?
  pulls = JSON.parse(json).map do |pr|
    pr.slice("number", "title", "html_url", "state", "merged_at", "created_at").merge(
      "base_sha" => pr.fetch("base").fetch("sha"), "head_sha" => pr.fetch("head").fetch("sha")
    )
  end
  File.write(metadata, JSON.pretty_generate(pulls) + "\n")
end
pulls = JSON.parse(File.read(metadata)).first(options[:limit])
pulls.each_slice(10) do |batch|
  refs = batch.map { |pr| "+refs/pull/#{pr.fetch("number")}/head:refs/regression-check/#{pr.fetch("number")}" }
  log, status = Open3.capture2e("git", "fetch", "--no-tags", "origin", *refs)
  abort log unless status.success?
end

results = pulls.map do |pr|
  directory = File.join(output, pr.fetch("number").to_s)
  result_path = File.join(directory, "results.json")
  report = File.exist?(result_path) ? JSON.parse(File.read(result_path)) : nil
  unless report && report["checker_digest"] == RegressionCheck::CHECKER_DIGEST &&
      report["head"] == pr.fetch("head_sha")
    puts "Checking ##{pr.fetch("number")}: #{pr.fetch("title")}"
    begin
      [pr.fetch("head_sha"), pr.fetch("base_sha")].each do |sha|
        _, status = Open3.capture2e("git", "cat-file", "-e", "#{sha}^{commit}")
        unless status.success?
          log, status = Open3.capture2e("git", "fetch", "--no-tags", "origin", sha)
          raise RegressionCheck::Error, log unless status.success?
        end
      end
      report = RegressionCheck::Check.new(
        base: pr.fetch("base_sha"), head: pr.fetch("head_sha"), output: directory,
        timeout: options[:timeout], install: true
      ).run
    rescue RegressionCheck::Error => error
      report = {
        "checker_digest" => RegressionCheck::CHECKER_DIGEST, "head" => pr.fetch("head_sha"),
        "tests" => [], "counts" => {}, "notes" => [], "error" => error.message
      }
      FileUtils.mkdir_p(directory)
      File.write(result_path, JSON.pretty_generate(report) + "\n")
      warn "##{pr.fetch("number")}: #{error.message}"
    end
  end
  pr.merge("report" => report)
end

File.write(File.join(output, "results.json"), JSON.pretty_generate(results) + "\n")
counts = results.flat_map { |pr| pr.fetch("report").fetch("tests") }.group_by { |test| test.fetch("status") }.transform_values(&:length)
selected_prs = results.count { |pr| pr.fetch("report").fetch("tests").any? }
errors = results.count { |pr| pr.fetch("report")["error"] }
lines = [
  "# Historical regression check", "",
  "Latest #{pulls.length} pull requests by creation time, including open and closed pull requests. PR metadata is frozen in `pull_requests.json`.", "",
  "Ruby #{RUBY_VERSION}; Rails 8.1 appraisal from each PR. Tests use each PR's dependencies.", "",
  "#{selected_prs} PRs had selected tests; #{errors} PRs could not complete dependency setup.", "",
  "Test results: #{counts.map { |status, count| "#{count} #{status}" }.join(", ")}.", "",
  "| PR | Demonstrated | Also passes on base | Inconclusive | Head failed | Notes |",
  "| --- | --- | --- | --- | --- | --- |"
]
results.each do |pr|
  report = pr.fetch("report")
  totals = report.fetch("counts")
  notes = (report["error"] || report.fetch("notes").join("; ")).gsub(RegressionCheck::ROOT + "/", "")
  notes = "No added or modified tests" if report.fetch("tests").empty? && notes.empty?
  values = [
    "[##{pr.fetch("number")}](#{pr.fetch("html_url")})",
    *%w[demonstrated not_demonstrated inconclusive head_failed].map { |key| totals.fetch(key, 0) },
    notes
  ]
  lines << "| #{values.map { |value| RegressionCheck.table_cell(value) }.join(" | ")} |"
end
lines << "" << "## Tests that also pass without the implementation" << ""
results.each do |pr|
  tests = pr.fetch("report").fetch("tests").select { |test| test.fetch("status") == "not_demonstrated" }
  next if tests.empty?

  lines << "- [##{pr.fetch("number")}](#{pr.fetch("html_url")}): #{tests.map { |test| "`#{test.fetch("id")}` (#{test.fetch("change")})" }.join(", ")}"
end
lines << "" << "## Implementation changes without selected tests" << ""
results.each do |pr|
  report = pr.fetch("report")
  next unless report.fetch("tests").empty? && !report["error"]

  paths = report.fetch("changed_files", []).map { |file| file.fetch("path") }.select do |path|
    path.start_with?("app/", "lib/") && !path.start_with?("app/views/test_mailer/")
  end
  next if paths.empty?

  lines << "- [##{pr.fetch("number")}](#{pr.fetch("html_url")}): #{paths.map { |path| "`#{path}`" }.join(", ")}"
end
lines << "" << "Passing on base is a review signal, not proof of missing coverage. Pre-fix exceptions, unsupported definitions, dependency problems, and historical head failures require manual review."
File.write(File.join(output, "summary.md"), lines.join("\n") + "\n")
puts lines.join("\n")
