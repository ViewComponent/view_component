# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = (ENV["RAILS_VERSION"] || "~> 8.0.1").to_s
gem "rails", (rails_version == "main") ? {git: "https://github.com/rails/rails", ref: "main"} : rails_version

ruby_version = (ENV["RUBY_VERSION"] || "~> 3.4.1").to_s
ruby ruby_version
