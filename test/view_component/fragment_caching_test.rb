# frozen_string_literal: true

require "test_helper"
require "view_component/caching/erb_tracker"
require "view_component/caching/component_tracker"

class DependencyTrackingTest < ActionDispatch::IntegrationTest
  def setup
    Mime::Type.register "text/ruby", :rb
    set_tracker :erb, ViewComponent::Caching::ERBTracker
    set_tracker :rb, ViewComponent::Caching::ComponentTracker
  end

  def teardown
    Mime::Type.unregister :rb
    set_tracker :erb, ActionView::DependencyTracker::ERBTracker
    set_tracker :rb, nil
  end

  test "finds dependencies of rails templates including components" do
    name = "integration_examples/partial"
    template = find_template name, "test/app/views", :html

    dependencies = ActionView::DependencyTracker.find_dependencies name, template

    assert_equal ["integration_examples/test_partial", "PartialComponent"], dependencies
  end

  test "finds dependencies of components including template files and parent classes" do
    name = "InheritedWithOwnTemplateComponent"
    template = find_template name.underscore, "test/app/components", :rb

    dependencies = ActionView::DependencyTracker.find_dependencies name, template

    assert_equal ["inherited_with_own_template_component", "MyComponent"], dependencies
  end

  private

    def set_tracker(extension, tracker)
      ActionView::DependencyTracker.remove_tracker ActionView::Template.handler_for_extension(extension)
      ActionView::DependencyTracker.register_tracker extension, tracker if tracker
    end

    def find_template(name, path, format)
      template_finder(path, format).find_all(name, [], false, []).first
    end

    def template_finder(path, format)
      ActionView::LookupContext.new(
        ActionView::PathSet.new([path]),
        formats: [format]
      )
    end
end
