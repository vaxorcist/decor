# decor/test/mailers/newsletter_mailer_test.rb
# version 1.0
# Session 58: Newsletter feature — initial mailer test file.
#
# Covers NewsletterMailer#send_newsletter:
#   - Correct to: and subject: headers
#   - {{user_name}} placeholder is replaced in the rendered HTML body
#   - {{user_name}} placeholder is NOT present after substitution
#   - Newsletter body without the placeholder is rendered without error
#
# Class: ActionMailer::TestCase — inheriting this class automatically includes
# ActionMailer::TestHelper (assert_emails, assert_no_emails) and sets up the
# test delivery mode. No explicit include needed here.
#
# Body inspection:
#   The mailer has a single HTML template (send_newsletter.html.erb).
#   html_part is used when the message is multipart; for a single-part HTML
#   email, body.decoded also works. The helper method mail_html_body handles
#   both cases safely.
#
# Substitution mechanics:
#   NewsletterMailer assigns @html_body = newsletter.html_body.gsub("{{user_name}}", owner.user_name)
#   before rendering. The view receives the already-substituted string. Therefore
#   the rendered body must contain owner.user_name and must NOT contain "{{user_name}}".

require "test_helper"

class NewsletterMailerTest < ActionMailer::TestCase
  # ── Helper ────────────────────────────────────────────────────────────────

  # Returns the decoded HTML body regardless of whether the mail is multipart.
  def mail_html_body(mail)
    if mail.html_part
      mail.html_part.body.decoded
    else
      mail.body.decoded
    end
  end

  # ── Headers ───────────────────────────────────────────────────────────────

  test "send_newsletter sets the correct to address" do
    owner      = owners(:one)   # alice
    newsletter = newsletters(:one)

    mail = NewsletterMailer.send_newsletter(owner, newsletter)

    assert_equal [owner.email], mail.to,
      "mail.to should be the recipient's email address"
  end

  test "send_newsletter sets the correct subject" do
    owner      = owners(:one)
    newsletter = newsletters(:one)

    mail = NewsletterMailer.send_newsletter(owner, newsletter)

    assert_equal newsletter.subject, mail.subject,
      "mail.subject should match the newsletter's subject field"
  end

  # ── {{user_name}} substitution in the rendered body ─────────────────────
  # fixtures(:one).html_body contains "{{user_name}}" — checked by newsletter_test.rb.
  # After send_newsletter runs gsub, the rendered HTML body must have the
  # owner's actual user_name in place of the placeholder.

  test "send_newsletter replaces {{user_name}} with the recipient's user_name" do
    owner      = owners(:one)   # alice
    newsletter = newsletters(:one)

    mail = NewsletterMailer.send_newsletter(owner, newsletter)
    body = mail_html_body(mail)

    assert_includes body, owner.user_name,
      "Rendered body must contain the recipient's user_name after substitution"
  end

  test "send_newsletter does not leave the raw {{user_name}} placeholder in the body" do
    owner      = owners(:one)
    newsletter = newsletters(:one)

    mail = NewsletterMailer.send_newsletter(owner, newsletter)
    body = mail_html_body(mail)

    refute_includes body, "{{user_name}}",
      "The {{user_name}} placeholder must not appear in the rendered body"
  end

  test "send_newsletter substitutes user_name for a different recipient" do
    # Verifies substitution works regardless of which owner receives the mail.
    owner      = owners(:three)  # charlie
    newsletter = newsletters(:one)

    mail = NewsletterMailer.send_newsletter(owner, newsletter)
    body = mail_html_body(mail)

    assert_includes body, owner.user_name,  # "charlie"
      "Body must contain charlie's user_name"
    refute_includes body, "{{user_name}}"
  end

  # ── Newsletter without placeholder ────────────────────────────────────────

  test "send_newsletter renders a newsletter without the placeholder without error" do
    # fixtures(:two) has no {{user_name}} in its body. gsub returns the original
    # string unchanged — the mailer must not raise when no substitution occurs.
    owner      = owners(:one)
    newsletter = newsletters(:two)

    assert_nothing_raised do
      mail = NewsletterMailer.send_newsletter(owner, newsletter)
      assert mail_html_body(mail).present?, "Body should be non-empty"
    end
  end

  # ── Delivery ──────────────────────────────────────────────────────────────

  test "calling deliver_now stores the email in ActionMailer deliveries" do
    owner      = owners(:one)
    newsletter = newsletters(:one)

    assert_emails 1 do
      NewsletterMailer.send_newsletter(owner, newsletter).deliver_now
    end
  end
end
