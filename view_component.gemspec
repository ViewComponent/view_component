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

  spec.files = Dir[
    "LICENSE.txt",
    "README.md",
    "app/**/*",
    "docs/CHANGELOG.md",
    "lib/rails/**/*.rb",
    "lib/view_component.rb",
    "lib/view_component/**/*.rb"
  ]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_runtime_dependency "activesupport", [">= 5.2.0", "< 8.1"]
  spec.add_runtime_dependency "method_source", "~> 1.0"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1"
end
