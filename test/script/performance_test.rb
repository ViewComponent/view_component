# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require "tmpdir"

class PerformanceTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def test_measures_rendering_cold_digests_boot_and_executor
    Dir.mktmpdir do |directory|
      output = File.join(directory, "performance.json")
      stdout, stderr, status = Open3.capture3(
        {
          "VIEW_COMPONENT_LIB" => File.join(ROOT, "lib"),
          "PASSES" => "1",
          "SAMPLE_SECONDS" => "0.001",
          "BOOT_COMPONENTS" => "2"
        },
        RbConfig.ruby, File.join(ROOT, "performance/measure.rb"), output
      )
      assert status.success?, "#{stdout}\n#{stderr}"

      results = JSON.parse(File.read(output))
      assert_equal %w[component inline_call inline_erb_template slots collection cold_digest boot executor], results["scenarios"].keys
      results["scenarios"].each_value do |scenario|
        assert_equal 1, scenario["ratios"].size
        assert_equal scenario["ratios"].first, scenario["ratio"]
        %w[reference_ms component_ms reference_allocations component_allocations].each do |key|
          assert_operator scenario[key], :>, 0
        end
      end
    end
  end

  def test_comparison_rejects_cold_digest_boot_and_executor_regressions
    Dir.mktmpdir do |directory|
      base = File.join(directory, "base.json")
      head = File.join(directory, "head.json")
      results = {
        "rails" => "8.1",
        "ruby" => RUBY_DESCRIPTION,
        "scenarios" => %w[cold_digest boot executor].to_h do |name|
          [name, {"ratio" => 1.0, "ratios" => [1.0], "component_allocations" => 100}]
        end
      }
      File.write(base, JSON.generate(results))

      %w[cold_digest boot executor].each do |name|
        results["scenarios"].each do |scenario_name, scenario|
          scenario["ratio"] = (scenario_name == name) ? 2.0 : 1.0
          scenario["ratios"] = [scenario["ratio"]]
        end
        File.write(head, JSON.generate(results))

        stdout, stderr, status = Open3.capture3(
          {"THRESHOLD" => "0.05"},
          RbConfig.ruby, File.join(ROOT, "performance/compare.rb"), base, head
        )
        assert_equal 1, status.exitstatus, "#{stdout}\n#{stderr}"
        assert_includes stdout, "Regressed by more than 5.0%: #{name}."
      end
    end
  end
end
