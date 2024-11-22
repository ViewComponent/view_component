# frozen_string_literal: true

Rails.application.config.assets.precompile += %w[admin.css] if Rails.version.to_f <= 7.2
