# frozen_string_literal: true

require "rails/engine"

module Shared
  module ViewComponents
    class Engine < ::Rails::Engine
      isolate_namespace Shared::ViewComponents
      config.autoload_once_paths = %w[
        %{root}/app/components
      ]
    end
  end
end