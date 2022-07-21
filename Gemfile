# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = (ENV["RAILS_VERSION"] || "~> 7.0.0").to_s

gem "capybara", "~> 3"

# https://github.com/rails/rails/pull/45614 broke our global output buffer
# code, which we plan to remove anyways. Pinning to before it was merged
# so CI will work.
gem "rails", rails_version == "main" ? {git: "https://github.com/rails/rails", ref: "71c59c69f40cef908d0a97ef4b4c5496778559e5"} : rails_version

gem "rspec-rails", "~> 5"

if RUBY_VERSION >= "3.1"
  gem "net-imap", require: false
  gem "net-pop", require: false
  gem "net-smtp", require: false
end
