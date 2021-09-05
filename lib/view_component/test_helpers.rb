# frozen_string_literal: true

module ViewComponent
  module TestHelpers
    begin
      require "capybara/minitest"
      include Capybara::Minitest::Assertions

      def page
        Capybara::Node::Simple.new(@rendered_component)
      end

      def refute_component_rendered
        assert_no_selector("body")
      end
    rescue LoadError
      # We don't have a test case for running an application without capybara installed.
      # It's probably fine to leave this without coverage.
      # :nocov:
      if ENV["DEBUG"]
        warn(
          "WARNING in `ViewComponent::TestHelpers`: You must add `capybara` " \
          "to your Gemfile to use Capybara assertions."
        )
      end

      # :nocov:
    end

    attr_reader :rendered_component

    def render_inline(component, **args, &block)
      @rendered_component =
        if Rails.version.to_f >= 6.1
          controller.view_context.render(component, args, &block)
        else
          controller.view_context.render_component(component, &block)
        end

      Nokogiri::HTML.fragment(@rendered_component)
    end

    def render_in_browser(component, options = {})
      html = controller.render_to_string(component, **options)

      # Write to temporary file to contain fully rendered component
      # within a browser
      file = Tempfile.new([component.class.name, ".html"], "tmp")
      file.write(html)
      file.rewind

      # NOTE - not entirely sure how this would work
      # given that the application may have their own capybara
      # instance running
      session = fetch_capybara_session
      filename = file.path.split("/").last

      # Visit the file that contains the HTML
      session.visit(filename)

      # Erase temporary file
      file.unlink

      return session
    end

    def controller
      @controller ||= build_controller(Base.test_controller.constantize)
    end

    def request
      @request ||=
        begin
          request = ActionDispatch::TestRequest.create
          request.session = ActionController::TestSession.new
          request
        end
    end

    def with_variant(variant)
      old_variants = controller.view_context.lookup_context.variants

      controller.view_context.lookup_context.variants = variant
      yield
    ensure
      controller.view_context.lookup_context.variants = old_variants
    end

    def with_controller_class(klass)
      old_controller = defined?(@controller) && @controller

      @controller = build_controller(klass)
      yield
    ensure
      @controller = old_controller
    end

    def with_request_url(path)
      old_request_path_parameters = request.path_parameters
      old_controller = defined?(@controller) && @controller

      request.path_parameters = Rails.application.routes.recognize_path(path)
      yield
    ensure
      request.path_parameters = old_request_path_parameters
      @controller = old_controller
    end

    def build_controller(klass)
      klass.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
    end

    private

    def fetch_capybara_session
      rack_app = Rack::File.new("./tmp/")
      Capybara::Session.new(Capybara.default_driver, rack_app)
    end
  end
end
