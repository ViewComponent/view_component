# frozen_string_literal: true

require "test_helper"

class MailerTest < ActionMailer::TestCase
  def test_rendering_component_in_an_action_mailer
    result = TestMailer.test_email.deliver_now.body.to_s
    assert_includes result, "<div>Hello world!</div>"
  end

  def test_rendering_component_in_an_action_mailer_with_asset_component
    result = TestMailer.test_asset_email.deliver_now.body.to_s
    assert_includes result, "<div>/assets"
  end

  def test_rendering_component_in_each_part_of_a_multipart_action_mailer
    mail = TestMailer.test_multipart_email.deliver_now

    assert_includes mail.text_part.body.to_s, "Hello text!"
    assert_includes mail.html_part.body.to_s, "<div>Hello HTML!</div>"
  end

  def test_mailer_url_host
    result = TestMailer.test_url_email.deliver_now.body.to_s
    assert_includes result, "www.yourhost.com/posts"
  end
end
