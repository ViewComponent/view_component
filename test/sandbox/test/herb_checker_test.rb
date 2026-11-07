# frozen_string_literal: true

require "test_helper"
require "rake"

class HerbCheckerTest < ActiveSupport::TestCase
  def test_source_templates_include_sidecar_and_inline_templates_only
    assert_equal(
      ["#{Rails.root}/app/components/my_component.html.erb"],
      MyComponent.__vc_compiler.source_templates.map { |template| File.expand_path(template.path) }
    )

    inline = Class.new(ViewComponent::Base) { erb_template "<div></div>" }
    assert_equal [:inline], inline.__vc_compiler.source_templates.map(&:type)

    call = Class.new(ViewComponent::Base) do
      def call
        "<div></div>".html_safe
      end
    end
    assert_empty call.__vc_compiler.source_templates
  end

  def test_handler_template_and_source_match_what_the_compiler_passes_the_handler
    component = Class.new(ViewComponent::Base) do
      strip_trailing_whitespace

      erb_template "<div></div>\n\n"
    end
    template = component.__vc_compiler.source_templates.first

    assert_equal :html, template.handler_template.format
    assert_equal "text/html", template.handler_template.type.to_s
    assert_equal File.basename(__FILE__), File.basename(template.handler_template.identifier)
    assert_equal "<div></div>", template.handler_source
  end

  def test_reports_sidecar_template_that_herb_cannot_compile
    skip_unless_herb_supported

    Dir.mktmpdir do |directory|
      component = component_in(directory, "BrokenSidecarComponent")
      File.write(File.join(directory, "broken_sidecar_component.html.erb"), "<div><%= 1 %>\n")

      failures = ViewComponent::HerbChecker.check([component])

      assert_equal 1, failures.size
      assert_equal component, failures.first.component
      assert_equal File.join(directory, "broken_sidecar_component.html.erb"), failures.first.template.path
      assert_kind_of ::Herb::Engine::CompilationError, failures.first.error
      assert_includes failures.first.identifier, "(BrokenSidecarComponent)"
    end
  end

  def test_reports_inline_template_that_herb_cannot_compile
    skip_unless_herb_supported

    component = Class.new(ViewComponent::Base) { erb_template "<div><%= 1 %>" }

    failures = ViewComponent::HerbChecker.check([component])

    assert_equal 1, failures.size
    assert_equal :inline, failures.first.template.type
    assert_match(/#{File.basename(__FILE__)}:\d+ \(/, failures.first.identifier)
  end

  def test_reports_erb_output_in_attribute_names
    skip_unless_herb_supported

    component = Class.new(ViewComponent::Base) { erb_template "<div <%= 'class' %>=\"a\"></div>" }

    assert_equal 1, ViewComponent::HerbChecker.check([component]).size
  end

  def test_accepts_templates_herb_compiles
    skip_unless_herb_supported

    Dir.mktmpdir do |directory|
      component = component_in(directory, "ValidSidecarComponent")
      File.write(File.join(directory, "valid_sidecar_component.html.erb"), "<div><%= 1 %></div>\n")
      inline = Class.new(ViewComponent::Base) { erb_template "<p><%= 1 %></p>" }

      assert_empty ViewComponent::HerbChecker.check([component, inline])
    end
  end

  def test_skips_templates_that_are_not_html_erb
    skip_unless_herb_supported

    Dir.mktmpdir do |directory|
      component = component_in(directory, "OtherFormatsComponent")
      File.write(File.join(directory, "other_formats_component.html.haml"), "%div\n")
      File.write(File.join(directory, "other_formats_component.text.erb"), "<div><%= 1 %>\n")

      assert_empty ViewComponent::HerbChecker.check([component])
    end
  end

  def test_herb_check_task_runs_the_component_check
    application = Rake::Application.new
    Rake.with_application(application) do
      load File.expand_path("../../../lib/view_component/tasks/herb.rake", __dir__)
    end

    assert_equal ["environment"], application["view_component:herb:check"].prerequisites
    assert_equal ["environment"], application["view_component:herb:report"].prerequisites
    assert_equal ["view_component:herb:report"], application["herb:check"].prerequisites
  end

  private

  def skip_unless_herb_supported
    skip "Action View doesn't compile ERB through Herb" unless ViewComponent::HerbChecker.supported?
  end

  def component_in(directory, name)
    Class.new(ViewComponent::Base).tap do |component|
      component.identifier = File.join(directory, "#{name.underscore}.rb")
      component.define_singleton_method(:name) { name }
    end
  end
end
