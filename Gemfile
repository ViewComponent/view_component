# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = (ENV["RAILS_VERSION"] || "~> 7.0.0").to_s

gem "capybara", "~> 3"
gem "rails", (rails_version == "main") ? {git: "https://github.com/rails/rails", ref: "main"} : rails_version

gem "rspec-rails", "~> 5"

group :test do
  gem "cuprite", "~> 0.15"
  gem "puma", "~> 6"
  gem "warning"

  gem "selenium-webdriver", "4.9.0" # 4.9.1 requires Ruby 3+
end

group :development, :test do
  gem "appraisal", "~> 2.5"
end

if RUBY_VERSION >= "3.1"
  gem "net-imap", require: false
  gem "net-pop", require: false
  gem "net-smtp", require: false
end

gem "debug"
