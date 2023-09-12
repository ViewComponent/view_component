# frozen_string_literal: true

module ViewComponent
  module TestHelpers
    begin
      require "capybara/minitest"

      include Capybara::Minitest::Assertions

      def page
        @page ||= Capybara::Node::Simple.new(rendered_content)
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
          "WARNING in `ViewComponent::TestHelpers`: Add `capybara` " \
          "to Gemfile to use Capybara assertions."
        )
      end

      # :nocov:
    end

    # Returns the result of a render_inline call.
    #
    # @return [ActionView::OutputBuffer]
    attr_reader :rendered_content

    # Render a component inline. Internally sets `page` to be a `Capybara::Node::Simple`,
    # allowing for Capybara assertions to be used:
    #
    # ```ruby
    # render_inline(MyComponent.new)
    # assert_text("Hello, World!")
    # ```
    #
    # @param component [ViewComponent::Base, ViewComponent::Collection] The instance of the component to be rendered.
    # @return [Nokogiri::HTML]
    def render_inline(component, **args, &block)
      @page = nil
      @rendered_content =
        if Rails.version.to_f >= 6.1
          vc_test_controller.view_context.render(component, args, &block)
        else
          vc_test_controller.view_context.render_component(component, &block)
        end

      Nokogiri::HTML.fragment(@rendered_content)
    end

    # Render a preview inline. Internally sets `page` to be a `Capybara::Node::Simple`,
    # allowing for Capybara assertions to be used:
    #
    # ```ruby
    # render_preview(:default)
    # assert_text("Hello, World!")
    # ```
    #
    # Note: `#rendered_preview` expects a preview to be defined with the same class
    # name as the calling test, but with `Test` replaced with `Preview`:
    #
    # MyComponentTest -> MyComponentPreview etc.
    #
    # In RSpec, `Preview` is appended to `described_class`.
    #
    # @param name [String] The name of the preview to be rendered.
    # @param from [ViewComponent::Preview] The class of the preview to be rendered.
    # @param params [Hash] Parameters to be passed to the preview.
    # @return [Nokogiri::HTML]
    def render_preview(name, from: __vc_test_helpers_preview_class, params: {})
      previews_controller = __vc_test_helpers_build_controller(Rails.application.config.view_component.preview_controller.constantize)

      # From what I can tell, it's not possible to overwrite all request parameters
      # at once, so we set them individually here.
      params.each do |k, v|
        previews_controller.request.params[k] = v
      end

      previews_controller.request.params[:path] = "#{from.preview_name}/#{name}"
      previews_controller.set_response!(ActionDispatch::Response.new)
      result = previews_controller.previews

      @rendered_content = result

      Nokogiri::HTML.fragment(@rendered_content)
    end

    # Execute the given block in the view context (using `instance_exec`).
    # Internally sets `page` to be a `Capybara::Node::Simple`, allowing for
    # Capybara assertions to be used. All arguments are forwarded to the block.
    #
    # ```ruby
    # render_in_view_context(arg1, arg2: nil) do |arg1, arg2:|
    #   render(MyComponent.new(arg1, arg2))
    # end
    #
    # assert_text("Hello, World!")
    # ```
    def render_in_view_context(*args, &block)
      @page = nil
      @rendered_content = vc_test_controller.view_context.instance_exec(*args, &block)
      Nokogiri::HTML.fragment(@rendered_content)
    end
    ruby2_keywords(:render_in_view_context) if respond_to?(:ruby2_keywords, true)

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
      old_variants = vc_test_controller.view_context.lookup_context.variants

      vc_test_controller.view_context.lookup_context.variants = variant
      yield
    ensure
      vc_test_controller.view_context.lookup_context.variants = old_variants
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
      old_controller = defined?(@vc_test_controller) && @vc_test_controller

      @vc_test_controller = __vc_test_helpers_build_controller(klass)
      yield
    ensure
      @vc_test_controller = old_controller
    end

    # Set the URL of the current request (such as when using request-dependent path helpers):
    #
    # ```ruby
    # with_request_url("/users/42") do
    #   render_inline(MyComponent.new)
    # end
    # ```
    #
    # To use a specific host, pass the host param:
    #
    # ```ruby
    # with_request_url("/users/42", host: "app.example.com") do
    #   render_inline(MyComponent.new)
    # end
    # ```
    #
    # @param path [String] The path to set for the current request.
    # @param host [String] The host to set for the current request.
    def with_request_url(path, host: nil)
      old_request_host = vc_test_request.host
      old_request_path_info = vc_test_request.path_info
      old_request_path_parameters = vc_test_request.path_parameters
      old_request_query_parameters = vc_test_request.query_parameters
      old_request_query_string = vc_test_request.query_string
      old_controller = defined?(@vc_test_controller) && @vc_test_controller

      path, query = path.split("?", 2)
      vc_test_request.host = host if host
      vc_test_request.path_info = path
      vc_test_request.path_parameters = Rails.application.routes.recognize_path_with_request(vc_test_request, path, {})
      vc_test_request.set_header("action_dispatch.request.query_parameters",
        Rack::Utils.parse_nested_query(query).with_indifferent_access)
      vc_test_request.set_header(Rack::QUERY_STRING, query)
      yield
    ensure
      vc_test_request.host = old_request_host
      vc_test_request.path_info = old_request_path_info
      vc_test_request.path_parameters = old_request_path_parameters
      vc_test_request.set_header("action_dispatch.request.query_parameters", old_request_query_parameters)
      vc_test_request.set_header(Rack::QUERY_STRING, old_request_query_string)
      @vc_test_controller = old_controller
    end

    # Access the controller used by `render_inline`:
    #
    # ```ruby
    # test "logged out user sees login link" do
    #   vc_test_controller.expects(:logged_in?).at_least_once.returns(false)
    #   render_inline(LoginComponent.new)
    #   assert_selector("[aria-label='You must be signed in']")
    # end
    # ```
    #
    # @return [ActionController::Base]
    def vc_test_controller
      @vc_test_controller ||= __vc_test_helpers_build_controller(Base.test_controller.constantize)
    end

    # Access the request used by `render_inline`:
    #
    # ```ruby
    # test "component does not render in Firefox" do
    #   request.env["HTTP_USER_AGENT"] = "Mozilla/5.0"
    #   render_inline(NoFirefoxComponent.new)
    #   refute_component_rendered
    # end
    # ```
    #
    # @return [ActionDispatch::TestRequest]
    def vc_test_request
      @vc_test_request ||=
        begin
          out = ActionDispatch::TestRequest.create
          out.session = ActionController::TestSession.new
          out
        end
    end

    # Note: We prefix private methods here to prevent collisions in consumer's tests.
    private

    def __vc_test_helpers_build_controller(klass)
      klass.new.tap { |c| c.request = vc_test_request }.extend(Rails.application.routes.url_helpers)
    end

    def __vc_test_helpers_preview_class
      result = if respond_to?(:described_class)
        raise "`render_preview` expected a described_class, but it is nil." if described_class.nil?

        "#{described_class}Preview"
      else
        self.class.name.gsub("Test", "Preview")
      end
      result = result.constantize
    rescue NameError
      raise NameError, "`render_preview` expected to find #{result}, but it does not exist."
    end
  end
end
