# frozen_string_literal: true

require "rails/generators/erb/component_generator"

module Tailwindcss
  module Generators
    class ComponentGenerator < Erb::Generators::ComponentGenerator
      source_root File.expand_path("templates", __dir__)
    end
  end
end
