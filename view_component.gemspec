# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "view_component/version"

Gem::Specification.new do |spec|
  spec.name = "view_component"
  spec.version = ViewComponent::VERSION::STRING
  spec.author = "ViewComponent Team"

  spec.summary = "A framework for building reusable, testable & encapsulated view components in Ruby on Rails."
  spec.homepage = "https://viewcomponent.org"
  spec.license = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "https://github.com/viewcomponent/view_component"
  spec.metadata["changelog_uri"] = "https://github.com/ViewComponent/view_component/blob/main/docs/CHANGELOG.md"

  spec.files = Dir["LICENSE.txt", "README.md", "app/**/*", "docs/CHANGELOG.md", "lib/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_runtime_dependency "activesupport", [">= 7.1.0", "< 8.1"]
  spec.add_runtime_dependency "concurrent-ruby", "~> 1"
  spec.add_development_dependency "allocation_stats"
  spec.add_development_dependency "appraisal", "~> 2"
  spec.add_development_dependency "benchmark-ips", "~> 2"
  spec.add_development_dependency "better_html"
  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "capybara", "~> 3"
  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "erb_lint"
  spec.add_development_dependency "haml", "~> 6"
  spec.add_development_dependency "jbuilder", "~> 2"
  spec.add_development_dependency "m", "~> 1"
  spec.add_development_dependency "method_source", "~> 1"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency "puma", "~> 6"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "rspec-rails", "~> 7"
  spec.add_development_dependency "rubocop-md", "~> 2"
  spec.add_development_dependency "selenium-webdriver", "~> 4"
  spec.add_development_dependency "simplecov-console", "< 1"
  spec.add_development_dependency "simplecov", "< 1"
  spec.add_development_dependency "slim", "~> 5"
  spec.add_development_dependency "sprockets-rails", "~> 3"
  spec.add_development_dependency "standard", "~> 1"
  spec.add_development_dependency "turbo-rails", "~> 2"
  spec.add_development_dependency "warning"
  spec.add_development_dependency "yard-activesupport-concern", "< 1"
  spec.add_development_dependency "yard", "< 1"

  if RUBY_VERSION >= "3.3"
    spec.add_development_dependency "propshaft", "~> 1"
  end
end
