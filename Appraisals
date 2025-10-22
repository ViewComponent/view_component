# frozen_string_literal: true

appraise "rails-7.1" do
  ruby "~> 3.2.0"

  gem "rails", "~> 7.1.0"

  group :development, :test do
    gem "turbo-rails", "~> 1"
    gem "rspec-rails", "~> 7"
  end
end

appraise "rails-7.2" do
  ruby "~> 3.3.0"

  gem "rails", "~> 7.2.0"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 7"
  end
end

appraise "rails-8.0" do
  ruby "~> 3.4.0"

  gem "rails", "~> 8.0.0"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 8"
  end
end

appraise "rails-8.1" do
  ruby "~> 3.4.0"

  gem "rails", "~> 8.1.0"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 8"
  end
end

appraise "rails-main" do
  gem "rack", git: "https://github.com/rack/rack", ref: "8a4475a9f416a72e5b02bd7817e4a8ed684f29b0"
  gem "rails", github: "rails/rails", branch: "main"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 8"
  end
end
