# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shared/view_components/version"

Gem::Specification.new do |spec|
  spec.name          = "shared_view_components"
  spec.version       = Shared::ViewComponents::VERSION::STRING
  spec.authors       = ["GitHub Open Source"]
  spec.email         = ["opensource+primer_view_components@github.com"]
  spec.summary       = "Bundled ViewComponents Gem Example"
  spec.homepage      = "https://github.com/github/view_components/shared_view_components"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency             "actionpack", ">= 5.0.0"
  spec.add_dependency             "actionview", ">= 5.0.0"
  spec.add_dependency             "activesupport", ">= 5.0.0"
  spec.add_dependency             "view_component", [">= 2.0.0", "< 3.0"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "capybara", "~> 3"
  spec.add_development_dependency "rails", ">= 5.0.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
