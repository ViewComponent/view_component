# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = "#{ENV['RAILS_VERSION'] || 'main'}"

gem "capybara", "~> 3"
gem "rails", rails_version == "main" ? { git: "https://github.com/rails/rails", ref: "main" } : rails_version

if RUBY_VERSION >= "3.1"
  gem "net-imap", require: false
  gem "net-pop", require: false
  gem "net-smtp", require: false
end
