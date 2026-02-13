# frozen_string_literal: true

require "base64"
require "securerandom"

module ViewComponent
  module SystemTestHelpers
    include TestHelpers

    # Returns a block that can be used to visit the path of the inline rendered component.
    # @param fragment [Nokogiri::Fragment] The fragment returned from `render_inline`.
    # @param layout [String] The (optional) layout to use.
    # @return [Proc] A block that can be used to visit the path of the inline rendered component.
    def with_rendered_component_path(fragment, layout: false, &block)
      rendered_html = vc_test_controller.render_to_string(html: fragment.to_html.html_safe, layout: layout)

      if use_inline_data_url?(layout)
        yield("data:text/html;base64,#{Base64.strict_encode64(rendered_html)}")
        return
      end

      filename = "rendered_#{fragment.class.name.gsub("::", "")}_#{SecureRandom.hex(8)}.html"
      path = File.join(ViewComponentsSystemTestController.temp_dir, filename)

      File.write(path, rendered_html)

      yield("/_system_test_entrypoint?file=#{filename}")
    end

    private

    def use_inline_data_url?(layout)
      return false if layout
      return true if defined?(ActionDispatch::SystemTestCase) && is_a?(ActionDispatch::SystemTestCase)
      return false unless defined?(Capybara) && Capybara.respond_to?(:current_driver)

      Capybara.current_driver != :rack_test
    end
  end
end
