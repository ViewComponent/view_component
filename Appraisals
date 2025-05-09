# frozen_string_literal: true

appraise "rails-6.1" do
  gem "rails", "~> 6.1"
  gem "tailwindcss-rails", "~> 2.0"
  gem "sprockets-rails", "~> 3.4.2"
  gem "concurrent-ruby", "1.3.4"

  # Required for Ruby 3.1.0
  gem "net-smtp", require: false
  gem "net-imap", require: false
  gem "net-pop", require: false
  gem "turbo-rails", "~> 1"
end

appraise "rails-7.0" do
  gem "rails", "~> 7.0"
  gem "tailwindcss-rails", "~> 2.0"
  gem "turbo-rails", "~> 1"
  gem "sprockets-rails", "~> 3.4.2"
end

appraise "rails-7.1" do
  gem "rails", "~> 7.1"
  gem "tailwindcss-rails", "~> 2.0"
  gem "turbo-rails", "~> 1"
  gem "sprockets-rails", "~> 3.4.2"
end

appraise "rails-7.2" do
  gem "rails", "~> 7.2"
  gem "tailwindcss-rails", "~> 2.0"
  gem "sprockets-rails", "~> 3.4.2"
end

appraise "rails-8.0" do
  gem "rails", "~> 8.0"
  gem "tailwindcss-rails", "~> 2.0"
  gem "propshaft", "~> 1.1.0"
end

appraise "rails-main" do
  gem "rails", github: "rails/rails", branch: "main"
  gem "tailwindcss-rails", "~> 2.0"
  gem "turbo-rails", "~> 1"
end
