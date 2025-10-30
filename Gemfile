# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = (ENV["RAILS_VERSION"] || "~> 8").to_s

gem "rails", (rails_version == "main") ? {git: "https://github.com/rails/rails", ref: "main"} : rails_version

ruby_version = (ENV["RUBY_VERSION"] || "~> 3.4").to_s
ruby ruby_version

group :development, :test do
  gem "allocation_stats"
  gem "appraisal", "~> 2"
  gem "appraisal-run", "~> 1.1"
  gem "benchmark-ips", "~> 2"
  gem "better_html"
  gem "bundler", "~> 2"
  gem "capybara", "~> 3"
  gem "cuprite"
  gem "dry-initializer", require: true
  gem "erb_lint"
  gem "haml", "~> 6"
  gem "jbuilder", "~> 2"
  gem "m", "~> 1"
  gem "method_source", "~> 1"
  gem "minitest", "~> 5"
  gem "propshaft", "~> 1"
  gem "puma", ">= 6"
  gem "rake", "~> 13"
  gem "rails-dom-testing", "~> 2.3.0"
  gem "redis"
  gem "rspec-rails"
  gem "rubocop-md", "~> 2"
  gem "selenium-webdriver", "~> 4"
  gem "simplecov-console", "< 1"
  gem "simplecov", "< 1"
  gem "slim", "~> 5"
  gem "sprockets-rails", "~> 3"
  gem "standard", "~> 1"
  gem "tailwindcss-rails", "~> 4"
  gem "turbo-rails"
  gem "warning"
  gem "yard-activesupport-concern", "< 1"
  gem "yard", "< 1"
end
