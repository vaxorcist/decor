# decor/test/controllers/admin/newsletters_controller_test.rb
# version 1.0
# Session 58: Newsletter feature — initial controller test file.
#
# Covers Admin::NewslettersController actions:
#   index          — GET /admin/newsletters
#   new            — GET /admin/newsletters/new
#   create         — POST /admin/newsletters (with MD file upload)
#   show           — GET /admin/newsletters/:id
#   destroy        — DELETE /admin/newsletters/:id
#   send_newsletter GET  /admin/newsletters/:id/send_newsletter
#   send_newsletter POST /admin/newsletters/:id/send_newsletter
#
# Auth model:
#   Admin::BaseController guards all actions with require_admin.
#   Tests verify both happy-path (logged in as alice, admin) and auth guard
#   (unauthenticated request redirects — one representative test per controller).
#
# ActionMailer::TestHelper:
#   Included here because ActionDispatch::IntegrationTest does NOT include it
#   automatically. Required for assert_emails / assert_no_emails in send tests.
#   See RAILS_SPECIFICS.md "Rails Test Class — Required Inclusions".
#
# deliver_now:
#   The controller uses deliver_now (not deliver_later) for admin-initiated sends,
#   so ActionMailer::Base.deliveries is populated synchronously during the request.
#   deliveries are cleared in setup to prevent cross-test contamination.
#
# File upload:
#   create action reads params[:newsletter][:md_file].read so the test must
#   supply a Rack::Test::UploadedFile wrapping a real temp file.
#   See RAILS_SPECIFICS.md "File Uploads in Integration Tests".

require "test_helper"

