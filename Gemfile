# frozen_string_literal: true

source "https://rubygems.org"
gemspec

rails_version = (ENV["RAILS_VERSION"] || "~> 8").to_s
gem "rails", (rails_version == "main") ? {git: "https://github.com/rails/rails", ref: "main"} : rails_version

ruby_version = (ENV["RUBY_VERSION"] || "~> 3.4").to_s
ruby ruby_version

# Pin cgi to a version that still defines `@@accept_charset`; later versions
# crash on Ruby 3.5 when called from globalid.
gem "cgi", "< 0.5"

group :development, :test do
  gem "appraisal-run", "~> 1.0"
end
