# decor/test/controllers/admin/site_texts_controller_test.rb
# version 1.0
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
    SiteText.where(key: %w[readme news test_upload_key]).destroy_all
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

  # ── delete_confirm ───────────────────────────────────────────────────────────

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
