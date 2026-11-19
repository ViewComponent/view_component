# frozen_string_literal: true

require "bundler"
require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class UpdateDependenciesWorkflowTest < Minitest::Test
  WORKFLOW = YAML.load_file(File.expand_path("../../.github/workflows/update-dependencies.yml", __dir__))
  LOCKFILE = "gemfiles/rails_main_head.gemfile.lock"

  def setup
    @directory = Dir.mktmpdir("view-component-dependencies-")
    FileUtils.mkdir_p(File.join(@directory, "gemfiles"))
    rake = Gem::Specification.find_by_name("rake")
    write("gemfiles/rails_main_head.gemfile", <<~RUBY)
      source "https://rubygems.org"
      gem "rake", "= #{rake.version}"
    RUBY
    @lockfile = <<~LOCK
      GEM
        remote: https://rubygems.org/
        specs:
          rake (#{rake.version})

      PLATFORMS
        ruby

      DEPENDENCIES
        rake (= #{rake.version})

      BUNDLED WITH
         #{Bundler::VERSION}
    LOCK
    checksums = "CHECKSUMS\n  rake (#{rake.version})\n\n"
    write(LOCKFILE, @lockfile.sub("BUNDLED WITH", "#{checksums}BUNDLED WITH"))
    write("mocks.bash", <<~BASH)
      bundle() {
        if [ "$1" = lock ]; then
          return "${UPDATE_STATUS:-0}"
        fi
        "$RUBY_EXECUTABLE" "$BUNDLE_EXECUTABLE" "$@" --local
      }
    BASH
    @environment = {
      "BASH_ENV" => File.join(@directory, "mocks.bash"),
      "RUBY_EXECUTABLE" => RbConfig.ruby,
      "BUNDLE_EXECUTABLE" => Gem.bin_path("bundler", "bundle", Bundler::VERSION),
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_LOCKFILE" => nil,
      "BUNDLE_APP_CONFIG" => File.join(@directory, ".bundle"),
      "RUBYOPT" => nil
    }
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_removes_existing_checksums_and_passes_a_frozen_install
    stdout, stderr, status = run_step

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_equal @lockfile, File.read(File.join(@directory, LOCKFILE))
    assert_includes stdout, "Bundle complete!"
  end

  def test_lockfiles_without_checksums_are_unchanged
    write(LOCKFILE, @lockfile)

    stdout, stderr, status = run_step

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_equal @lockfile, File.read(File.join(@directory, LOCKFILE))
  end

  def test_update_errors_stop_before_rewriting_the_lockfile
    original = File.read(File.join(@directory, LOCKFILE))

    _stdout, _stderr, status = run_step("UPDATE_STATUS" => "42")

    assert_equal 42, status.exitstatus
    assert_equal original, File.read(File.join(@directory, LOCKFILE))
  end

  def test_frozen_install_errors_fail_the_update
    write("gemfiles/rails_main_head.gemfile", "source \"https://rubygems.org\"\ngem \"rake\"\n")

    _stdout, stderr, status = run_step

    refute status.success?
    assert_includes stderr, "frozen mode"
  end

  private

  def run_step(env = {})
    step = WORKFLOW.fetch("jobs").fetch("update").fetch("steps").find { |entry| entry["name"] == "Update Ruby head dependencies" }
    Open3.capture3(@environment.merge(env), "bash", "-e", "-o", "pipefail", "-c", step.fetch("run"), chdir: @directory)
  end

  def write(path, content)
    File.write(File.join(@directory, path), content)
  end
end
