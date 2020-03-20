# frozen_string_literal: true

require "rails/generators/erb"

module Erb
  module Generators
    class ComponentGenerator < Base
      source_root File.expand_path("templates", __dir__)

      def copy_view_file
        template "component.html.erb", File.join("app/components", class_path, "#{file_name}_component.html.erb")
      end

      private

      def file_name
        @_file_name ||= super.sub(/_component\z/i, "")
      end
    end
  end
end
