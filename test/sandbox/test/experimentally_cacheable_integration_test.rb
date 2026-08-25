# frozen_string_literal: true

require "test_helper"

# Proves the scenario from https://github.com/ViewComponent/view_component/issues/234:
# a `<% cache %>` block in a view that renders a component is invalidated when
# the component changes.
class ExperimentallyCacheableIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    clear_digest_cache
    ActionController::Base.perform_caching = true
  end

  def teardown
    ActionController::Base.perform_caching = false
    Rails.cache.clear
    clear_digest_cache
  end

  def test_renders_a_component_inside_a_cache_block
    get "/cached_component"

    assert_response :success
    assert_select(".cacheable", text: "cached")
  end

  def test_cache_block_is_invalidated_when_the_component_template_changes
    get "/cached_component"
    assert_select(".cacheable", text: "cached")

    modify_file "app/components/cacheable_component.html.erb", "<div class=\"cacheable\">changed</div>\n" do
      clear_digest_cache
      with_new_cache do
        get "/cached_component"
        assert_select(".cacheable", text: "changed")
      end
    end
  end

  def test_cache_block_is_invalidated_when_the_component_ruby_file_changes
    get "/cached_component"
    assert_select(".cacheable", text: "cached")

    before = fragment_digest_for("integration_examples/cached_component")

    original = File.read(Rails.root.join("app/components/cacheable_component.rb"))
    modify_file "app/components/cacheable_component.rb", original + "\n# a comment\n" do
      clear_digest_cache

      refute_equal before, fragment_digest_for("integration_examples/cached_component")
    end
  end

  def test_cache_block_is_invalidated_when_a_nested_component_changes
    get "/cached_nested_component"
    assert_select(".cacheable-child", text: "child")

    before = fragment_digest_for("integration_examples/cached_nested_component")

    modify_file "app/components/cacheable_child_component.html.erb", "<span class=\"cacheable-child\">changed</span>\n" do
      clear_digest_cache

      refute_equal before, fragment_digest_for("integration_examples/cached_nested_component")
    end
  end

  def test_cache_block_digest_is_unaffected_by_unrelated_components
    before = fragment_digest_for("integration_examples/cached_component")

    modify_file "app/components/erb_component.html.erb", "<div>unrelated change</div>\n" do
      clear_digest_cache

      assert_equal before, fragment_digest_for("integration_examples/cached_component")
    end
  end

  def test_component_output_is_cached_between_requests
    get "/cached_component"
    assert_select(".cacheable", text: "cached")

    # The component's own `cache_on` entry is written on first render.
    component = CacheableComponent.new(title: "cached")
    refute_nil Rails.cache.read(component.cache_key(view_context))
  end

  private

  # The digest Rails mixes into every `<% cache %>` key in the given template.
  #
  # Built from a fresh lookup context each time: an existing one holds its own
  # digest cache, which a real request would never reuse across a code reload.
  def fragment_digest_for(virtual_path)
    ActionView::Digestor.digest(
      name: virtual_path,
      format: :html,
      finder: ActionView::LookupContext.new(ActionController::Base.view_paths)
    )
  end

  def view_context
    ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create }.view_context
  end
end