class Admin::NewslettersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    # Log in as alice (admin: true) for all tests unless a test overrides this.
    @admin = owners(:one)
    login_as @admin

    # Reset deliveries before each test so counts are independent.
    ActionMailer::Base.deliveries.clear
  end

  # ── Auth guard — representative test ─────────────────────────────────────
  # One auth guard test covers the whole controller (BaseController enforces it).

  test "unauthenticated request to index redirects" do
    # Log out by clearing the session so the request is unauthenticated.
    delete session_path
    get admin_newsletters_path
    assert_response :redirect,
      "Unauthenticated request to admin#index should redirect to login"
  end

  # ── index ─────────────────────────────────────────────────────────────────

  test "GET index returns 200" do
    get admin_newsletters_path
    assert_response :success
  end

  test "GET index lists newsletter subjects" do
    get admin_newsletters_path
    assert_body_includes newsletters(:one).subject
    assert_body_includes newsletters(:two).subject
  end

  # ── new ───────────────────────────────────────────────────────────────────

  test "GET new returns 200" do
    get new_admin_newsletter_path
    assert_response :success
  end

  # ── create ────────────────────────────────────────────────────────────────

  test "POST create with valid MD file saves newsletter and redirects to show" do
    tempfile = Tempfile.new(["newsletter", ".md"])
    tempfile.write("# Spring Edition\n\nHello {{user_name}}, welcome back.")
    tempfile.rewind

    upload = Rack::Test::UploadedFile.new(
      tempfile.path, "text/markdown", false,
      original_filename: "spring.md"
    )

    assert_difference "Newsletter.count", 1 do
      post admin_newsletters_path, params: {
        newsletter: { subject: "Spring Edition 2026", md_file: upload }
      }
    end

    saved = Newsletter.last
    assert_redirected_to admin_newsletter_path(saved)
    assert_equal "Spring Edition 2026", saved.subject
    assert saved.html_body.present?,
      "html_body should be generated from markdown_body on save"
  ensure
    tempfile.close
    tempfile.unlink
  end

  test "POST create without file renders new with unprocessable_entity" do
    assert_no_difference "Newsletter.count" do
      post admin_newsletters_path, params: {
        newsletter: { subject: "No File Newsletter", md_file: nil }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create with blank subject renders new with unprocessable_entity" do
    tempfile = Tempfile.new(["newsletter", ".md"])
    tempfile.write("Body content without a subject.")
    tempfile.rewind

    upload = Rack::Test::UploadedFile.new(
      tempfile.path, "text/markdown", false,
      original_filename: "no_subject.md"
    )

    assert_no_difference "Newsletter.count" do
      post admin_newsletters_path, params: {
        newsletter: { subject: "", md_file: upload }
      }
    end
    assert_response :unprocessable_entity
  ensure
    tempfile.close
    tempfile.unlink
  end

  # ── show ──────────────────────────────────────────────────────────────────

  test "GET show returns 200" do
    get admin_newsletter_path(newsletters(:one))
    assert_response :success
  end

  test "GET show displays the newsletter subject" do
    newsletter = newsletters(:one)
    get admin_newsletter_path(newsletter)
    assert_body_includes newsletter.subject
  end

  # ── destroy ───────────────────────────────────────────────────────────────

  test "DELETE destroy removes the newsletter and redirects to index" do
    newsletter = newsletters(:two)

    assert_difference "Newsletter.count", -1 do
      delete admin_newsletter_path(newsletter)
    end

    assert_redirected_to admin_newsletters_path
    assert_nil Newsletter.find_by(id: newsletter.id),
      "Newsletter should be gone from the DB after destroy"
  end

  test "DELETE destroy shows a confirmation notice with the subject" do
    newsletter = newsletters(:two)
    delete admin_newsletter_path(newsletter)
    assert_includes flash[:notice], newsletter.subject
  end

  # ── send_newsletter (GET) ─────────────────────────────────────────────────

  test "GET send_newsletter returns 200" do
    get send_newsletter_admin_newsletter_path(newsletters(:one))
    assert_response :success
  end

  # ── send_newsletter (POST) — recipient: all ───────────────────────────────

  test "POST send_newsletter with recipient=all delivers one email per subscribed owner" do
    # alice (one) and charlie (three) are subscribed (newsletter: 1) per owners.yml v2.2.
    # bob (two) has newsletter: 0 and must NOT receive the newsletter.
    subscribed_count = Owner.newsletter_subscribed.count

    post send_newsletter_admin_newsletter_path(newsletters(:one)),
         params: { recipient: "all" }

    assert_equal subscribed_count, ActionMailer::Base.deliveries.count,
      "Should deliver exactly one email per subscribed owner"
    assert_redirected_to admin_newsletters_path
    assert_includes flash[:notice], subscribed_count.to_s
  end

  test "POST send_newsletter with recipient=all addresses emails to subscribed owners" do
    post send_newsletter_admin_newsletter_path(newsletters(:one)),
         params: { recipient: "all" }

    delivered_to = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_includes delivered_to, owners(:one).email,   "alice should receive the newsletter"
    assert_includes delivered_to, owners(:three).email, "charlie should receive the newsletter"
    refute_includes delivered_to, owners(:two).email,   "bob (newsletter: 0) must not receive it"
  end

  # ── send_newsletter (POST) — recipient: specific ──────────────────────────

  test "POST send_newsletter with recipient=specific and valid owner_id sends one email" do
    recipient = owners(:two)  # bob — not subscribed, but specific-owner send ignores preference

    assert_emails 1 do
      post send_newsletter_admin_newsletter_path(newsletters(:one)),
           params: { recipient: "specific", owner_id: recipient.id }
    end

    assert_redirected_to admin_newsletters_path
    assert_includes flash[:notice], recipient.user_name
  end

  test "POST send_newsletter with recipient=specific sends to the correct address" do
    recipient = owners(:two)

    post send_newsletter_admin_newsletter_path(newsletters(:one)),
         params: { recipient: "specific", owner_id: recipient.id }

    delivery = ActionMailer::Base.deliveries.last
    assert_equal [recipient.email], delivery.to
  end

  test "POST send_newsletter with recipient=specific and blank owner_id rerenders form" do
    assert_no_emails do
      post send_newsletter_admin_newsletter_path(newsletters(:one)),
           params: { recipient: "specific", owner_id: "" }
    end

    assert_response :unprocessable_entity
  end

  # ── send_newsletter (POST) — no recipient selected ────────────────────────

  test "POST send_newsletter with no recipient param rerenders form" do
    assert_no_emails do
      post send_newsletter_admin_newsletter_path(newsletters(:one)),
           params: { recipient: nil }
    end

    assert_response :unprocessable_entity
  end
end
