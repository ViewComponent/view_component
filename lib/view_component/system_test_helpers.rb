# frozen_string_literal: true

module ViewComponent
  module SystemTestHelpers
    include TestHelpers
    include Capybara::DSL

    def page
      Capybara.current_session
    end

    def visit_rendered_component_in_browser(component, **options)
      layout = options[:layout] || false

      opts = {
        layout: layout,
        locals: {
          render_args: {
            component: component,
            template: "view_components/preview",
            hide_preview_source: true
          }
        }
      }
      html = controller.render_to_string("view_components/preview", opts)

      # Add 'tmp/' directory if it doesn't exist to store the rendered component html
      Dir.mkdir("tmp/view_component_integrations") unless Dir.exist?("tmp/view_component_integrations/")

      # Write to temporary file to contain fully rendered component
      # within a browser
      file = Tempfile.new(["rendered_#{component.class.name}", ".html"], "tmp/view_component_integrations")
      file.write(html)
      file.rewind

      filename = file.path.split("/").last

      # Visit the file that contains the HTML
      visit "/view_components_system_test_entrypoint?file=#{filename}"

      # Erase temporary file
      file.unlink
    end
  end
end
