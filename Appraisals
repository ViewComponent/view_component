# frozen_string_literal: true

appraise "rails-7.1" do
  ruby "~> 3.2"

  gem "rails", "~> 7.1.0"

  group :development, :test do
    gem "turbo-rails", "~> 1"
    gem "rspec-rails", "~> 7"
  end
end

appraise "rails-7.2" do
  ruby "~> 3.3"

  gem "rails", "~> 7.2.0"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 7"
  end
end

appraise "rails-8.0" do
  ruby "~> 3.4"

  gem "rails", "~> 8.0.0"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 8"
  end
end

appraise "rails-8.1" do
  ruby "~> 4.0"

  gem "rails", "~> 8.1.0"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    gem "rspec-rails", "~> 8"
  end
end

appraise "rails-main" do
  ruby "~> 4.0"

  gem "rack", git: "https://github.com/rack/rack", ref: "a9833c8f3bd6b6d1e0ab35de00a1f1a16b5095f5"
  gem "rails", github: "rails/rails", ref: "7a569bc6cbf10cb07023ac63a838fd0a6b39cad4"
  # Ractor support, https://github.com/ruby-i18n/i18n/pull/741
  gem "i18n", github: "Shopify/i18n", ref: "58aa1dcd3e04c34831e1c2ec06c83391559c7c91"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    # Compatibility with frozen default_url_options, unreleased as of 8.0.4
    gem "rspec-rails", github: "rspec/rspec-rails", ref: "4832492d8a1683bab4b74dc218576f64b0ff988c"
  end
end

appraise "rails-main_head" do
  ruby "4.1.0.dev"

  gem "rack", git: "https://github.com/rack/rack", ref: "a9833c8f3bd6b6d1e0ab35de00a1f1a16b5095f5"
  gem "rails", github: "rails/rails", ref: "7a569bc6cbf10cb07023ac63a838fd0a6b39cad4"
  # Ractor support, https://github.com/ruby-i18n/i18n/pull/741
  gem "i18n", github: "Shopify/i18n", ref: "58aa1dcd3e04c34831e1c2ec06c83391559c7c91"

  group :development, :test do
    gem "turbo-rails", "~> 2"
    # Compatibility with frozen default_url_options, unreleased as of 8.0.4
    gem "rspec-rails", github: "rspec/rspec-rails", ref: "4832492d8a1683bab4b74dc218576f64b0ff988c"
  end
end
