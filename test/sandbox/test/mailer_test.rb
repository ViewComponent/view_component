# frozen_string_literal: true

require "test_helper"

class MailerTest < ActionMailer::TestCase
  def test_rendering_component_in_an_action_mailer
    result = TestMailer.test_email.deliver_now.body.to_s
    assert_includes result, "<div>Hello world!</div>"
    assert_includes result, "test_email.html.erb"
  end

  def test_rendering_component_in_an_action_mailer_with_asset_component
    result = TestMailer.test_asset_email.deliver_now.body.to_s
    assert_includes result, "<div>/assets"
  end

  def test_mailer_url_host
    result = TestMailer.test_url_email.deliver_now.body.to_s
    assert_includes result, "www.yourhost.com/posts"
  end
end
