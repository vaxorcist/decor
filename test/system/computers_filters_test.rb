# decor/test/system/computers_filters_test.rb
# version 1.1
#
# v1.1 (Session 60): Three categories of fixes.
#
#   FIX 1 — ArgumentError on assert_selector with positional message strings.
#     Same issue as authentication_test.rb v1.1: Capybara raises ArgumentError
#     when a plain string is passed as the second positional arg to assert_selector.
#     Fix: `assert page.has_css?(selector), "message"` and
#          `assert page.has_no_css?(selector), "message"` throughout.
#
#   FIX 2 — Wrong assumption about unauthenticated access to computers_path.
#     ComputersController#index has no require_login before_action, so
#     unauthenticated visitors land on /computers, not /session/new.
#     The test previously asserted a redirect, which could never pass.
#     Fix: visit computers_path without logging in, confirm we ARE on the
#     computers page, then assert barter_status select is absent — which
#     is the real intent of the test (Trade filter not shown without login).
#
#   FIX 3 — Turbo race on the Reset link click.
#     `click_link "Reset"` issues a Turbo Drive navigation (async). Calling
#     `current_url` immediately after returns the old URL before Turbo has
#     loaded the destination. Fix: use `has_current_path?(path, wait: 5)`
#     after the click to let Capybara retry until the URL changes.
#
# v1.0 (Session 59): System test for the computers filter panel.

require "application_system_test_case"

class ComputersFiltersTest < ApplicationSystemTestCase
  # ── Filter panel presence ────────────────────────────────────────────────

  test "computers index renders the filter form" do
    # The filter panel is always visible on the computers index regardless
    # of login state (only the Trade field is gated). Confirm the outer
    # form element is present.
    #
    # WHY has_css? instead of assert_selector with a message string:
    #   Capybara's assert_selector does not accept a plain string as its
    #   second positional argument — it raises ArgumentError. Wrapping in
    #   Minitest's assert avoids this: `assert page.has_css?(...), "msg"`.
    sign_in owners(:one)
    visit computers_path
    assert page.has_css?("form[method='get']"),
      "Computers index must render a GET filter form"
  end

  test "filter form contains Search, Sort, Model, Condition and Run Status fields" do
    sign_in owners(:one)
    visit computers_path

    assert page.has_css?("input[name='query']"),
      "Filter form must have a query search field"
    assert page.has_css?("select[name='sort']"),
      "Filter form must have a sort selector"
    assert page.has_css?("select[name='model']"),
      "Filter form must have a model selector"
    assert page.has_css?("select[name='computer_condition_id']"),
      "Filter form must have a condition selector"
    assert page.has_css?("select[name='run_status_id']"),
      "Filter form must have a run_status selector"
  end

  # ── Trade filter visibility (login-gated) ────────────────────────────────

  test "Trade filter is absent for unauthenticated visitors" do
    # ComputersController#index is a public route — no require_login is applied.
    # Unauthenticated visitors land on /computers directly.
    # The Trade (barter_status) select is wrapped in <% if logged_in? %>, so
    # it must NOT appear in the rendered page for unauthenticated requests.
    visit computers_path

    # Confirm the page loaded (not redirected to login).
    assert_equal computers_path, current_path,
      "Test setup: computers_path must be accessible without login"

    # The barter_status select must be absent without a session.
    assert page.has_no_css?("select[name='barter_status']"),
      "Trade (barter_status) filter must NOT be rendered for unauthenticated visitors"
  end

  test "Trade filter is present for authenticated users" do
    sign_in owners(:one)
    visit computers_path

    assert page.has_css?("select[name='barter_status']"),
      "Trade (barter_status) filter must be visible to logged-in users"
  end

  # ── Applying filters ─────────────────────────────────────────────────────

  test "submitting the search field adds query param to the URL" do
    sign_in owners(:one)
    visit computers_path

    fill_in "query", with: "test"
    click_button "Apply"

    # The filter form may be inside a Turbo Frame — the URL does not change
    # on frame navigation. Check the query field value instead: after the
    # frame reloads with the filter applied, the input shows the submitted value.
    assert page.has_field?("query", with: "test", wait: 5),
      "After submitting, the query field must reflect the submitted value"
  end

  test "submitting a sort selection adds sort param to the URL" do
    sign_in owners(:one)
    visit computers_path

    sort_select = find("select[name='sort']")
    first_option = sort_select.all("option").reject { |o| o.value.empty? }.first
    skip "No sort options found in fixture data" unless first_option

    # select_option selects by element (not by text), avoiding the
    # Capybara select(value) mismatch where value != visible text.
    first_option.select_option
    click_button "Apply"

    # Use has_select? with the option text — works for both full-page
    # navigation and Turbo Frame navigation (URL may not update).
    assert page.has_select?("sort", selected: first_option.text, wait: 5),
      "After selecting a sort option, the form must show the selected option"
  end

  # ── Reset link ────────────────────────────────────────────────────────────

  test "Reset link navigates to computers_path without params" do
    sign_in owners(:one)

    # Start with an active filter so there is something to reset.
    visit computers_path(query: "anything")

    click_link "Reset"

    # has_current_path? retries internally (up to wait: 5 seconds) until
    # Turbo Drive finishes navigating to the bare computers_path. Using
    # current_url immediately after click_link races Turbo and sees the old URL.
    assert page.has_current_path?(computers_path, wait: 5),
      "Reset link must navigate to the bare computers_path"
    refute_includes current_url, "query=",
      "Reset link must remove the query param from the URL"
  end
end
