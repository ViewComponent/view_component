# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = (ENV["RAILS_VERSION"] || "~> 8").to_s
gem "rails", (rails_version == "main") ? {git: "https://github.com/rails/rails", ref: "main"} : rails_version

ruby_version = (ENV["RUBY_VERSION"] || "~> 3.4").to_s
ruby ruby_version

group :development, :test do
  gem "allocation_stats", "~> 0.1.5"
  gem "appraisal", "~> 2.4"
  gem "benchmark-ips", "~> 2.13.0"
  gem "better_html"
  gem "bundler", "~> 2"
  gem "capybara", "~> 3"
  gem "cuprite", "~> 0.15"
  gem "debug"
  gem "erb_lint"
  gem "haml", "~> 6"
  gem "jbuilder", "~> 2"
  gem "m", "~> 1"
  gem "minitest", "~> 5.18"
  gem "pry", "~> 0.13"
  gem "puma", "~> 6"
  gem "rake", "~> 13.0"
  gem "rspec-rails", "~> 5"
  gem "rubocop-md", "~> 1"
  gem "selenium-webdriver", "4.9.0"
  gem "sprockets-rails", "~> 3.4.2"
  gem "standard", "~> 1"
  gem "simplecov", "~> 0.22.0"
  gem "simplecov-console", "~> 0.9.1"
  gem "slim", "~> 5.1"
  gem "turbo-rails", "~> 1"
  gem "warning"
  gem "yard", "~> 0.9.34"
  gem "yard-activesupport-concern", "~> 0.0.1"

  if RUBY_VERSION >= "3.1"
    gem "net-imap"
    gem "net-pop"
    gem "net-smtp"
  end

  if RUBY_VERSION >= "3.3"
    gem "base64"
    gem "bigdecimal"
    gem "drb"
    gem "mutex_m"
    gem "propshaft", "~> 1.1.0"
  end
end