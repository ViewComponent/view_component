# frozen_string_literal: true

# require "abstract_unit"
require "active_support/log_subscriber/test_helper"
require "action_view/log_subscriber"
# require "controller/fake_models"

require "test_helper"

class LogSubscriberTest < ViewComponent::TestCase
  include ActiveSupport::LogSubscriber::TestHelper

  def setup
    super

    ViewComponent::LogSubscriber.attach_to :view_component
  end

  def teardown
    super

    ActiveSupport::LogSubscriber.log_subscribers.clear
  end

  def set_logger(logger)
    ActionView::Base.logger = logger
  end

  def test_inline_component
    render_inline(InlineComponent.new)
    wait

    assert_equal 1, @logger.logged(:debug).size
    assert_match(/Rendered InlineComponent/, @logger.logged(:debug).last)
  end

  def test_button_to_component
    render_inline(ButtonToComponent.new)
    wait

    assert_equal 1, @logger.logged(:debug).size
    assert_match(/Rendered ButtonToComponent/, @logger.logged(:debug).last)
  end

  def test_variants_component
    with_variant :phone do
      render_inline(VariantsComponent.new)
      wait

      assert_equal 1, @logger.logged(:debug).size
      assert_match(/Rendered VariantsComponent/, @logger.logged(:debug).last)
    end
  end

  def test_collection
    products = [OpenStruct.new(name: "Radio clock"), OpenStruct.new(name: "Mints")]
    render_inline(ProductComponent.with_collection(products, notice: "On sale"))
    wait

    assert_equal 1, @logger.logged(:debug).size
    assert_match(/Rendered collection of ProductComponent/, @logger.logged(:debug).last)
    assert_match(/\[2 times\]/, @logger.logged(:debug).last)
  end
end
