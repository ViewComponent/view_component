# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "yard"
require "yard/mattr_accessor_handler"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Runs benchmarks against components"
task :benchmark do
  ruby "./performance/benchmark.rb"
end

desc "Runs benchmarks against component content area/ slot implementations"
task :slotable_benchmark do
  ruby "./performance/slotable_benchmark.rb"
end

task :translatable_benchmark do
  ruby "./performance/translatable_benchmark.rb"
end

namespace :coverage do
  task :report do
    require "simplecov"
    require "simplecov-console"

    SimpleCov.minimum_coverage 100

    SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"], "rails" do
      formatter SimpleCov::Formatter::Console
    end
  end
end

namespace :docs do
  # Build api.md documentation page from YARD comments.
  task :build do
    YARD::Rake::YardocTask.new
    puts "Building YARD documentation."

    Rake::Task["yard"].execute

    puts "Converting YARD documentation to Markdown files."

    registry = YARD::RegistryStore.new
    registry.load!(".yardoc")

    meths =
      registry.
      get("ViewComponent::Base").
      meths.
      select do |method|
        !method.tag(:private) &&
          method.path.include?("ViewComponent::Base") &&
          method.visibility == :public
      end.sort_by { |method| method[:name] }

    instance_methods_to_document = meths.select { |method| method.scope != :class }
    class_methods_to_document = meths.select { |method| method.scope == :class }

    File.open("docs/api.md", "w") do |f|
      f.puts("---")
      f.puts("layout: default")
      f.puts("title: API")
      f.puts("---")
      f.puts
      f.puts("<!-- Warning: AUTO-GENERATED file, do not edit. Add code comments to your Ruby instead <3 -->")
      f.puts
      f.puts("# API")

      f.puts
      f.puts("## Class methods")

      class_methods_to_document.each do |method|
        suffix =
          if method.tag(:deprecated)
            " (Deprecated)"
          end

        types =
          if method.tag(:return)&.types
            " → [#{method.tag(:return).types.join(',')}]"
          end

        f.puts
        f.puts("### #{method.sep}#{method.signature.gsub('def ', '')}#{types}#{suffix}")
        f.puts
        f.puts(method.docstring)

        if method.tag(:deprecated)
          f.puts
          f.puts("_#{method.tag(:deprecated).text}_")
        end
      end

      f.puts
      f.puts("## Instance methods")

      instance_methods_to_document.each do |method|
        suffix =
          if method.tag(:deprecated)
            " (Deprecated)"
          end

        types =
          if method.tag(:return)&.types
            " → [#{method.tag(:return).types.join(',')}]"
          end

        f.puts
        f.puts("### #{method.sep}#{method.signature.gsub('def ', '')}#{types}#{suffix}")
        f.puts
        f.puts(method.docstring)

        if method.tag(:deprecated)
          f.puts
          f.puts("_#{method.tag(:deprecated).text}_")
        end
      end

      f.puts
      f.puts("## Configuration")

      registry.
        get("ViewComponent::Base").
        meths.
        select { |method| method[:mattr_accessor] }.
        sort_by { |method| method[:name] }.
        each do |method|
        suffix =
          if method.tag(:deprecated)
            " (Deprecated)"
          end

        f.puts
        f.puts("### #{method.sep}#{method.name}#{suffix}")

        if method.docstring.length > 0
          f.puts
          f.puts(method.docstring)
        end

        if method.tag(:deprecated)
          f.puts
          f.puts("_#{method.tag(:deprecated).text}_")
        end
      end
    end
  end
end

task default: :test
