# frozen_string_literal: true

module ViewComponent
  module SystemTestHelpers
    include TestHelpers

    #
    # Returns a block that can be used to visit the path of the inline rendered component.
    # @param fragment [Nokogiri::Fragment] The fragment returned from `render_inline`.
    # @param layout [String] The (optional) layout to use.
    # @return [Proc] A block that can be used to visit the path of the inline rendered component.
    def with_rendered_component_path(fragment, layout: false, &block)
      # Add './tmp/view_components/' directory if it doesn't exist to store the rendered component HTML
      FileUtils.mkdir_p("./tmp/view_components/") unless Dir.exist?("./tmp/view_components/")

      file = Tempfile.new(["rendered_#{fragment.class.name}", ".html"], "tmp/view_components/")
      begin
        file.write(controller.render_to_string(html: fragment.to_html.html_safe, layout: layout))
        file.rewind

        block.call("/_system_test_entrypoint?file=#{file.path.split("/").last}")
      ensure
        file.unlink
      end
    end
  end
end
