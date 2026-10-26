# frozen_string_literal: true

class TestMailer < ActionMailer::Base
  def test_email
    mail(
      from: "no-reply@example.com",
      to: "test@example.com",
      subject: "Testing ViewComponent in ActionMailer"
    )
  end

  def test_asset_email
    mail(
      from: "no-reply@example.com",
      to: "test@example.com",
      subject: "Testing ViewComponent with Assets in ActionMailer"
    )
  end

  def test_url_email
    mail(
      from: "no-reply@example.com",
      to: "test@example.com",
      subject: "Testing ViewComponent with url_for in ActionMailer"
    )
  end

  def test_multipart_email
    mail(
      from: "no-reply@example.com",
      to: "test@example.com",
      subject: "Testing ViewComponent in a multipart ActionMailer email"
    ) do |format|
      format.text
      format.html
    end
  end
end
