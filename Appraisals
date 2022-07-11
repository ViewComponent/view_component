# frozen_string_literal: true

if RUBY_VERSION < "3.0.0"
  appraise "rails-5.2" do
    gem "rails", "~> 5.2.0"
    gem "rspec-rails", "~> 5.1"
  end
else
  puts "WARNING: Skipping Rails 5.2, as it is not compatible with Ruby >= 3.0.0"
end

appraise "rails-6.0" do
  gem "rails", "~> 6.0.0"
  gem "rspec-rails", "~> 5.1"
  gem "tailwindcss-rails", "~> 2.0"
end

appraise "rails-6.1" do
  gem "rails", "~> 6.1.0"
  gem "rspec-rails", "~> 5.1"
  gem "tailwindcss-rails", "~> 2.0"

  # Required for Ruby 3.1.0
  gem "net-smtp", require: false
  gem "net-imap", require: false
  gem "net-pop", require: false
end

appraise "rails-7.0" do
  gem "rails", "~> 7.0.0"
  gem "rspec-rails", "~> 5.1"
  gem "tailwindcss-rails", "~> 2.0"
end

appraise "rails-head" do
  gem "rails", github: "rails/rails", branch: "main"
  gem "rspec-rails", "~> 5.1"
  gem "tailwindcss-rails", "~> 2.0"
end
