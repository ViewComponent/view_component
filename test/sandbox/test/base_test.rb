# frozen_string_literal: true

require "test_helper"

class ViewComponent::Base::UnitTest < Minitest::Test
  def test_templates_parses_all_types_of_paths
    file_path = [
      "/Users/fake.user/path/to.templates/component/test_component.html+phone.erb",
      "/_underscore-dash./component/test_component.html+desktop.slim",
      "/tilda~/component/test_component.html.haml"
    ]
    expected = [
      {variant: :phone, handler: "erb"},
      {variant: :desktop, handler: "slim"},
      {variant: nil, handler: "haml"}
    ]

    compiler = ViewComponent::Compiler.new(ViewComponent::Base)

    ViewComponent::Base.stub(:sidecar_files, file_path) do
      templates = compiler.send(:templates)

      templates.each_with_index do |template, index|
        assert_equal(template[:path], file_path[index])
        assert_equal(template[:variant], expected[index][:variant])
        assert_equal(template[:handler], expected[index][:handler])
      end
    end
  end

  def test_calling_helpers_outside_render_raises
    component = ViewComponent::Base.new
    err =
      assert_raises ViewComponent::Base::ViewContextCalledBeforeRenderError do
        component.helpers
      end
    assert_includes err.message, "can't be used during initialization"
  end

  def test_calling_controller_outside_render_raises
    component = ViewComponent::Base.new
    err =
      assert_raises ViewComponent::Base::ViewContextCalledBeforeRenderError do
        component.controller
      end

    assert_includes err.message, "can't be used during initialization"
  end

  def test_sidecar_files
    root = ViewComponent::Engine.root.join("test/sandbox")

    assert_equal(
      [
        "#{root}/app/components/template_and_sidecar_directory_template_component.html.erb",
        "#{root}/app/components/template_and_sidecar_directory_template_component/" \
        "template_and_sidecar_directory_template_component.html.erb"
      ],
      TemplateAndSidecarDirectoryTemplateComponent.sidecar_files(["erb"])
    )

    assert_equal(
      [
        "#{root}/app/components/css_sidecar_file_component.css",
        "#{root}/app/components/css_sidecar_file_component.html.erb"
      ],
      CssSidecarFileComponent.sidecar_files(["css", "erb"])
    )

    assert_equal(
      ["#{root}/app/components/css_sidecar_file_component.css"],
      CssSidecarFileComponent.sidecar_files(["css"])
    )

    assert_equal(
      ["#{root}/app/components/translatable_component.yml"],
      TranslatableComponent.sidecar_files(["yml"])
    )
  end

  def test_does_not_render_additional_newline_with_render_in
    skip unless Rails::VERSION::MAJOR >= 7
    without_template_annotations do
      ActionView::Template::Handlers::ERB.strip_trailing_newlines = true
      rendered_output = Array.new(2) {
        DisplayInlineComponent.new.render_in(ActionController::Base.new.view_context)
      }.join
      assert_includes rendered_output, "<span>Hello, world!</span><span>Hello, world!</span>"
    end
  ensure
    ActionView::Template::Handlers::ERB.strip_trailing_newlines = false if Rails::VERSION::MAJOR >= 7
  end

  def test_evaled_component
    source = <<~RUBY
      class EvaledComponent < ViewComponent::Base
        def initialize(cta: nil, title:)
          @cta = cta
          @title = title
        end
        private

        attr_reader :cta, :title
      end
    RUBY

    eval(source) # rubocop:disable Security/Eval
  end
end
