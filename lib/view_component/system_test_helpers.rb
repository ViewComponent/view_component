# frozen_string_literal: true

module ViewComponent
  module SystemTestHelpers
    include TestHelpers
    include Capybara::DSL

    def page
      Capybara.current_session
    end

    def with_rendered_component_in_browser(component, **options, &block)
      layout = options[:layout] || false

      opts = {
        layout: layout,
        locals: {
          render_args: {
            component: component,
            hide_preview_source: true
          }
        }
      }
      html = controller.render_to_string("view_components/preview", opts)

      # Write to temporary file to contain fully rendered component
      # within a browser
      file = Tempfile.new(["rendered_#{component.class.name}", ".html"], "tmp/")
      file.write(html)
      file.rewind

      filename = file.path.split("/").last
      path = "/system_test_entrypoint?file=#{filename}"

      yield path
    ensure
      file.unlink
    end
  end
end
