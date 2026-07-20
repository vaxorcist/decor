# decor/test/controllers/site_texts_controller_test.rb
# version 1.0
# v1.0 (Session 73): New file. This controller (app/controllers/
#   site_texts_controller.rb) had no test coverage at all before this session
#   — flagged per PROGRAMMING_GENERAL.md's mandatory "Test Coverage Check"
#   while fixing a real bug in it (see site_texts_controller.rb v1.1
#   changelog: the controller's own private title_for_key was stale and
#   never delegated to SiteText.title_for_key after Session 20 established
#   that as the single source of truth).
#
# Covers:
#   show: renders successfully for a key with stored content, correct title
#         and content are rendered; renders "== Empty ==" placeholder for a
#         key with no stored SiteText record yet; title is correct for BOTH
#         a pre-existing key (privacy) AND one of the 5 new Category Help
#         Pages keys (help_computers) — the help_computers case is the one
#         that would have failed under the old buggy title_for_key, since
#         "help_computers".titleize gives "Help Computers", not the
#         configured "Computers Help".
#   No require_login — these pages are public; no login is performed here.
#
# No fixtures — SiteText records created inline and cleaned up in teardown.

require "test_helper"

class SiteTextsControllerTest < ActionDispatch::IntegrationTest
  def teardown
    SiteText.where(key: %w[privacy help_computers]).destroy_all
  end

  test "GET show renders stored content with the correct title" do
    SiteText.create!(key: "privacy", content: "# Privacy Policy\n\nWe respect your data.")

    get privacy_path

    assert_response :success
    assert_select "h1", "Privacy"
    assert_body_includes "Privacy Policy"
  end

  test "GET show renders the empty placeholder when no record exists yet" do
    # Ensure no record exists for this key.
    SiteText.where(key: "privacy").destroy_all

    get privacy_path

    assert_response :success
    assert_body_includes "== Empty =="
  end

  test "GET show uses SiteText.title_for_key, not a stale local mapping" do
    # Regression test for the Session 73 bug fix: this key's titleized form
    # ("Help Computers") does NOT match its configured KNOWN_TEXTS title
    # ("Computers Help") — proving the title comes from the actual
    # single source of truth, not a fallback .titleize.
    SiteText.create!(key: "help_computers", content: "# How to register a computer")

    get help_computers_path

    assert_response :success
    assert_select "h1", "Computers Help"
    refute_includes response.body, "<h1>Help Computers</h1>"
  end
end
