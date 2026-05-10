# decor/test/application_system_test_case.rb
# version 1.3
#
# v1.3 (Session 60): Fix sign_out — replaced brittle CSS selector with click_on.
#
#   The selector a[data-turbo-method='delete'][href='/session'] assumed the
#   sign-out is rendered as a link_to with data-turbo-method. The app uses
#   button_to instead, which renders a <form><button> pair — no <a> tag,
#   so the CSS selector always raises ElementNotFound.
#   Fix: click_on "Sign out" matches any clickable element (link or button)
#   by its visible text, regardless of the underlying HTML element type.
#
# v1.2 (Session 60): sign_in waits for Turbo navigation via has_no_field?.
# v1.1 (Session 59): Added browser-based sign_in / sign_out helpers.

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  parallelize(workers: 1)

  fixtures :all

  include AuthenticationHelper

  # ── Browser login helper ────────────────────────────────────────────────

  def sign_in(owner, password: nil)
    password ||= case owner.user_name
    when "alice"   then TEST_PASSWORD_ALICE
    when "bob"     then TEST_PASSWORD_BOB
    when "charlie" then "DecorTest2026!"
    else                TEST_PASSWORD_VALID
    end

    visit new_session_path
    fill_in "user_name", with: owner.user_name
    fill_in "password",  with: password
    find("[type=submit]").click

    # Wait for Turbo to finish navigating away from the login page before
    # returning. has_no_field? retries until the user_name field disappears
    # (new page loaded) or the 5-second timeout expires.
    has_no_field?("user_name", wait: 5)
  end

  # ── Browser logout helper ───────────────────────────────────────────────

  def sign_out
    # click_on matches both <a> and <button> elements by visible text,
    # so it works regardless of whether the app uses link_to or button_to
    # for the sign-out action.
    click_on "Sign out"

    # Wait for the sign-out navigation to complete.
    has_no_text?("Sign out", wait: 5)
  end
end
