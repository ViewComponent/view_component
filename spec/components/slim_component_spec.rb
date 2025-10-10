describe SlimComponent do

  before do
    ViewComponent::CompileCache.invalidate!

    # FIXME: found a better way to "simulate" Slim delay initialization
    ActionView::Template.unregister_template_handler(:slim)
    Slim.send(:remove_const, :RailsTemplate) if defined?(Slim::RailsTemplate)
  end

  context "when slim has not been loaded yet" do
    it "raise error" do
      expect { render_preview(:default) }.to raise_error(/Couldn't find a template file or inline render method for SlimComponent/)
    end
  end

  context "when slim has been lazy loaded" do
    before do
      require "slim"

      # Same stuff as to simulate lazy load: https://github.com/slim-template/slim/blob/main/lib/slim/railtie.rb#L7
      Slim::RailsTemplate = Temple::Templates::Rails(
        Slim::Engine,
        register_as: :slim,
        generator: Temple::Generators::RailsOutputBuffer,
        disable_capture: true,
        streaming: true
      )
    end

    it "renders the component" do
      render_preview(:default)

      expect(page).to have_css "div.slim-div", text: "Hello"
    end
  end
end
