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
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = "https://github.com/viewcomponent/view_component"
  spec.metadata["changelog_uri"] = "https://github.com/ViewComponent/view_component/blob/main/docs/CHANGELOG.md"

  spec.files = Dir[
    "LICENSE.txt",
    "README.md",
    "app/**/*",
    "docs/CHANGELOG.md",
    "lib/generators/**/*.rb",
    "lib/generators/**/*.tt",
    "lib/view_component.rb",
    "lib/view_component/**/*"
  ]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  supported_rails_version = [">= 7.1.0", "< 8.2"]
  spec.add_runtime_dependency "activesupport", supported_rails_version
  spec.add_runtime_dependency "actionview", supported_rails_version
  spec.add_runtime_dependency "concurrent-ruby", "~> 1"
end
