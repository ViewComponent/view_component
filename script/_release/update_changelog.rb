#!/usr/bin/env ruby
# frozen_string_literal: true

require "git"

previous_version = ARGV[0]
new_version = ARGV[1]

if previous_version.nil? || new_version.nil?
  raise "Usage: update_changelog.rb [previous_version] [new_version]"
end

unreleased_changes_url =
  "https://github.com/github/view_component/compare/v#{new_version}...main"
commits_in_this_release =
  Git.open(File.expand_path("../..", __dir__)).log.between("v#{previous_version}", "HEAD")
changelog_entries_in_this_release =
  commits_in_this_release.map do |commit|
    "* #{commit.message.lines.first.strip}\n\n    *#{commit.author.name}*"
  end

new_release_notes =
  "[unreleased-changes]: %{unreleased_changes_url}\n\n%{version_heading}\n\n%{changelog_entries}" %
  {
    unreleased_changes_url: unreleased_changes_url,
    version_heading: "## v#{new_version}",
    changelog_entries: changelog_entries_in_this_release.join("\n\n"),
  }

changelog_path = File.expand_path("../../docs/CHANGELOG.md", __dir__)
File.write(
  changelog_path,
  File.read(changelog_path).sub(/\[unreleased-changes\]: \S+/, new_release_notes)
)
