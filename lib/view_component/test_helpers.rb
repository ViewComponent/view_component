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

    # @private
    attr_reader :rendered_component

    # Render a component inline. Internally sets `page` to be a `Capybara::Node::Simple`,
    # allowing for Capybara assertions to be used:
    #
    # ```ruby
    # render_inline(MyComponent.new)
    # assert_text("Hello, World!")
    # ```
    #
    # @param component [ViewComponent::Base] The instance of the component to be rendered.
    # @return [Nokogiri::HTML]
    def render_inline(component, **args, &block)
      @rendered_component =
        if Rails.version.to_f >= 6.1
          controller.view_context.render(component, args, &block)
        else
          controller.view_context.render_component(component, &block)
        end

      Nokogiri::HTML.fragment(@rendered_component)
    end

    # @private
    def controller
      @controller ||= build_controller(Base.test_controller.constantize)
    end

    # @private
    def request
      @request ||=
        begin
          request = ActionDispatch::TestRequest.create
          request.session = ActionController::TestSession.new
          request
        end
    end

    # Set the Action Pack request variant for the given block:
    #
    # ```ruby
    # with_variant(:phone) do
    #   render_inline(MyComponent.new)
    # end
    # ```
    #
    # @param variant [Symbol] The variant to be set for the provided block.
    def with_variant(variant)
      old_variants = controller.view_context.lookup_context.variants

      controller.view_context.lookup_context.variants = variant
      yield
    ensure
      controller.view_context.lookup_context.variants = old_variants
    end

    # Set the controller to be used while executing the given block,
    # allowing access to controller-specific methods:
    #
    # ```ruby
    # with_controller_class(UsersController) do
    #   render_inline(MyComponent.new)
    # end
    # ```
    #
    # @param klass [ActionController::Base] The controller to be used.
    def with_controller_class(klass)
      old_controller = defined?(@controller) && @controller

      @controller = build_controller(klass)
      yield
    ensure
      @controller = old_controller
    end

    # Set the URL for the current request (such as when using request-dependent path helpers):
    #
    # ```ruby
    # with_request_url("/users/42") do
    #   render_inline(MyComponent.new)
    # end
    # ```
    #
    # @param path [String] The path to set for the current request.
    def with_request_url(path)
      old_request_path_parameters = request.path_parameters
      old_controller = defined?(@controller) && @controller

      request.path_parameters = Rails.application.routes.recognize_path(path)
      yield
    ensure
      request.path_parameters = old_request_path_parameters
      @controller = old_controller
    end

    # @private
    def build_controller(klass)
      klass.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
    end
  end
end
