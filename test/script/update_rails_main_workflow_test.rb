# frozen_string_literal: true

require "bundler"
require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class UpdateRailsMainWorkflowTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  WORKFLOW = YAML.load_file(File.join(ROOT, ".github/workflows/update-rails-main.yml"))
  LOCKFILES = %w[main main_head].map { |version| "gemfiles/rails_#{version}.gemfile.lock" }.freeze

  def setup
    @directory = Dir.mktmpdir("view-component-rails-update-")
    @environment = {
      "RUBYOPT" => nil,
      "RUBYLIB" => nil,
      "GIT_CONFIG_GLOBAL" => File::NULL,
      "GIT_CONFIG_COUNT" => "0",
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_VERSION" => "system",
      "BUNDLE_PATH" => File.join(@directory, "gems"),
      "BUNDLE_APP_CONFIG" => File.join(@directory, ".bundle"),
      "BUNDLE_USER_HOME" => File.join(@directory, ".bundle-user"),
      "BUNDLE_LOCAL__RAILS" => File.join(@directory, "tmp/rails"),
      "BUNDLE_DISABLE_LOCAL_REVISION_CHECK" => "true",
      "GITHUB_OUTPUT" => File.join(@directory, "output")
    }
    write("Gemfile", "source \"https://rubygems.org\"\n")
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_runs_on_mondays_and_manually_against_main
    triggers = WORKFLOW.fetch("on", WORKFLOW[true])
    assert_equal [{"cron" => "0 9 * * 1"}], triggers.fetch("schedule")
    assert triggers.key?("workflow_dispatch")
    assert_equal({"group" => "update-rails-main", "cancel-in-progress" => false}, WORKFLOW.fetch("concurrency"))
    assert_equal "main", step("Checkout repository").dig("with", "ref")
    assert_equal "main", step("Checkout Rails main").dig("with", "ref")
    assert_equal false, step("Checkout Rails main").dig("with", "persist-credentials")
    assert_equal "4.0", step("Setup Ruby 4.0").dig("with", "ruby-version")
    assert_equal "head", step("Setup Ruby head").dig("with", "ruby-version")
  end

  def test_updates_both_lockfiles_to_the_same_checkout_and_preserves_the_rack_pin
    prepare_lockfiles
    original_manifests = LOCKFILES.to_h { |path| [path.delete_suffix(".lock"), read(path.delete_suffix(".lock"))] }
    previous_revision = git("tmp/rails", "rev-parse", "HEAD")
    write_gemspec("tmp/rails/rails.gemspec", "rails", "2.0.0", dependency: "activesupport")
    write_gemspec("tmp/rails/activesupport/activesupport.gemspec", "activesupport", "2.0.0")
    git("tmp/rails", "add", ".")
    git("tmp/rails", "commit", "-qm", "Update Rails")
    revision = git("tmp/rails", "rev-parse", "HEAD")

    run_step!("Record Rails revisions")
    assert_includes read("output"), "revision=#{revision}\n"
    assert_includes read("output"), "main=#{previous_revision}\n"
    assert_includes read("output"), "main_head=#{previous_revision}\n"

    ["Update Rails main on Ruby 4.0", "Update Rails main on Ruby head"].each { |name| run_step!(name) }
    run_step!("Verify Rails revisions", "EXPECTED_REVISION" => revision)

    LOCKFILES.each do |path|
      content = read(path)
      assert_includes content, "remote: https://github.com/rails/rails.git\n  revision: #{revision}\n  branch: main"
      assert_includes content, "rails (2.0.0)"
      assert_includes content, "activesupport (2.0.0)"
      assert_includes content, "revision: #{@rack_revision}\n  ref: #{@rack_revision}"
      assert_equal original_manifests.fetch(path.delete_suffix(".lock")), read(path.delete_suffix(".lock"))
    end

    updated_lockfiles = LOCKFILES.to_h { |path| [path, read(path)] }
    ["Update Rails main on Ruby 4.0", "Update Rails main on Ruby head"].each { |name| run_step!(name) }
    LOCKFILES.each { |path| assert_equal updated_lockfiles.fetch(path), read(path) }
  end

  def test_verification_rejects_mismatched_revisions_and_changed_sources
    revision = "a" * 40
    LOCKFILES.each { |path| write_lockfile(path, revision) }
    run_step!("Verify Rails revisions", "EXPECTED_REVISION" => revision)

    [
      [revision.next, "main", "https://github.com/rails/rails.git"],
      [revision, "other-branch", "https://github.com/rails/rails.git"],
      [revision, "main", "https://github.com/other/rails.git"]
    ].each do |sha, branch, remote|
      write_lockfile(LOCKFILES.last, sha, branch: branch, remote: remote)
      stdout, stderr, status = run_step("Verify Rails revisions", "EXPECTED_REVISION" => revision)

      refute status.success?, stdout
      assert_includes stderr, "#{LOCKFILES.last} must track Rails main at #{revision}"
    end
  end

  def test_pull_request_reuses_one_branch_and_only_commits_the_two_lockfiles
    pull_request = step("Create or update pull request")
    assert_equal LOCKFILES, pull_request.dig("with", "add-paths").split
    assert_equal "automation/update-rails-main", pull_request.dig("with", "branch")
    assert_equal "main", pull_request.dig("with", "base")
    assert_equal "${{ github.token }}", pull_request.dig("with", "token")
    assert_equal "write", WORKFLOW.dig("jobs", "update", "permissions", "pull-requests")
    steps = WORKFLOW.dig("jobs", "update", "steps")
    assert_equal pull_request, steps.last
    refute steps.any? { |entry| entry["continue-on-error"] || entry["if"] == "always()" }
  end

  def test_changelog_check_exempts_only_the_automated_lockfiles
    lint = YAML.load_file(File.join(ROOT, ".github/workflows/lint.yml"))
    script = lint.dig("jobs", "changelog", "steps").first.fetch("run")
    script = script.gsub("${{needs.changedfiles.outputs.markdown}}", "")

    [LOCKFILES, LOCKFILES + ["Gemfile.lock", "docs/Gemfile.lock"]].each do |paths|
      stdout, stderr, status = run_shell(script.gsub("${{needs.changedfiles.outputs.all}}", paths.join(" ")))
      assert status.success?, "#{stdout}\n#{stderr}"
    end

    ["lib/view_component/base.rb", "gemfiles/rails_8.1.gemfile.lock", "gemfiles/rails_main.gemfile"].each do |path|
      stdout, _stderr, status = run_shell(script.gsub("${{needs.changedfiles.outputs.all}}", (LOCKFILES + [path]).join(" ")))
      refute status.success?, path
      assert_includes stdout, "Please make sure that you add a docs/CHANGELOG.md entry"
    end
  end

  private

  def prepare_lockfiles
    write_gemspec("tmp/rails/rails.gemspec", "rails", "1.0.0", dependency: "activesupport")
    write_gemspec("tmp/rails/activesupport/activesupport.gemspec", "activesupport", "1.0.0")
    write_gemspec("tmp/rack/rack.gemspec", "rack", "1.0.0")
    %w[rails rack].each do |name|
      git("tmp/#{name}", "init", "-q", "--initial-branch=main")
      git("tmp/#{name}", "add", ".")
      git("tmp/#{name}", "commit", "-qm", "Initial version")
    end
    @rack_revision = git("tmp/rack", "rev-parse", "HEAD")
    %w[main main_head].each do |version|
      path = "gemfiles/rails_#{version}.gemfile"
      write(path, <<~RUBY)
        source "https://rubygems.org"
        gem "rails", git: "https://github.com/rails/rails.git", branch: "main"
        gem "rack", git: "file://#{@directory}/tmp/rack", ref: "#{@rack_revision}"
      RUBY
      stdout, stderr, status = run_shell("bundle lock", "BUNDLE_GEMFILE" => path)
      assert status.success?, "#{stdout}\n#{stderr}"
    end
  end

  def write_gemspec(path, name, version, dependency: nil)
    write(path, <<~RUBY)
      Gem::Specification.new do |spec|
        spec.name = "#{name}"
        spec.version = "#{version}"
        spec.summary = "Workflow test fixture"
        spec.authors = ["Test"]
        #{"spec.add_dependency \"#{dependency}\", \"= #{version}\"" if dependency}
      end
    RUBY
  end

  def write_lockfile(path, revision, branch: "main", remote: "https://github.com/rails/rails.git")
    write(path, <<~LOCK)
      GIT
        remote: #{remote}
        revision: #{revision}
        branch: #{branch}
        specs:
          rails (1.0.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        rails!
    LOCK
  end

  def step(name)
    WORKFLOW.dig("jobs", "update", "steps").find { |entry| entry["name"] == name }
  end

  def run_step!(name, env = {})
    stdout, stderr, status = run_step(name, env)
    assert status.success?, "#{stdout}\n#{stderr}"
  end

  def run_step(name, env = {})
    configuration = step(name)
    run_shell(configuration.fetch("run"), configuration.fetch("env", {}).merge(env))
  end

  def run_shell(script, env = {})
    Open3.capture3(@environment.merge(env), "bash", "-e", "-o", "pipefail", "-c", script, chdir: @directory)
  end

  def git(path, *args)
    stdout, stderr, status = Open3.capture3(
      "git", "-C", File.join(@directory, path),
      "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false", *args
    )
    assert status.success?, "#{stdout}\n#{stderr}"
    stdout.strip
  end

  def write(path, content)
    full_path = File.join(@directory, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def read(path)
    File.read(File.join(@directory, path))
  end
end
