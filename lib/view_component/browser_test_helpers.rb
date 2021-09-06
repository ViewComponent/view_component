# frozen_string_literal: true

module ViewComponent
  module BrowserTestHelpers
    include TestHelpers
    include Capybara::DSL

    def page
      @page ||= fetch_capybara_session
    end

    def render_in_browser(component, **options)
      html = controller.render_to_string(component, **options)

      # Write to temporary file to contain fully rendered component
      # within a browser
      file = Tempfile.new(["rendered_#{component.class.name}", ".html"], "tmp")
      file.write(html)
      file.rewind

      # NOTE - not entirely sure how this would work
      # given that the application may have their own capybara
      # instance running
      filename = file.path.split("/").last

      # Visit the file that contains the HTML
      page.visit(filename)

      # Erase temporary file
      file.unlink
    end

    private

    def fetch_capybara_session
      rack_app = Rack::File.new("./tmp/")
      Capybara::Session.new(Capybara.default_driver, rack_app)
    end
  end
end
