# frozen_string_literal: true

if Rails.version.to_f <= 7.2 then Rails.application.config.assets.precompile += %w[admin.css] end
