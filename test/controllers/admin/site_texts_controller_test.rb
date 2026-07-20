# decor/test/controllers/admin/site_texts_controller_test.rb
# version 1.2
# v1.2 (Session 73): Added tests for the generalized url_for_key(key) fix
#   (admin/site_texts_controller.rb v1.3). The old hardcoded `case` statement
#   only covered the 4 pre-existing keys, so it could never have caught a
#   regression on a 5th key by construction. These new tests deliberately use
#   "help_computers" — one of the 5 new Category Help Pages keys added this
#   session, and NOT one of the 4 keys the old case statement happened to
#   list — to prove the redirect works for a key the method was never
#   special-cased for. Also added "help_computers" to the teardown cleanup list.
# v1.1 (Session 53): Added tests for download_confirm and download actions.
#   Also documents why the delete_confirm Turbo bug wasn't caught by this file:
#   controller tests call routes directly and cannot observe JS/Turbo link behaviour.
#   That gap can only be closed by system tests (test/system/ — still empty).
# v1.0 (Session 20): New file. Tests Admin::SiteTextsController actions:
#   new:            renders upload form
#   create:         success (saves content, redirects to public page),
#                   missing file (redirects back with alert)
#   delete_confirm: renders confirmation page
#   destroy:        success (deletes record), missing key (redirects with alert)
#
# No fixtures — SiteText records created inline and cleaned up in teardown.
# File uploads use Rack::Test::UploadedFile (required for integration tests —
# see RAILS_SPECIFICS.md: File Uploads in Integration Tests).

require "test_helper"

class Admin::SiteTextsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # alice is admin: true — required by Admin::BaseController
    login_as owners(:one)
  end

  def teardown
    # Clean up any SiteText records created during tests
    SiteText.where(key: %w[readme news test_upload_key help_computers]).destroy_all
  end

  # ── new ─────────────────────────────────────────────────────────────────────

  test "GET new renders upload form" do
    get new_admin_site_text_path
    assert_response :success
  end

  # ── create ──────────────────────────────────────────────────────────────────

  test "POST create with valid file saves content and redirects to public page" do
    tempfile = Tempfile.new(["upload", ".md"])
    tempfile.write("# Hello World")
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", false,
                                          original_filename: "readme.md")

    assert_difference "SiteText.count", 1 do
      post admin_site_texts_path, params: { key: "readme", file: upload }
    end

    assert_redirected_to readme_path
    assert_equal "Read Me was successfully updated.", flash[:notice]

    saved = SiteText.for("readme")
    assert_not_nil saved
    assert_equal "# Hello World", saved.content
  ensure
    tempfile&.unlink
  end

  test "POST create replaces existing content for the same key" do
    SiteText.create!(key: "readme", content: "# Old Content")

    tempfile = Tempfile.new(["upload", ".md"])
    tempfile.write("# New Content")
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", false,
                                          original_filename: "readme.md")

    assert_no_difference "SiteText.count" do
      post admin_site_texts_path, params: { key: "readme", file: upload }
    end

    assert_equal "# New Content", SiteText.for("readme").content
  ensure
    tempfile&.unlink
  end

  test "POST create without a file redirects back with alert" do
    assert_no_difference "SiteText.count" do
      post admin_site_texts_path, params: { key: "readme" }
    end

    assert_redirected_to new_admin_site_text_path
    assert_equal "Please select a .md file to upload.", flash[:alert]
  end

  # ── url_for_key generalization (Session 73) ──────────────────────────────────
  #
  # These use "help_computers" specifically — one of the 5 new Category Help
  # Pages keys, deliberately NOT one of the 4 keys the old hardcoded `case`
  # statement in url_for_key used to special-case. A regression back to the
  # old case statement (or a typo in the new send("#{key}_path") call) would
  # fail these tests even though the 4 pre-existing-key tests above still pass.

  test "POST create for a Category Help Pages key redirects to its own public page" do
    tempfile = Tempfile.new(["upload", ".md"])
    tempfile.write("# Computers Help")
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", false,
                                          original_filename: "help_computers.md")

    assert_difference "SiteText.count", 1 do
      post admin_site_texts_path, params: { key: "help_computers", file: upload }
    end

    assert_redirected_to help_computers_path
    assert_equal "Computers Help was successfully updated.", flash[:notice]
  ensure
    tempfile&.unlink
  end

  test "url_for_key falls back to root_path for a key with no matching route" do
    tempfile = Tempfile.new(["upload", ".md"])
    tempfile.write("# Orphan")
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", false,
                                          original_filename: "orphan.md")

    # "orphan_key_with_no_route" is intentionally NOT in SiteText::KNOWN_TEXTS
    # and has no matching route — exercises the rescue NoMethodError branch.
    post admin_site_texts_path, params: { key: "orphan_key_with_no_route", file: upload }

    assert_redirected_to root_path
  ensure
    tempfile&.unlink
    SiteText.where(key: "orphan_key_with_no_route").destroy_all
  end

  # ── delete_confirm ───────────────────────────────────────────────────────────
  #
  # NOTE: this test verifies the page renders. It cannot verify that the Delete
  # link fires a DELETE request — that depends on Turbo JS and is only testable
  # via system tests (test/system/ — currently empty). The v1.0 bug (Delete link
  # inside a data-turbo="false" form causing a plain GET) was invisible here
  # because controller tests call routes directly without rendering JS behaviour.

  test "GET delete_confirm renders confirmation page" do
    get delete_confirm_admin_site_texts_path
    assert_response :success
  end

  # ── destroy ──────────────────────────────────────────────────────────────────

  test "DELETE destroy removes the SiteText record and redirects" do
    SiteText.create!(key: "readme", content: "# To be deleted")

    assert_difference "SiteText.count", -1 do
      delete admin_site_text_path("readme")
    end

    assert_redirected_to admin_owners_path
    assert_equal "Read Me was successfully deleted.", flash[:notice]
    assert_nil SiteText.for("readme")
  end

  test "DELETE destroy on missing key redirects with alert" do
    assert_no_difference "SiteText.count" do
      delete admin_site_text_path("nonexistent_key")
    end

    assert_redirected_to admin_owners_path
    assert flash[:alert].present?
  end

  # ── download_confirm ─────────────────────────────────────────────────────────

  test "GET download_confirm renders selector page" do
    get download_confirm_admin_site_texts_path
    assert_response :success
  end

  # ── download ─────────────────────────────────────────────────────────────────

  test "GET download sends stored content as a .md file attachment" do
    SiteText.create!(key: "readme", content: "# Stored readme content")

    get download_admin_site_text_path("readme")

    assert_response :success
    # Verify the response is sent as an attachment (browser saves, not displays).
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.headers["Content-Disposition"], "readme.md"
    # Verify content type includes text/markdown.
    assert_includes response.media_type, "text/markdown"
    # Verify the actual stored content is in the body.
    assert_equal "# Stored readme content", response.body
  end

  test "GET download on missing key redirects to download_confirm with alert" do
    # Ensure the key has no record (teardown handles cleanup, but be explicit).
    SiteText.where(key: "readme").destroy_all

    get download_admin_site_text_path("readme")

    assert_redirected_to download_confirm_admin_site_texts_path
    assert flash[:alert].present?
  end

  # ── authentication guard ─────────────────────────────────────────────────────

  test "all actions require admin" do
    # Admin::BaseController uses require_admin (not require_login).
    # require_admin checks admin? — false for both non-admins and logged-out users.
    # Both cases redirect to root_path, not new_session_path.
    delete session_path
    get new_admin_site_text_path
    assert_redirected_to root_path
  end
end
