source "https://rubygems.org"
gemspec

rails_version = "#{ENV['RAILS_VERSION'] || '5.2.3'}"

if rails_version == "master"
  gem "rails", github: 'rails/rails'
else
  gem "rails", rails_version
end
