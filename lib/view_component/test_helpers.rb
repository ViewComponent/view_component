# frozen_string_literal: true

module ViewComponent
  module TestHelpers
    begin
      require "capybara/minitest"

      include Capybara::Minitest::Assertions

      def page
        @page ||= Capybara::Node::Simple.new(_view_component_private.rendered_content)
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
      _view_component_private.rendered_content =
        if Rails.version.to_f >= 6.1
          _view_component_private.controller.view_context.render(component, args, &block)
        else
          _view_component_private.controller.view_context.render_component(component, &block)
        end

      Nokogiri::HTML.fragment(_view_component_private.rendered_content)
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
    def render_preview(name, from: _view_component_private.preview_class(self), params: {})
      previews_controller = _view_component_private.build_controller(
        Rails.application.config.view_component.preview_controller.constantize
      )

      # From what I can tell, it's not possible to overwrite all request parameters
      # at once, so we set them individually here.
      params.each do |k, v|
        previews_controller.request.params[k] = v
      end

      previews_controller.request.params[:path] = "#{from.preview_name}/#{name}"
      previews_controller.set_response!(ActionDispatch::Response.new)
      result = previews_controller.previews

      _view_component_private.rendered_content = result

      Nokogiri::HTML.fragment(_view_component_private.rendered_content)
    end

    # Execute the given block in the view context (using `instance_exec`).
    # Internally sets `page` to be a `Capybara::Node::Simple`, allowing for
    # Capybara assertions to be used. All arguments are forwarded to the block.
    #
    # ```ruby
    # render_in_view_context(arg1, arg2:) do |arg1, arg2:|
    #   render(MyComponent.new(arg1, arg2))
    # end
    #
    # assert_text("Hello, World!")
    # ```
    def render_in_view_context(*args, &block)
      @page = nil
      _view_component_private.rendered_content = _view_component_private
        .controller
        .view_context.instance_exec(*args, &block)
      Nokogiri::HTML.fragment(_view_component_private.rendered_content)
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
      old_variants = _view_component_private.controller.view_context.lookup_context.variants

      _view_component_private.controller.view_context.lookup_context.variants = variant
      yield
    ensure
      _view_component_private.controller.view_context.lookup_context.variants = old_variants
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
      old_controller = _view_component_private.cached_controller

      _view_component_private.controller = _view_component_private.build_controller(klass)
      yield
    ensure
      _view_component_private.controller = old_controller
    end

    # Set the URL of the current request (such as when using request-dependent path helpers):
    #
    # ```ruby
    # with_request_url("/users/42") do
    #   render_inline(MyComponent.new)
    # end
    # ```
    #
    # @param path [String] The path to set for the current request.
    def with_request_url(path)
      request = _view_component_private.request
      old_request_path_info = request.path_info
      old_request_path_parameters = request.path_parameters
      old_request_query_parameters = request.query_parameters
      old_request_query_string = request.query_string
      old_controller = _view_component_private.cached_controller

      path, query = path.split("?", 2)
      request.path_info = path
      request.path_parameters = Rails.application.routes.recognize_path_with_request(request, path, {})
      request.set_header("action_dispatch.request.query_parameters", Rack::Utils.parse_nested_query(query))
      request.set_header(Rack::QUERY_STRING, query)
      yield
    ensure
      request.path_info = old_request_path_info
      request.path_parameters = old_request_path_parameters
      request.set_header("action_dispatch.request.query_parameters", old_request_query_parameters)
      request.set_header(Rack::QUERY_STRING, old_request_query_string)
      _view_component_private.controller = old_controller
    end

    private

    # All the private API is stored in this object. Keeping everything enclosed
    # inside an object reduces the number of methods that will be added to the
    # class this module is included in. Reducing the API surface reduces the
    # risk of the user of this module to define methods with conflicting names.
    # Making the method name ugly on purpose also reduces the risk of
    # conflicting names. Finally, using an anonymous class also reduces the risk
    # of conflicting names and reduces the API surface.
    def _view_component_private
      @_view_component_private ||= Class.new do
        attr_accessor :rendered_content
        attr_writer :controller

        def controller
          @controller ||= build_controller(Base.test_controller.constantize)
        end

        def cached_controller
          defined?(@controller) && @controller
        end

        def request
          @request ||=
            begin
              request = ActionDispatch::TestRequest.create
              request.session = ActionController::TestSession.new
              request
            end
        end

        def build_controller(klass)
          klass.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
        end

        def preview_class(context)
          result = if context.respond_to?(:described_class)
            raise "`render_preview` expected a described_class, but it is nil." if context.described_class.nil?

            "#{context.described_class}Preview"
          else
            context.class.name.gsub("Test", "Preview")
          end
          result = result.constantize
        rescue NameError
          raise NameError, "`render_preview` expected to find #{result}, but it does not exist."
        end
      end.new
    end
  end
end
