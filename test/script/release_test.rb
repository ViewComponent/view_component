# frozen_string_literal: true

require "bundler"
require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

class ReleaseTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__).freeze

  def test_release_preserves_prerelease_versions_everywhere
    with_release_files do
      output, status = run_script("release", "4", "21", "0", "rc1")

      assert status.success?, output
      assert_includes read("lib/view_component/version.rb"), 'PRE = "rc1"'
      assert_includes read("docs/CHANGELOG.md"), "## 4.21.0.rc1"
      assert_equal "version: 4.21.0.rc1\n", read("docs/_data/library.yml")
      %w[Gemfile.lock gemfiles/rails_8.1.gemfile.lock].each do |path|
        assert_includes read(path), "view_component (4.21.0.rc1)"
      end
      assert_includes commands, "git switch --quiet -C release-4-21-0-rc1"
      assert_includes commands, "git commit --quiet -m release 4.21.0.rc1"
    end
  end

  def test_release_normalizes_rubygems_prerelease_versions
    with_release_files do
      output, status = run_script("release", "4", "21", "0", "beta-1")

      assert status.success?, output
      assert_includes read("lib/view_component/version.rb"), 'PRE = "beta.pre.1"'
      assert_includes read("Gemfile.lock"), "view_component (4.21.0.beta.pre.1)"
      assert_includes commands, "git switch --quiet -C release-4-21-0-beta-pre-1"
    end
  end

  def test_stable_release_clears_the_previous_prerelease
    with_release_files(version: "4.21.0.rc1") do
      output, status = run_script("release", "4", "21", "0")

      assert status.success?, output
      assert_includes read("lib/view_component/version.rb"), "PRE = nil"
      assert_equal "version: 4.21.0\n", read("docs/_data/library.yml")
      %w[Gemfile.lock gemfiles/rails_8.1.gemfile.lock].each do |path|
        assert_includes read(path), "view_component (4.21.0)"
        refute_includes read(path), "rc1"
      end
      assert_includes commands, "git switch --quiet -C release-4-21-0"
    end
  end

  def test_release_rejects_numeric_prerelease_labels
    with_release_files do
      original_version = read("lib/view_component/version.rb")
      output, status = run_script("release", "4", "21", "0", "1")

      refute status.success?
      assert_includes output, "pre-release version must contain a letter"
      assert_equal original_version, read("lib/view_component/version.rb")
      refute_includes commands, "git switch"
    end
  end

  def test_interactive_release_can_finalize_the_same_prerelease_version
    with_release_files(version: "4.21.0.rc1") do
      output, status = run_script("release", input: "4\n4.21.0\n")

      assert status.success?, output
      assert_includes read("lib/view_component/version.rb"), "PRE = nil"
      assert_equal "version: 4.21.0\n", read("docs/_data/library.yml")
    end
  end

  def test_release_rejects_core_version_numbers_with_leading_zeros
    with_release_files do
      original_version = read("lib/view_component/version.rb")
      output, status = run_script("release", "4", "021", "0")

      refute status.success?
      assert_includes output, "without leading zeros"
      assert_equal original_version, read("lib/view_component/version.rb")
      refute_includes commands, "git switch"
    end
  end

  def test_release_rejects_invalid_prerelease_labels
    with_release_files do
      original_version = read("lib/view_component/version.rb")
      output, status = run_script("release", "4", "21", "0", 'invalid"label')

      refute status.success?
      assert_includes output, "invalid pre-release version"
      assert_equal original_version, read("lib/view_component/version.rb")
      refute_includes commands, "git switch"
    end
  end

  def test_publish_uses_the_prerelease_tag_and_marks_the_release
    with_release_files(version: "4.21.0.rc1") do
      output, status = run_script("publish")

      assert status.success?, output
      assert_includes commands, "git tag v4.21.0.rc1"
      assert_includes commands, "gh release create v4.21.0.rc1"
      assert_includes commands, "--prerelease"
      assert_includes commands, "gh workflow run push_gem.yml --repo ViewComponent/view_component --ref v4.21.0.rc1"
    end
  end

  def test_publish_does_not_mark_stable_releases_as_prereleases
    with_release_files do
      output, status = run_script("publish")

      assert status.success?, output
      assert_includes commands, "gh release create v4.20.0"
      refute_includes commands, "--prerelease"
      assert_includes commands, "gh workflow run push_gem.yml --repo ViewComponent/view_component --ref v4.20.0"
    end
  end

  def test_publish_propagates_gem_dispatch_failures
    with_release_files do
      _output, status = run_script("publish", env: {"DISPATCH_STATUS" => "42"})

      assert_equal 42, status.exitstatus
      assert_includes commands, "gh workflow run push_gem.yml"
    end
  end

  def test_publish_stops_when_the_tag_cannot_be_pushed
    with_release_files do
      _output, status = run_script("publish", env: {"PUSH_STATUS" => "43"})

      assert_equal 43, status.exitstatus
      refute_includes commands, "gh release create"
      refute_includes commands, "gh workflow run"
    end
  end

  private

  def with_release_files(version: "4.20.0")
    Dir.mktmpdir("view-component-release-") do |directory|
      @directory = directory
      %w[release publish].each { |name| write("script/#{name}", File.read(File.join(ROOT, "script", name))) }
      major, minor, patch, pre = version.split(".", 4)
      write("lib/view_component/version.rb", <<~RUBY)
        module ViewComponent
          module VERSION
            MAJOR = #{major}
            MINOR = #{minor}
            PATCH = #{patch}
            PRE = #{pre.inspect}
            STRING = [MAJOR, MINOR, PATCH, PRE].compact.join(".").freeze
          end
        end
      RUBY
      write("lib/view_component/deprecation.rb", 'DEPRECATION_HORIZON = "5.0.0"')
      write("docs/CHANGELOG.md", "## main\n\n## #{version}\n\nRelease notes.\n\n## 4.19.0\n")
      write("docs/_data/library.yml", "version: #{version}\n")
      %w[Gemfile.lock gemfiles/rails_8.1.gemfile.lock].each do |path|
        write(path, "PATH\n  specs:\n    view_component (#{version})\n")
      end
      write("mocks.bash", <<~BASH)
        git() {
          printf 'git %s\\n' "$*" >> "$COMMAND_LOG"
          case "$1" in
            symbolic-ref) printf 'main\\n' ;;
            rev-list) printf '0\\n' ;;
            rev-parse) return 1 ;;
            push) return "${PUSH_STATUS:-0}" ;;
            status|fetch|ls-remote|switch|restore|add|commit|branch|checkout|tag) return 0 ;;
            *) printf 'Unexpected git operation: %s\\n' "$1" >&2; return 77 ;;
          esac
        }
        gh() {
          printf 'gh %s\\n' "$*" >> "$COMMAND_LOG"
          case "$1" in
            workflow) return "${DISPATCH_STATUS:-0}" ;;
            auth|repo|release) return 0 ;;
            *) printf 'Unexpected gh operation: %s\\n' "$1" >&2; return 77 ;;
          esac
        }
        bundle() { return 0; }
        ruby() {
          if [ "$1" = "script/sync_contributors.rb" ]; then return 0; fi
          command ruby "$@"
        }
      BASH
      yield
    end
  end

  def run_script(name, *args, env: {}, input: "")
    environment = {
      "BASH_ENV" => File.join(@directory, "mocks.bash"),
      "COMMAND_LOG" => File.join(@directory, "commands.log"),
      "RELEASE_DRY_RUN" => "1",
      "GITHUB_ACTIONS" => "true",
      "RUBYOPT" => nil
    }.merge(env)
    Bundler.with_unbundled_env do
      Open3.capture2e(environment, "bash", "script/#{name}", *args, chdir: @directory, stdin_data: input)
    end
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(File.join(@directory, path)))
    File.write(File.join(@directory, path), content)
  end

  def read(path)
    File.read(File.join(@directory, path))
  end

  def commands
    read("commands.log")
  end
end
