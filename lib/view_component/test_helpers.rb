# frozen_string_literal: true

module ViewComponent
  module TestHelpers
    begin
      require "capybara/minitest"
      include Capybara::Minitest::Assertions

      def page
        Capybara::Node::Simple.new(@raw)
      end

      def refute_component_rendered
        assert_no_selector("body")
      end
    rescue LoadError
      warn "WARNING in `ViewComponent::TestHelpers`: You must add `capybara` to your Gemfile to use Capybara assertions."
    end

    def render_inline(component, **args, &block)
      @raw = controller.view_context.render(component, args, &block)

      Nokogiri::HTML.fragment(@raw)
    end

    def controller
      @controller ||= Base.test_controller.constantize.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
    end

    def request
      @request ||= ActionDispatch::TestRequest.create
    end

    def with_variant(variant)
      old_variants = controller.view_context.lookup_context.variants

      controller.view_context.lookup_context.variants = variant
      yield
      controller.view_context.lookup_context.variants = old_variants
    end
  end
end
