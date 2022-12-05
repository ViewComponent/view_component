# frozen_string_literal: true

module ViewComponent
  module SystemTestHelpers
    include TestHelpers

    #
    # Returns a block that can be used to visit the path of the inline rendered
    # component.
    # @param fragment [Nokogiri::Fragment] The fragment of the inline rendered component.
    # @param layout [String] The layout to use for the inline rendered component.
    # @return [Proc] A block that can be used to visit the path of the inline rendered component.
    def with_rendered_component_path(fragment, **options, &block)
      layout = options[:layout] || false

      opts = {
        layout: layout,
        locals: {
          render_args: {
            fragment: fragment.to_html.html_safe,
            hide_preview_source: true
          }
        }
      }

      html = controller.render_to_string("view_components/preview", opts)

      # Add './tmp/view_components/' directory if it doesn't exist to store the rendered component html
      FileUtils.mkdir_p("./tmp/view_components/") unless Dir.exist?("./tmp/view_components/")

      # Write to temporary file to contain fully rendered component
      # within a browser
      file = Tempfile.new(["rendered_#{fragment.class.name}", ".html"], "tmp/view_components/")
      begin
        file.write(html)
        file.rewind

        filename = file.path.split("/").last
        path = "/system_test_entrypoint?file=#{filename}"

        block.call(path)
      ensure
        file.unlink
      end
    end
  end
end
