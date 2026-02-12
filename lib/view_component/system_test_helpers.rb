# frozen_string_literal: true

require "securerandom"

module ViewComponent
  module SystemTestHelpers
    include TestHelpers

    # Returns a block that can be used to visit the path of the inline rendered component.
    # @param fragment [Nokogiri::Fragment] The fragment returned from `render_inline`.
    # @param layout [String] The (optional) layout to use.
    # @return [Proc] A block that can be used to visit the path of the inline rendered component.
    def with_rendered_component_path(fragment, layout: false, &block)
      filename = "rendered_#{fragment.class.name.gsub("::", "")}_#{SecureRandom.hex(8)}.html"
      path = File.join(ViewComponentsSystemTestController.temp_dir, filename)

      File.write(path, vc_test_controller.render_to_string(html: fragment.to_html.html_safe, layout: layout))

      yield("/_system_test_entrypoint?file=#{filename}")
    end
  end
end
