# frozen_string_literal: true

require "test_helper"

class MailerTest < ViewComponent::TestCase
  def test_rendering_component_in_an_action_mailer
    assert_includes TestMailer.test_email.deliver_now.body.raw_source, "<div>Hello world!</div>"
  end
end
