#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "bundler"
require "digest"
require "json"
require "open3"
require "optparse"
require "pathname"
require "prism"
require "rbconfig"
require "tmpdir"

module RegressionCheck
  ROOT = File.expand_path("..", __dir__)
  RUNNER = File.expand_path("regression_check/runner.rb", __dir__)
  CHECKER_DIGEST = Digest::SHA256.hexdigest(File.read(__FILE__) + File.read(RUNNER))

  class Error < StandardError; end

  class TestDefinitions < Prism::Visitor
    attr_reader :tests, :unsupported

    def initialize(source)
      @tests = {}
      @unsupported = []
      @scope = []
      @visibility = [:public]
      result = Prism.parse(source)
      raise Error, result.errors.map(&:message).join("; ") unless result.success?

      result.value.accept(self)
      @tests.reject! { |_, test| test.delete("visibility") != :public }
    end

    def visit_class_node(node)
      within_scope(node.constant_path.slice) { visit(node.body) }
    end

    def visit_module_node(node)
      within_scope(node.constant_path.slice) { visit(node.body) }
    end

    def visit_def_node(node)
      add(node.name.to_s, node) if node.name.to_s.start_with?("test_") && !node.receiver
    end

    def visit_call_node(node)
      if [:public, :private, :protected].include?(node.name) && !node.receiver
        if node.arguments
          node.arguments.arguments.each do |argument|
            if argument.is_a?(Prism::DefNode)
              previous = @visibility[-1]
              @visibility[-1] = node.name
              visit(argument)
              @visibility[-1] = previous
            elsif argument.is_a?(Prism::SymbolNode)
              test = @tests["#{@scope.join("::")}##{argument.unescaped}"]
              test["visibility"] = node.name if test
            end
          end
        else
          @visibility[-1] = node.name
        end
        return
      end
      if node.name == :test && node.block
        argument = node.arguments&.arguments&.first
        if argument.is_a?(Prism::StringNode) && !node.receiver
          add("test_#{argument.unescaped.gsub(/\s+/, "_")}", node)
        else
          @unsupported << "dynamic test definition at line #{node.location.start_line}"
        end
      elsif [:it, :specify, :define_method].include?(node.name)
        @unsupported << "#{node.name} definition at line #{node.location.start_line}"
      end
      super
    end

    private

    def within_scope(name)
      @scope.push(name)
      @visibility.push(:public)
      yield
    ensure
      @scope.pop
      @visibility.pop
    end

    def add(name, node)
      key = "#{@scope.join("::")}##{name}"
      if @tests.key?(key)
        @unsupported << "duplicate test identity #{key}"
      end
      @tests[key] = {
        "name" => name,
        "line" => node.location.start_line,
        "end_line" => node.location.end_line,
        "visibility" => @visibility.last,
        "source" => node.slice
      }
    end
  end

  class Check
    def initialize(base:, output:, head: "HEAD", timeout: 90, install: false, root: ROOT)
      @root = root
      @base = git("rev-parse", "--verify", "#{base}^{commit}").strip
      @head = git("rev-parse", "--verify", "#{head}^{commit}").strip
      @base = git("merge-base", @base, @head).strip
      @output = File.expand_path(output)
      @timeout = timeout
      @install = install
      bundle_path = Bundler.settings[:path]
      @bundle_path = File.expand_path(bundle_path, Bundler.root) if bundle_path
      @report = {
        "checker_digest" => CHECKER_DIGEST,
        "base" => @base, "head" => @head, "tests" => [], "notes" => [], "files" => [], "changed_files" => []
      }
    end

    def run
      FileUtils.mkdir_p(@output)
      FileUtils.rm_f([File.join(@output, "results.json"), File.join(@output, "summary.md")])
      selected = select_tests
      @report["notes"] << "No added or modified Minitest tests found." if selected.empty?
      unless selected.empty?
        FileUtils.mkdir_p(File.join(@root, "tmp"))
        Dir.mktmpdir("regression-check-", File.join(@root, "tmp")) do |scratch|
          head = File.join(scratch, "head")
          base = File.join(scratch, "base")
          snapshot(@head, head)
          install_dependencies(head) if @install
          FileUtils.cp_r(head, base)
          restore_implementation(base, scratch)
          selected.each_with_index do |(file, tests), index|
            head_result = run_file(head, file, tests, "head", index)
            base_result = run_file(base, file, tests, "base", index)
            compare(file, tests, head_result, base_result)
          end
        end
      end
      write_report
      @report
    end

    private

    def git(*args)
      output, status = Open3.capture2e("git", "-C", @root, *args)
      raise Error, "git #{args.first} failed: #{output}" unless status.success?

      output
    end

    def select_tests
      selected = {}
      changes = git("diff", "--name-status", "-z", "--find-renames", @base, @head).split("\0")
      until changes.empty?
        status = changes.shift
        old_path = changes.shift
        path = status.start_with?("R", "C") ? changes.shift : old_path
        @report["changed_files"] << {"status" => status, "path" => path, "old_path" => old_path}
        next if status == "D"
        next unless path.end_with?("_test.rb", "_spec.rb")

        before = (status == "A") ? "" : git("show", "#{@base}:#{old_path}")
        after = git("show", "#{@head}:#{path}")
        next if before == after

        if !path.start_with?("test/", "test_engine/") || path.end_with?("_spec.rb")
          @report["notes"] << "Unsupported test file: #{path}"
          next
        end
        old = TestDefinitions.new(before)
        current = TestDefinitions.new(after)
        current.unsupported.each { |reason| @report["notes"] << "#{path}: #{reason}" }
        tests = current.tests.filter_map do |key, test|
          previous = old.tests[key]
          next if previous && previous["source"] == test["source"]

          test.except("source").merge(
            "definition" => key, "change" => previous ? "modified" : "added"
          )
        end
        @report["files"] << {"path" => path, "selected" => tests.length}
        selected[path] = tests unless tests.empty?
      end
      selected
    end

    def snapshot(revision, destination)
      FileUtils.mkdir_p(destination)
      archive = File.join(File.dirname(destination), "#{File.basename(destination)}.tar")
      git("archive", "--format=tar", "--output=#{archive}", revision)
      _, status = Open3.capture2e("tar", "-xf", archive, "-C", destination)
      raise Error, "Could not extract #{revision}" unless status.success?
    end

    def specification(directory)
      @specifications ||= {}
      @specifications[directory] ||= begin
        output, status = Bundler.with_unbundled_env do
          Open3.capture2e(
            RbConfig.ruby, "-rjson", "-e", <<~RUBY, chdir: directory
              spec = Gem::Specification.load("view_component.gemspec")
              abort "Cannot load gemspec" unless spec
              bundler = spec.dependencies.find { |dependency| dependency.name == "bundler" }
              puts JSON.generate(files: spec.files, bundler: bundler&.requirement&.as_list)
            RUBY
          )
        end
        raise Error, "Cannot load gemspec: #{output}" unless status.success?

        JSON.parse(output)
      end
    end

    def packaged_files(directory)
      specification(directory).fetch("files").select do |path|
        raise Error, "Unsafe packaged path: #{path}" if Pathname.new(path).absolute? || path.split("/").include?("..")

        File.file?(File.join(directory, path)) &&
          path.start_with?("app/", "lib/") && !path.start_with?("app/views/test_mailer/")
      end
    end

    def restore_implementation(directory, scratch)
      original = File.join(scratch, "original")
      snapshot(@base, original)
      head_files = packaged_files(directory)
      base_files = packaged_files(original)
      (head_files | base_files).each do |path|
        source = File.join(original, path)
        destination = File.join(directory, path)
        if File.file?(source)
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.copy_file(source, destination)
        elsif File.file?(destination)
          FileUtils.rm(destination)
        end
      end
      @report["implementation_files"] = (head_files | base_files).sort
      if git("diff", "--name-only", @base, @head, "--", "Gemfile", "view_component.gemspec", "gemfiles").length.positive?
        @report["notes"] << "Dependencies changed. Both runs use the PR's dependencies; this does not compare dependency changes."
      end
    end

    def run_file(directory, file, tests, version, index)
      prefix = File.join(@output, "#{index}-#{version}")
      input = "#{prefix}-selection.json"
      result = "#{prefix}.json"
      log = "#{prefix}.log"
      File.write(input, JSON.pretty_generate(tests))
      FileUtils.rm_f([result, "#{result}.tmp"])
      env = test_environment(directory)
      status, timed_out = run_process(
        env, [*bundle_command(directory), "exec", RbConfig.ruby, RUNNER, file, input, result], directory, log, @timeout
      )
      data = File.exist?(result) ? JSON.parse(File.read(result)) : {"tests" => []}
      data.merge("timeout" => timed_out, "exit_code" => status&.exitstatus, "log" => File.basename(log))
    end

    def test_environment(directory)
      gemfile = ENV.fetch("BUNDLE_GEMFILE", "gemfiles/rails_8.1.gemfile")
      if Pathname.new(gemfile).absolute?
        gemfile = Pathname.new(gemfile).relative_path_from(Pathname.new(@root)).to_s
      end
      environment = {
        "BUNDLE_GEMFILE" => File.expand_path(gemfile, directory),
        "RAILS_ENV" => "test",
        "MEASURE_COVERAGE" => nil,
        "LOADED_GEMS_DIR" => nil
      }
      environment["BUNDLE_PATH"] = @bundle_path if @bundle_path
      environment
    end

    def install_dependencies(directory)
      log = File.join(@output, "bundle.log")
      env = test_environment(directory)
      command = bundle_command(directory)
      status, _ = run_process(env, [*command, "check"], directory, log, 30)
      return if status&.success?

      version = bundler_version(directory)
      requirements = version ? [version] : specification(directory)["bundler"]
      if requirements && Gem::Specification.find_all_by_name("bundler", Gem::Requirement.new(requirements)).empty?
        status, _ = run_process(env, ["gem", "install", "bundler", "--version", requirements.join(", "), "--no-document"], directory, log, 180)
        raise Error, "Bundler #{requirements.join(", ")} installation failed; see #{log}" unless status&.success?
      end
      command = bundle_command(directory)
      status, timed_out = run_process(env, [*command, "install", "--quiet"], directory, log, 300)
      raise Error, "Dependency installation #{timed_out ? "timed out" : "failed"}; see #{log}" unless status&.success?
    end

    def bundler_version(directory)
      lockfile = "#{test_environment(directory).fetch("BUNDLE_GEMFILE")}.lock"
      locked = File.read(lockfile)[/^BUNDLED WITH\n\s+(\d+\.\d+\.\d+)\s*$/, 1] if File.file?(lockfile)
      return locked if locked

      requirement = specification(directory)["bundler"]
      if requirement
        Gem::Specification.find_all_by_name("bundler", Gem::Requirement.new(requirement)).max_by(&:version)&.version&.to_s
      end
    end

    def bundle_command(directory)
      version = bundler_version(directory)
      version ? ["bundle", "_#{version}_"] : ["bundle"]
    end

    def run_process(env, command, directory, log, timeout)
      status = nil
      timed_out = false
      File.open(log, "w") do |io|
        pid = Bundler.with_unbundled_env do
          Process.spawn(env, *command, chdir: directory, out: io, err: io, pgroup: true)
        end
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          waited = Process.waitpid2(pid, Process::WNOHANG)
          if waited
            status = waited.last
            break
          end
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            timed_out = true
            Process.kill("KILL", -pid)
            Process.waitpid(pid)
            break
          end
          sleep 0.05
        end
      end
      [status, timed_out]
    end

    def compare(file, tests, head, base)
      head_tests = head.fetch("tests").to_h { |test| [test.fetch("id"), test] }
      base_tests = base.fetch("tests").to_h { |test| [test.fetch("id"), test] }
      tests.each do |definition|
        matches = head_tests.values.select { |test| test["definition"] == definition["definition"] }
        if matches.empty?
          @report["tests"] << definition.merge("file" => file, "status" => "inconclusive",
            "reason" => head["timeout"] ? "Head timed out" : "Test did not run on head", "head_log" => head["log"])
        end
        matches.each do |head_test|
          base_test = base_tests[head_test["id"]]
          status, reason = classify(head_test, base_test, head, base)
          @report["tests"] << definition.merge(
            "file" => file, "id" => head_test["id"], "status" => status, "reason" => reason,
            "head" => head_test, "base" => base_test, "head_log" => head["log"], "base_log" => base["log"]
          )
        end
      end
    end

    def classify(head_test, base_test, head, base)
      return ["inconclusive", "Head timed out"] if head["timeout"]
      return ["inconclusive", "Head test run did not complete"] unless head["completed"]
      return ["inconclusive", "Head process did not complete normally"] unless [0, 1].include?(head["exit_code"])
      if head["exit_code"] != 0 && head["tests"].none? { |test| ["failed", "error"].include?(test["status"]) }
        return ["inconclusive", "Head failed outside the selected tests"]
      end
      return ["head_failed", "Test does not pass on head"] if ["failed", "error"].include?(head_test["status"])
      return ["inconclusive", "Test skipped or made no assertions on head"] if head_test["status"] != "passed" || head_test["assertions"].zero?
      return ["inconclusive", "Base timed out"] if base["timeout"]
      return ["inconclusive", "Base test run did not complete"] unless base["completed"]
      return ["inconclusive", "Base process did not complete normally"] unless [0, 1].include?(base["exit_code"])
      if base["exit_code"] != 0 && base["tests"].none? { |test| ["failed", "error"].include?(test["status"]) }
        return ["inconclusive", "Base failed outside the selected tests"]
      end
      return ["inconclusive", "Test did not run on base"] unless base_test

      case base_test["status"]
      when "failed" then ["demonstrated", "Passes on head; assertion fails without the implementation"]
      when "passed" then ["not_demonstrated", "Also passes without the implementation"]
      else ["inconclusive", "Base #{base_test["status"]}: inspect the recorded exception"]
      end
    end

    def write_report
      @report["counts"] = @report["tests"].group_by { |test| test["status"] }.transform_values(&:length)
      File.write(File.join(@output, "results.json"), JSON.pretty_generate(@report) + "\n")
      lines = [
        "## Regression check", "",
        "Base: `#{@base}`; head: `#{@head}`.", "",
        "| Test | Change | Result | Detail |",
        "| --- | --- | --- | --- |"
      ]
      @report["tests"].each do |test|
        values = [test["id"] || "#{test["file"]}:#{test["line"]}", test["change"], test["status"], test["reason"]]
        lines << "| #{values.map { |value| RegressionCheck.table_cell(value) }.join(" | ")} |"
      end
      lines << "" << "No added or modified tests were selected." if @report["tests"].empty?
      @report["notes"].each { |note| lines << "" << "- #{note}" }
      lines << "" << "Assertion failures demonstrate a difference, not necessarily a bug. Errors, skips, timeouts, and missing results are inconclusive."
      summary = lines.join("\n") + "\n"
      File.write(File.join(@output, "summary.md"), summary)
      puts summary
    end
  end

  def self.table_cell(value)
    value.to_s.gsub(/[\\|]/) { |character| "\\#{character}" }.tr("\n", " ")
  end

  def self.main(argv)
    options = {head: "HEAD", output: "tmp/regression-check", timeout: 90}
    strict = false
    OptionParser.new do |parser|
      parser.banner = "Usage: ruby script/regression_check.rb --base REV [options]"
      parser.on("--base REV") { |value| options[:base] = value }
      parser.on("--head REV") { |value| options[:head] = value }
      parser.on("--output DIR") { |value| options[:output] = value }
      parser.on("--timeout SECONDS", Integer) { |value| options[:timeout] = value }
      parser.on("--install") { options[:install] = true }
      parser.on("--strict") { strict = true }
    end.parse!(argv)
    raise Error, "--base is required" unless options[:base]
    raise Error, "--timeout must be positive" unless options[:timeout].positive?

    exit_code(Check.new(**options).run, strict: strict)
  rescue Error, OptionParser::ParseError => error
    warn error.message
    1
  end

  def self.exit_code(report, strict:)
    return 0 unless strict

    (report["tests"].any? && report["tests"].all? { |test| test["status"] == "demonstrated" } && report["notes"].empty?) ? 0 : 1
  end
end

exit RegressionCheck.main(ARGV) if $PROGRAM_NAME == __FILE__
