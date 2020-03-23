# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "view_component/version"

Gem::Specification.new do |spec|
  spec.name          = "actionview-component"
  spec.version       = ViewComponent::VERSION::STRING
  spec.authors       = ["GitHub Open Source"]
  spec.email         = ["opensource+view_component@github.com"]

  spec.summary       = %q{View components for Rails}
  spec.homepage      = "https://github.com/github/view_component"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_runtime_dependency     "capybara", "~> 3"
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "= 5.1.0"
  spec.add_development_dependency "haml", "~> 5"
  spec.add_development_dependency "slim", "~> 4.0"
  spec.add_development_dependency "better_html", "~> 1"
  spec.add_development_dependency "rubocop", "= 0.74"
  spec.add_development_dependency "rubocop-github", "~> 0.13.0"

  spec.post_install_message = "WARNING: actionview-component has been renamed to view_component, and will no longer be published in this namespace. Please update your Gemfile to use view_component."
end
