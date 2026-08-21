# frozen_string_literal: true

require "test_helper"

# Failing tests for the issues @reeganviljoen reported reviewing #2685.
# https://github.com/ViewComponent/view_component/pull/2685
class ExperimentallyCacheableReviewTest < ViewComponent::TestCase
  def setup
    super
    Rails.cache.clear
    ConditionalCacheProbeComponent.render_count = 0
  end

  def teardown
    Rails.cache.clear
    super
  end

  # Issue 1: format is passed to `cache_digest` but never enters the key itself.
  # Two formats whose digests match therefore share one cache entry.
  def test_formats_do_not_share_a_cache_entry
    with_caching do
      with_format(:html) do
        render_inline(FormatSensitiveCacheableComponent.new)
        assert_text "html"
      end

      with_format(:json) do
        render_inline(FormatSensitiveCacheableComponent.new)

        assert_text "json"
      end
    end
  end

  def test_cache_key_differs_by_format
    html_key = with_format(:html) { FormatSensitiveCacheableComponent.new.cache_key(vc_test_controller.view_context) }
    json_key = with_format(:json) { FormatSensitiveCacheableComponent.new.cache_key(vc_test_controller.view_context) }

    refute_equal html_key, json_key
  end

  # Issue 2: the key array is compacted as a whole, so a nil in one position is
  # indistinguishable from a nil in another.
  def test_nil_cache_on_values_do_not_collide_positionally
    left = PositionalCacheKeyComponent.new(first: nil, second: "same")
    right = PositionalCacheKeyComponent.new(first: "same", second: nil)

    refute_equal left.cache_key, right.cache_key
  end

  def test_nil_and_empty_cache_on_values_do_not_collide
    nils = PositionalCacheKeyComponent.new(first: nil, second: nil)
    empties = PositionalCacheKeyComponent.new(first: "", second: "")

    refute_equal nils.cache_key, empties.cache_key
  end

  # Issue 3: there's no way to skip caching for a single render. A false or nil
  # value from a `cache_on` method becomes an ordinary key component (or is
  # dropped from the key) rather than disabling the cache.
  def test_caching_can_be_disabled_per_render
    with_caching do
      render_inline(ConditionalCacheProbeComponent.new(cacheable: false))
      render_inline(ConditionalCacheProbeComponent.new(cacheable: false))

      assert_equal 2, ConditionalCacheProbeComponent.render_count
    end
  end

  def test_caching_still_applies_when_the_condition_is_met
    with_caching do
      render_inline(ConditionalCacheProbeComponent.new(cacheable: true))
      render_inline(ConditionalCacheProbeComponent.new(cacheable: true))

      assert_equal 1, ConditionalCacheProbeComponent.render_count
    end
  end

  def test_cache_conditions_accept_a_proc
    component = Class.new(ConditionalCacheProbeComponent) do
      def self.name
        "ProcConditionCacheProbeComponent"
      end

      cache_on :identity, if: -> { false }
    end

    with_caching do
      render_inline(component.new(cacheable: true))
      render_inline(component.new(cacheable: true))

      assert_equal 2, component.render_count
    end
  end

  def test_cache_conditions_accept_unless
    component = Class.new(ConditionalCacheProbeComponent) do
      def self.name
        "UnlessConditionCacheProbeComponent"
      end

      cache_on :identity, unless: :cacheable?
    end

    with_caching do
      render_inline(component.new(cacheable: true))
      render_inline(component.new(cacheable: true))

      assert_equal 2, component.render_count
    end
  end

  def test_cache_conditions_are_inherited
    component = Class.new(ConditionalCacheProbeComponent) do
      def self.name
        "InheritedConditionCacheProbeComponent"
      end
    end

    with_caching do
      render_inline(component.new(cacheable: false))
      render_inline(component.new(cacheable: false))

      assert_equal 2, component.render_count
    end
  end

  def test_cache_on_rejects_unknown_options
    error = assert_raises(ArgumentError) do
      Class.new(ViewComponent::Base) do
        include ViewComponent::ExperimentallyCacheable

        cache_on :identity, when: :something
      end
    end

    assert_match(/:when/, error.message)
  end

  def test_undefined_cache_condition_method_raises
    component = Class.new(ConditionalCacheProbeComponent) do
      def self.name
        "MissingConditionCacheProbeComponent"
      end

      cache_on :identity, if: :nonexistent?
    end

    with_caching do
      error = assert_raises(ViewComponent::UndefinedCacheKeyMethodError) do
        render_inline(component.new(cacheable: true))
      end

      assert_includes error.message, "nonexistent?"
    end
  end

  # Issue 4: a block passed to `cache_on` is silently dropped, leaving the
  # component uncached with no indication why.
  def test_cache_on_rejects_a_block
    assert_raises(ArgumentError) do
      Class.new(ViewComponent::Base) do
        include ViewComponent::ExperimentallyCacheable

        cache_on { :identity }
      end
    end
  end

  # ...and a proc raises NoMethodError from `to_sym` rather than saying what's
  # wrong.
  def test_cache_on_rejects_a_proc_with_a_useful_error
    error = assert_raises(ArgumentError) do
      Class.new(ViewComponent::Base) do
        include ViewComponent::ExperimentallyCacheable

        cache_on -> { :identity }
      end
    end

    assert_match(/cache_on/, error.message)
  end

  private

  def with_caching
    old_value = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
    yield
  ensure
    ActionController::Base.perform_caching = old_value
    Rails.cache.clear
  end
end
