# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class BenchmarkWorkflowTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  WORKFLOW = YAML.load_file(File.join(ROOT, ".github/workflows/ci.yml"))

  def setup
    @directory = Dir.mktmpdir("view-component-benchmark-")
    @environment = {
      "GITHUB_OUTPUT" => File.join(@directory, "output"),
      "GITHUB_STEP_SUMMARY" => File.join(@directory, "summary.md"),
      "GITHUB_SHA" => "merge-sha",
      "GITHUB_REPOSITORY" => "ViewComponent/view_component",
      "GITHUB_SERVER_URL" => "https://github.com",
      "GITHUB_RUN_ID" => "123",
      "PR_NUMBER" => "456",
      "HEAD_SHA" => "head-sha",
      "RUBYOPT" => nil
    }
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_release_baseline_uses_the_previous_tag_on_the_base_branch
    initialize_base
    git("tag", "v4.21.0")
    release_sha = git("rev-parse", "HEAD")
    git("commit", "--allow-empty", "-qm", "Unreleased changes")
    git("checkout", "-qb", "other-release")
    git("commit", "--allow-empty", "-qm", "Other release")
    git("tag", "v5.0.0")
    git("checkout", "-q", "main")
    git("merge", "--no-ff", "-qm", "Merge changes", "other-release")
    git("tag", "not-a-release")

    stdout, stderr, status = run_step("benchmark-rails", "Use previous release as benchmark base")

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_equal release_sha, git("rev-parse", "HEAD")
    assert_equal "tag=v4.21.0\n", read("output")
  end

  def test_previous_release_can_be_a_prerelease
    initialize_base
    git("tag", "v4.22.0.rc1")
    git("commit", "--allow-empty", "-qm", "Unreleased changes")

    stdout, stderr, status = run_step("benchmark-rails", "Use previous release as benchmark base")

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_equal "tag=v4.22.0.rc1\n", read("output")
  end

  def test_missing_release_tag_fails_instead_of_comparing_against_main
    initialize_base

    _stdout, stderr, status = run_step("benchmark-rails", "Use previous release as benchmark base")

    refute status.success?
    assert_includes stderr, "No names found"
    refute File.exist?(File.join(@directory, "output"))
  end

  def test_successful_comparisons_are_saved_for_the_comment
    assert_comparison_report(head_ratio: 1.0, exitstatus: 0)
  end

  def test_regressions_still_fail_and_are_saved_for_the_comment
    assert_comparison_report(head_ratio: 2.0, exitstatus: 1)
    assert_includes read("tmp/performance/report.md"), "Regressed by more than 5.0%: component."
  end

  def test_comments_include_both_rails_results_and_are_updated_on_reruns
    prepare_comments

    stdout, stderr, status = run_step("benchmark-comment", "Post release benchmark results")

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_includes read("commands.log"), "--method POST repos/ViewComponent/view_component/issues/456/comments"
    assert_includes read("posted-comment.md"), "<!-- view-component-release-benchmarks -->"
    assert_includes read("posted-comment.md"), "https://github.com/ViewComponent/view_component/actions/runs/123"
    %w[8.1 main].each do |rails|
      assert_includes read("posted-comment.md"), read("artifacts/performance-rails-#{rails}/report.md")
    end

    write("artifacts/performance-rails-main/report.md", "Updated Rails main results\n")
    comment_pages = [
      [
        {"id" => 123, "user" => {"login" => "contributor"}, "body" => "<!-- view-component-release-benchmarks -->"},
        {"id" => 456, "user" => {"login" => "github-actions[bot]"}, "body" => "Another comment"}
      ],
      [
        {"id" => 789, "user" => {"login" => "github-actions[bot]"}, "body" => "<!-- view-component-release-benchmarks -->\nOld results"}
      ]
    ]
    stdout, stderr, status = run_step("benchmark-comment", "Post release benchmark results", env: {"COMMENT_PAGES" => JSON.generate(comment_pages)})

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_includes read("posted-comment.md"), "Updated Rails main results"
    assert_equal 1, read("commands.log").lines.count { |line| line.include?("--method POST") }
    assert_includes read("commands.log"), "--method PATCH repos/ViewComponent/view_component/issues/comments/789"
    assert_includes read("commands.log"), "--paginate --slurp repos/ViewComponent/view_component/issues/456/comments?per_page=100"
  end

  def test_missing_results_are_reported_explicitly
    prepare_comments
    File.delete(File.join(@directory, "artifacts/performance-rails-main/report.md"))

    stdout, stderr, status = run_step("benchmark-comment", "Post release benchmark results")

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_includes read("posted-comment.md"), "Benchmark results are unavailable."
    assert_includes stderr, "::warning::No benchmark report for Rails main"
  end

  def test_outdated_runs_do_not_overwrite_newer_results
    prepare_comments

    stdout, stderr, status = run_step("benchmark-comment", "Post release benchmark results", env: {"CURRENT_HEAD" => "new-head"})

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_includes stdout, "Skipping results for an outdated pull request revision."
    refute File.exist?(File.join(@directory, "posted-comment.md"))
    refute_includes read("commands.log"), "--method"
  end

  def test_comment_api_errors_fail_the_job
    prepare_comments

    _stdout, _stderr, status = run_step("benchmark-comment", "Post release benchmark results", env: {"COMMENT_STATUS" => "42"})

    assert_equal 42, status.exitstatus
    refute File.exist?(File.join(@directory, "posted-comment.md"))
  end

  def test_comment_lookup_errors_do_not_create_duplicate_comments
    prepare_comments

    _stdout, _stderr, status = run_step("benchmark-comment", "Post release benchmark results", env: {"LOOKUP_STATUS" => "43"})

    assert_equal 43, status.exitstatus
    refute File.exist?(File.join(@directory, "posted-comment.md"))
    refute_includes read("commands.log"), "--method"
  end

  def test_only_same_repository_release_prs_use_release_reporting
    benchmark = WORKFLOW.fetch("jobs").fetch("benchmark-rails")
    reporter = WORKFLOW.fetch("jobs").fetch("benchmark-comment")
    release_condition = benchmark.fetch("env").fetch("RELEASE_PR")
    [release_condition, reporter.fetch("if")].each do |condition|
      assert_includes condition, "github.event.pull_request.head.repo.full_name == github.repository"
      assert_includes condition, "startsWith(github.head_ref, 'release-')"
    end
    assert_includes reporter.fetch("if"), "!cancelled()"
    assert_equal "env.RELEASE_PR == 'true'", step("benchmark-rails", "Use previous release as benchmark base").fetch("if")
    base_checkout = benchmark.fetch("steps").find { |entry| entry.dig("with", "path") == "tmp/base" }
    assert_equal "${{ github.event.pull_request.base.sha }}", base_checkout.dig("with", "ref")
    assert_equal "${{ env.RELEASE_PR == 'true' && '0' || '1' }}", base_checkout.dig("with", "fetch-depth")
    assert_equal "read", WORKFLOW.dig("permissions", "contents")
    refute benchmark.key?("permissions")
    assert_equal({"actions" => "read", "pull-requests" => "write"}, reporter.fetch("permissions"))
    refute reporter.fetch("steps").any? { |entry| entry.fetch("uses", "").start_with?("actions/checkout@") }
    assert_equal({"pattern" => "performance-rails-*", "path" => "artifacts"}, step("benchmark-comment", "Download benchmark results").fetch("with"))
  end

  private

  def assert_comparison_report(head_ratio:, exitstatus:)
    results = lambda do |ratio|
      JSON.generate(
        "rails" => "8.1",
        "ruby" => RUBY_DESCRIPTION,
        "scenarios" => {"component" => {"ratio" => ratio, "ratios" => [ratio], "component_allocations" => 100}}
      )
    end
    mock_commands(<<~BASH)
      bundle() {
        case "$3" in
          performance/measure.rb)
            mkdir -p "$(dirname "$4")"
            if [ -n "${VIEW_COMPONENT_LIB:-}" ]; then
              printf '%s\\n' "$BASE_RESULT" > "$4"
            else
              printf '%s\\n' "$HEAD_RESULT" > "$4"
            fi
            ;;
          performance/compare.rb) "$RUBY_EXECUTABLE" "$COMPARE_SCRIPT" "$4" "$5" ;;
          *) return 77 ;;
        esac
      }
    BASH

    stdout, stderr, status = run_step("benchmark-rails", "Compare performance against base", env: {
      "BASE_RESULT" => results.call(1.0),
      "HEAD_RESULT" => results.call(head_ratio),
      "RUBY_EXECUTABLE" => RbConfig.ruby,
      "COMPARE_SCRIPT" => File.join(ROOT, "performance/compare.rb"),
      "BASE_REF" => "v4.21.0",
      "THRESHOLD" => "0.05"
    })

    assert_equal exitstatus, status.exitstatus, "#{stdout}\n#{stderr}"
    assert_equal 6, Dir[File.join(@directory, "tmp/performance/{base,head}/*.json")].size
    assert_equal read("summary.md"), read("tmp/performance/report.md")
    assert_includes read("tmp/performance/report.md"), "Base: `v4.21.0`; head: `merge-sha`"
    assert_includes read("tmp/performance/report.md"), "| Scenario | Base ratio | Head ratio |"
  end

  def prepare_comments
    %w[8.1 main].each { |rails| write("artifacts/performance-rails-#{rails}/report.md", "Results for Rails #{rails}\n") }
    @environment["COMMAND_LOG"] = File.join(@directory, "commands.log")
    @environment["COMMENT_PAGES"] = JSON.generate([[]])
    mock_commands(<<~BASH)
      gh() {
        printf '%s\\n' "$*" >> "$COMMAND_LOG"
        case "$2" in
          repos/*/pulls/*) printf '%s\\n' "${CURRENT_HEAD:-$HEAD_SHA}" ;;
          --paginate)
            if [ "${LOOKUP_STATUS:-0}" != "0" ]; then return "$LOOKUP_STATUS"; fi
            printf '%s\\n' "$COMMENT_PAGES"
            ;;
          --method)
            if [ "${COMMENT_STATUS:-0}" != "0" ]; then return "$COMMENT_STATUS"; fi
            cp benchmark-comment.md posted-comment.md
            ;;
          *) return 77 ;;
        esac
      }
    BASH
  end

  def initialize_base
    FileUtils.mkdir_p(File.join(@directory, "tmp/base"))
    git("init", "--quiet", "--initial-branch=main")
    git("commit", "--allow-empty", "-qm", "Previous release")
  end

  def git(*args)
    stdout, stderr, status = Open3.capture3(
      "git", "-C", File.join(@directory, "tmp/base"),
      "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false", *args
    )
    assert status.success?, "#{stdout}\n#{stderr}"
    stdout.strip
  end

  def mock_commands(content)
    @environment["BASH_ENV"] = write("mocks.bash", content)
  end

  def step(job, name)
    WORKFLOW.fetch("jobs").fetch(job).fetch("steps").find { |entry| entry["name"] == name }
  end

  def run_step(job, name, env: {})
    configuration = step(job, name)
    Open3.capture3(
      @environment.merge(env), "bash", "-e", "-o", "pipefail", "-c", configuration.fetch("run"),
      chdir: File.join(@directory, configuration.fetch("working-directory", "."))
    )
  end

  def write(path, content)
    full_path = File.join(@directory, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def read(path)
    File.read(File.join(@directory, path))
  end
end
