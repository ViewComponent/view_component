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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["source_code_uri"] = "https://github.com/viewcomponent/view_component"
    spec.metadata["changelog_uri"] = "https://github.com/ViewComponent/view_component/blob/main/docs/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["LICENSE.txt", "README.md", "app/**/*", "docs/CHANGELOG.md", "lib/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_runtime_dependency "activesupport", [">= 5.2.0", "< 8.0"]
  spec.add_runtime_dependency "method_source", "~> 1.0"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_development_dependency "appraisal", "~> 2.4"
  spec.add_development_dependency "benchmark-ips", "~> 2.8.2"
  spec.add_development_dependency "better_html", "~> 1"
  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "erb_lint", "~> 0.0.37"
  spec.add_development_dependency "haml", "~> 5"
  spec.add_development_dependency "jbuilder", "~> 2"
  spec.add_development_dependency "m", "~> 1"
  spec.add_development_dependency "minitest", "= 5.6.0"
  spec.add_development_dependency "pry", "~> 0.13"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1"
  spec.add_development_dependency "simplecov", "~> 0.18.0"
  spec.add_development_dependency "simplecov-console", "~> 0.7.2"
  spec.add_development_dependency "slim", "~> 4.0"
  spec.add_development_dependency "sprockets-rails", "~> 3.2.2"
  spec.add_development_dependency "yard", "~> 0.9.25"
  spec.add_development_dependency "yard-activesupport-concern", "~> 0.0.1"
end
