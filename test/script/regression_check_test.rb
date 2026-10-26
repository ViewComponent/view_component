# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../script/regression_check"

class RegressionCheckTest < Minitest::Test
  def test_escapes_markdown_table_cells
    assert_equal "\\\\", RegressionCheck.table_cell("\\")
    assert_equal "\\|", RegressionCheck.table_cell("|")
    assert_equal ("\\" * 3) + "| next", RegressionCheck.table_cell("\\|\nnext")
  end

  def test_parses_methods_and_rails_test_blocks_without_matching_strings
    definitions = RegressionCheck::TestDefinitions.new(<<~RUBY)
      module Examples
        class ExampleTest
          def test_method
            assert true
          end
          test "a useful test" do
            assert true
          end
          def self.test_not_an_instance_method; end
          def helper; end
          text = "def test_not_really_a_test"
          def test_hidden_later; end
          private :test_hidden_later
          private def test_inline_private; end
          private
          def test_private_helper; end
        end
      end
    RUBY

    assert_equal ["Examples::ExampleTest#test_method", "Examples::ExampleTest#test_a_useful_test"], definitions.tests.keys
    assert_empty definitions.unsupported
  end

  def test_reports_dynamic_and_rspec_definitions
    definitions = RegressionCheck::TestDefinitions.new(<<~RUBY)
      class ExampleTest
        define_method("test_dynamic") { assert true }
        test(name) { assert true }
        it("does something") { expect(true).to eq(true) }
      end
    RUBY

    assert_equal 3, definitions.unsupported.length
  end

  def test_rejects_invalid_ruby
    assert_raises(RegressionCheck::Error) { RegressionCheck::TestDefinitions.new("class") }
  end

  def test_demonstrates_only_the_added_test_and_preserves_mailer_fixtures
    with_repository do
      write("app/views/test_mailer/example.html.erb", "fixture")
      write("lib/behavior.rb", 'VALUE = "new"')
      add_test('assert_equal "new", VALUE; assert_equal "fixture", File.read("app/views/test_mailer/example.html.erb")')
      report = check

      assert_equal({"demonstrated" => 1}, report["counts"])
      assert_equal "ExampleTest#test_regression", report["tests"].first["id"]
      assert_equal "failed", report["tests"].first.dig("base", "status")
      assert_equal 'VALUE = "new"', File.read(File.join(@repo, "lib/behavior.rb"))
      assert_empty Dir[File.join(@repo, "tmp/regression-check-*")]
    end
  end

  def test_reports_tests_that_also_pass_on_base
    with_repository do
      add_test("assert true")

      assert_equal({"not_demonstrated" => 1}, check["counts"])
    end
  end

  def test_checks_modified_existing_tests
    with_repository do
      write("test/example_test.rb", test_source("assert true"))
      @base = commit
      write("lib/behavior.rb", 'VALUE = "new"')
      write("test/example_test.rb", test_source('assert_equal "new", VALUE'))
      report = check

      assert_equal({"demonstrated" => 1}, report["counts"])
      assert_equal "modified", report["tests"].first["change"]
    end
  end

  def test_errors_are_not_treated_as_demonstrated_regressions
    with_repository do
      write("lib/behavior.rb", 'VALUE = "new"')
      add_test('raise "missing feature" if VALUE == "old"; assert true')
      report = check

      assert_equal({"inconclusive" => 1}, report["counts"])
      assert_equal "error", report["tests"].first.dig("base", "status")
    end
  end

  def test_head_assertion_failures_are_not_regressions
    with_repository do
      add_test('assert_equal "new", VALUE')

      assert_equal({"head_failed" => 1}, check["counts"])
    end
  end

  def test_skips_and_zero_assertions_are_inconclusive
    with_repository do
      add_test('skip "unsupported"')
      assert_equal({"inconclusive" => 1}, check["counts"])

      add_test("nil")
      assert_equal({"inconclusive" => 1}, check["counts"])
    end
  end

  def test_boot_errors_and_stale_results_cannot_pass
    with_repository do
      write("lib/behavior.rb", 'VALUE = "new"')
      add_test('assert_equal "new", VALUE')
      assert_equal({"demonstrated" => 1}, check["counts"])
      write("test/example_test.rb", "raise 'boot failure'\n" + test_source('assert_equal "new", VALUE'))

      assert_equal({"inconclusive" => 1}, check["counts"])
    end
  end

  def test_zero_test_runs_are_inconclusive
    with_repository do
      add_test("assert true", prefix: "if false\n", suffix: "\nend")

      assert_equal({"inconclusive" => 1}, check["counts"])
    end
  end

  def test_timeouts_are_inconclusive
    with_repository do
      add_test("sleep 30; assert true")
      report = check(timeout: 0.2)

      assert_equal({"inconclusive" => 1}, report["counts"])
      assert_match(/timed out/, report["tests"].first["reason"])
    end
  end

  def test_runs_normal_exit_hooks_without_rerunning_tests
    with_repository do
      write("test/example_test.rb", test_source(<<~RUBY.chomp))
        at_exit { puts "cleanup ran" }
        assert true
        end
        def test_only_runs_once
          refute File.exist?("already_ran.txt")
          File.write("already_ran.txt", "ran")
      RUBY
      report = check

      assert_equal({"not_demonstrated" => 2}, report["counts"])
      assert report["tests"].all? { |test| test["head"]["assertions"] == 1 }
      assert_includes File.read(File.join(@repo, "tmp/results/0-head.log")), "cleanup ran"
    end
  end

  def test_restores_deleted_implementation_and_removes_new_implementation_files
    with_repository do
      write("lib/deleted.rb", "old")
      @base = commit
      FileUtils.rm(File.join(@repo, "lib/deleted.rb"))
      write("lib/added.rb", "new")
      add_test('refute File.exist?("lib/deleted.rb"); assert File.exist?("lib/added.rb")')

      assert_equal({"demonstrated" => 1}, check["counts"])
    end
  end

  def test_restores_packaged_app_implementation
    with_repository do
      write("app/example.rb", "old")
      @base = commit
      write("app/example.rb", "new")
      add_test('assert_equal "new", File.read("app/example.rb")')

      assert_equal({"demonstrated" => 1}, check["counts"])
    end
  end

  def test_file_renames_do_not_select_unchanged_tests
    with_repository do
      FileUtils.mv(File.join(@repo, "test/example_test.rb"), File.join(@repo, "test/renamed_test.rb"))

      assert_empty check["tests"]
    end
  end

  def test_unsupported_specs_are_explicit
    with_repository do
      write("spec/example_spec.rb", 'describe("example") { it("works") { expect(true).to eq(true) } }')
      report = check

      assert_empty report["tests"]
      assert_includes report["notes"], "Unsupported test file: spec/example_spec.rb"
    end
  end

  def test_uses_merge_base_rather_than_unrelated_base_branch_changes
    with_repository do
      git("checkout", "-b", "other")
      write("lib/behavior.rb", 'VALUE = "unrelated"')
      other = commit
      git("checkout", "-b", "feature", @base)
      write("lib/behavior.rb", 'VALUE = "new"')
      add_test('assert_equal "new", VALUE')
      report = check(base: other)

      assert_equal @base, report["base"]
      assert_equal({"demonstrated" => 1}, report["counts"])
    end
  end

  def test_selects_tests_independently_when_they_share_a_file
    with_repository do
      write("lib/behavior.rb", 'VALUE = "new"')
      write("test/example_test.rb", test_source(<<~RUBY.chomp))
        assert_equal "new", VALUE
        end
        def test_also_passes
          assert true
      RUBY
      report = check

      assert_equal({"demonstrated" => 1, "not_demonstrated" => 1}, report["counts"])
    end
  end

  def test_runs_literal_rails_style_test_blocks
    with_repository do
      write("lib/behavior.rb", 'VALUE = "new"')
      write("test/example_test.rb", <<~RUBY)
        require "minitest/autorun"
        require "behavior"
        class ExampleTest < Minitest::Test
          def self.test(name, &block)
            define_method("test_\#{name.gsub(/\\s+/, "_")}", &block)
          end
          test "a literal description" do
            assert_equal "new", VALUE
          end
        end
      RUBY

      assert_equal({"demonstrated" => 1}, check["counts"])
    end
  end

  def test_selects_the_engine_test_bootstrap
    with_repository do
      write("lib/behavior.rb", 'VALUE = "new"')
      write("test_engine/test_helper.rb", "ENGINE_BOOTSTRAPPED = true\n")
      write("test_engine/test/example_test.rb", "require 'test_helper'\n" +
        test_source('assert ENGINE_BOOTSTRAPPED; assert_equal "new", VALUE'))

      assert_equal({"demonstrated" => 1}, check["counts"])
    end
  end

  def test_reuses_the_configured_bundle_outside_the_temporary_checkout
    with_repository do
      Bundler.settings.temporary(path: "vendor/bundle") do
        checker = RegressionCheck::Check.new(root: @repo, base: @base, output: File.join(@repo, "tmp/results"))
        environment = checker.send(:test_environment, File.join(@repo, "tmp/head"))

        assert_equal File.join(Bundler.root, "vendor/bundle"), environment["BUNDLE_PATH"]
      end
    end
  end

  def test_explicit_strict_mode_requires_demonstrated_regressions
    with_repository do
      add_test("assert true")
      head = commit
      previous = ENV["BUNDLE_GEMFILE"]
      ENV["BUNDLE_GEMFILE"] = File.join(@repo, "Gemfile")
      checker = RegressionCheck::Check.new(
        root: @repo, base: @base, head: head, output: File.join(@repo, "tmp/results")
      )
      report = nil
      capture_io { report = checker.run }
      assert_equal 0, RegressionCheck.exit_code(report, strict: false)
      assert_equal 1, RegressionCheck.exit_code(report, strict: true)
      assert_equal 1, RegressionCheck.exit_code({"tests" => [], "notes" => []}, strict: true)
      report["tests"].first["status"] = "demonstrated"
      assert_equal 0, RegressionCheck.exit_code(report, strict: true)
      report["notes"] << "Unsupported test definition"
      assert_equal 1, RegressionCheck.exit_code(report, strict: true)
    ensure
      ENV["BUNDLE_GEMFILE"] = previous
    end
  end

  private

  def with_repository
    FileUtils.mkdir_p(File.join(RegressionCheck::ROOT, "tmp"))
    Dir.mktmpdir("regression-fixture-", File.join(RegressionCheck::ROOT, "tmp")) do |directory|
      @repo = directory
      git("init", "--quiet")
      git("config", "user.name", "Regression checker")
      git("config", "user.email", "regression-check@example.invalid")
      write(".gitignore", "/tmp/\n")
      write("Gemfile", "source 'https://rubygems.org'\ngem 'minitest', '#{Minitest::VERSION}'\n")
      write("view_component.gemspec", <<~RUBY)
        Gem::Specification.new do |spec|
          spec.name = "view_component"
          spec.version = "0.0.0"
          spec.summary = "Regression check fixture"
          spec.authors = ["Regression checker"]
          spec.files = Dir["lib/**/*", "app/**/*"]
        end
      RUBY
      write("lib/behavior.rb", 'VALUE = "old"')
      write("test/example_test.rb", test_source('flunk "unrelated existing failure"', name: "test_existing"))
      environment = {"BUNDLE_GEMFILE" => File.join(@repo, "Gemfile")}
      bundle_path = Bundler.settings[:path]
      environment["BUNDLE_PATH"] = File.expand_path(bundle_path, Bundler.root) if bundle_path
      output, status = Bundler.with_unbundled_env do
        Open3.capture2e(environment, "bundle", "lock", "--local", chdir: @repo)
      end
      raise output unless status.success?

      @base = commit
      yield
    end
  end

  def write(path, content)
    destination = File.join(@repo, path)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, content)
  end

  def test_source(body, name: "test_regression")
    <<~RUBY
      require "minitest/autorun"
      require "behavior"
      class ExampleTest < Minitest::Test
        def #{name}
          #{body}
        end
      end
    RUBY
  end

  def add_test(body, prefix: "", suffix: "")
    write("test/example_test.rb", prefix + test_source('flunk "unrelated existing failure"', name: "test_existing") +
      test_source(body) + suffix)
  end

  def git(*args)
    output, status = Open3.capture2e("git", "-C", @repo, *args)
    raise output unless status.success?

    output.strip
  end

  def commit
    git("add", ".")
    git("-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Fixture")
    git("rev-parse", "HEAD")
  end

  def check(base: @base, **options)
    head = commit
    previous = ENV["BUNDLE_GEMFILE"]
    ENV["BUNDLE_GEMFILE"] = "Gemfile"
    report = nil
    capture_io do
      report = RegressionCheck::Check.new(
        root: @repo, base: base, head: head, output: File.join(@repo, "tmp/results"), **options
      ).run
    end
    report
  ensure
    ENV["BUNDLE_GEMFILE"] = previous
  end
end
