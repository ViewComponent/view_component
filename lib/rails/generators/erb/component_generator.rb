# frozen_string_literal: true

require "rails/generators/erb"

module Erb
  module Generators
    class ComponentGenerator < Base
      source_root File.expand_path("templates", __dir__)

      class_option :require_content, type: :boolean, default: false

      def copy_view_file
        template "component.html.erb", File.join("app/components", class_path, "#{file_name}_component.html.erb")
      end

      private

      def requires_content?
        options["require_content"]
      end

      def file_name
        @_file_name ||= super.sub(/_component\z/i, "")
      end
    end
  end
end
