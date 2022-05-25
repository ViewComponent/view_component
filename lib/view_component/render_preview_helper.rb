# frozen_string_literal: true

module ViewComponent
  module RenderPreviewHelper
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
    # @param preview [String] The name of the preview to be rendered.
    # @return [Nokogiri::HTML]
    def render_preview(name)
      begin
        preview_klass = self.class.name.gsub("Test", "Preview")
        preview_klass = preview_klass.constantize
      rescue NameError
        raise NameError.new(
          "`render_preview` expected to find #{preview_klass}, but it does not exist."
        )
      end

      previews_controller = build_controller(ViewComponent::Base.preview_controller.constantize)
      previews_controller.request.params[:path] = "#{preview_klass.preview_name}/#{name}"
      previews_controller.response = ActionDispatch::Response.new
      result = previews_controller.previews

      @rendered_content = result

      Nokogiri::HTML.fragment(@rendered_content)
    end
  end
end
