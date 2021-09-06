# frozen_string_literal: true

module ViewComponent
  module SystemTestHelpers
    include TestHelpers
    include Capybara::DSL

    def page
      Capybara.current_session
    end

    def visit_rendered_in_browser(component, **options)
      html = controller.render_to_string("view_components/preview", { layout: "application", locals: {
                                           render_args: {
                                             component: component,
                                             template: "view_components/preview",
                                             hide_preview_source: true
                                           }
                                         } })

      # Write to temporary file to contain fully rendered component
      # within a browser
      file = Tempfile.new(["rendered_#{component.class.name}", ".html"], "tmp/")
      file.write(html)
      file.rewind

      # NOTE - not entirely sure how this would work
      # given that the application may have their own capybara
      # instance running
      filename = file.path.split("/").last

      # Visit the file that contains the HTML
      visit "/view_components_system_test_entrypoint?file=#{filename}"

      # Erase temporary file
      file.unlink
    end
  end
end
