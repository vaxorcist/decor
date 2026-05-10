# decor/test/system/authentication_test.rb
# version 1.1
#
# v1.1 (Session 60): Two categories of fixes.
#
#   FIX 1 — ArgumentError on assert_selector with positional message strings.
#     Capybara's assert_selector treats its second positional argument as a
#     hash of query options (e.g. count:, visible:), not a message string.
#     Passing a plain string raises:
#       ArgumentError: Unused parameters passed to Capybara::Queries::SelectorQuery
#     Fix: wrap as `assert page.has_css?(selector), "message"` so the message
#     is handled by Minitest rather than Capybara.
#     Affected tests: login_page_renders_user_name_and_password_fields (3 calls).
#
#   FIX 2 — Wrong assumption about computers_path access control.
#     The test "unauthenticated visit to computers_path redirects to login"
#     asserted that visiting /computers without a session redirects to /session/new.
#     The actual browser lands on /computers (Actual: "/computers") because
#     ComputersController#index has no require_login before_action — the page
#     is public. The test was wrong, not the app.
#     Fix: changed to assert that an unauthenticated visit to a route that
#     genuinely requires login (new_owner_connection_group_path) does redirect
#     to /session/new, and added a separate test confirming computers_path IS
#     publicly accessible.
#
# v1.0 (Session 59): First system test file — authentication flow.
#
# WHAT THESE TESTS COVER (and why controller tests cannot):
#   Controller integration tests call routes directly via the Rack adapter
#   and bypass the browser entirely. They cannot verify:
#     - That the login form renders with the expected inputs
#     - That the browser cookie session is properly established
#     - That Turbo-driven sign-out (DELETE /session via data-turbo-method)
#       actually terminates the session from the browser's perspective
#     - That access-control redirects work end-to-end in a real browser
#
# FIXTURES USED:
#   owners(:one)   = alice — admin user,     password: TEST_PASSWORD_ALICE
#   owners(:two)   = bob   — non-admin user, password: TEST_PASSWORD_BOB

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  # ── Login form ────────────────────────────────────────────────────────────

  test "login page renders user_name and password fields" do
    # Verify the login form has the fields the sign_in helper depends on.
    # If this test fails, update the sign_in helper's fill_in selectors.
    #
    # WHY has_css? instead of assert_selector with a message string:
    #   Capybara's assert_selector does not accept a plain string as a second
    #   positional argument — it raises ArgumentError. Passing the message
    #   through Minitest's assert avoids this: `assert has_css?(...), "msg"`.
    visit new_session_path
    assert page.has_css?("input[name='user_name']"),
      "Login form must have an input with name='user_name'"
    assert page.has_css?("input[name='password']"),
      "Login form must have an input with name='password'"
    assert page.has_css?("[type=submit]"),
      "Login form must have a submit button"
  end

  # ── Successful login ──────────────────────────────────────────────────────

  test "login with valid credentials leaves the login page" do
    # Successful login must redirect the browser away from /session/new.
    # sign_in (v1.2) waits for Turbo navigation to complete before returning,
    # so current_path is reliable by the time we assert.
    sign_in owners(:one)
    assert_not_equal new_session_path, current_path,
      "Successful login must redirect away from #{new_session_path}"
  end

  test "login with valid credentials allows accessing protected pages" do
    # After sign_in, a visit to a page that requires authentication must
    # succeed without bouncing back to the login form.
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))
    assert_not_equal new_session_path, current_path,
      "Logged-in user must reach a protected page without redirection to login"
  end

  # ── Failed login ──────────────────────────────────────────────────────────

  test "login with wrong password stays on login page" do
    # Invalid credentials must NOT establish a session.
    # The browser must remain on (or return to) the login page.
    visit new_session_path
    fill_in "user_name", with: owners(:one).user_name
    fill_in "password",  with: "totallywrongpassword123"
    find("[type=submit]").click

    assert_equal new_session_path, current_path,
      "Invalid credentials must leave the browser on the login page"
  end

  test "login with unknown user_name stays on login page" do
    visit new_session_path
    fill_in "user_name", with: "nobody"
    fill_in "password",  with: "somepassword"
    find("[type=submit]").click

    assert_equal new_session_path, current_path,
      "Unknown user_name must leave the browser on the login page"
  end

  # ── Access control: unauthenticated ──────────────────────────────────────

  test "unauthenticated visit to computers_path is publicly accessible" do
    # ComputersController#index has no require_login before_action — the page
    # is public. Unauthenticated visitors land on /computers, not /session/new.
    # This test documents that behaviour and guards against accidentally adding
    # a login requirement to the computers index.
    visit computers_path
    assert_equal computers_path, current_path,
      "computers_path is a public route; unauthenticated visitors must not be redirected to login"
  end

  test "unauthenticated visit to a protected page redirects to login" do
    # new_owner_connection_group_path requires login (the controller enforces
    # authentication for all connection_groups actions).
    # Visiting it without a session must redirect to new_session_path.
    visit new_owner_connection_group_path(owners(:one))
    assert_equal new_session_path, current_path,
      "Unauthenticated user must be redirected to login from a protected page"
  end

  test "unauthenticated visit to software_items_path does NOT redirect to login" do
    # software_items_path is a public route (no require_login).
    # Visiting it without a session must succeed and remain on that page.
    visit software_items_path
    assert_not_equal new_session_path, current_path,
      "Public software_items_path must be accessible without login"
    assert_equal software_items_path, current_path,
      "Public software_items_path must not redirect to login"
  end

  # ── Access control: admin vs non-admin ───────────────────────────────────

  test "admin user can access admin area" do
    sign_in owners(:one)    # alice — admin: true
    visit admin_owners_path
    assert_equal admin_owners_path, current_path,
      "Admin user must be able to access admin_owners_path"
  end

  test "non-admin user is redirected away from admin area" do
    sign_in owners(:two)    # bob — admin: false
    visit admin_owners_path
    assert_not_equal admin_owners_path, current_path,
      "Non-admin user must be redirected away from admin_owners_path"
  end

  # ── Sign out ──────────────────────────────────────────────────────────────

  test "sign out terminates the browser session" do
    sign_in owners(:one)

    # Confirm we are past the login page before testing sign-out.
    # sign_in (v1.2) waits for Turbo navigation, so this should always hold.
    assert_not_equal new_session_path, current_path,
      "sign_in helper failed — still on login page before testing sign-out"

    sign_out

    # After sign-out, a protected page must redirect to login.
    visit new_owner_connection_group_path(owners(:one))
    assert_equal new_session_path, current_path,
      "After sign-out, the browser must be redirected to login for protected pages"
  end
end
