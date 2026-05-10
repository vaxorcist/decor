# decor/test/system/connection_groups_test.rb
# version 1.2
#
# v1.2 (Session 60): Two categories of fixes.
#
#   FIX 1 — ArgumentError on assert_selector with positional message strings.
#     v1.1 fixed the Ruby 3.4 SyntaxError (positional string after a keyword
#     arg, e.g. `visible: :all, "msg"`). But four tests still passed a plain
#     message string as the second positional argument to assert_selector
#     (e.g. `assert_selector "form[...]", "msg"`), which Capybara also rejects
#     with ArgumentError ("Unused parameters").
#     Fix: `assert page.has_css?(selector), "msg"` throughout those four tests.
#     assert_text is also converted to `assert page.has_text?` for consistency
#     and to guard against future Capybara signature changes.
#
#   FIX 2 — <template> element not findable via Capybara CSS selectors.
#     The form includes `<template data-connection-members-target="template">`.
#     HTML <template> elements are NOT part of the live document rendering tree
#     — their content lives in a DocumentFragment, not in the main DOM.
#     Selenium's element-finder (which powers Capybara assert_selector) cannot
#     locate them even with `visible: :all`. The element IS present as a DOM
#     node on the parent element, but not as a rendered child.
#     Fix: use evaluate_script to check for the element via
#     `document.querySelector(...)`, which CAN access <template> nodes on the
#     parent's children list (not its content fragment).
#
#   Note: several other tests that were ERRORing (Unable to find button
#     "Create connection", Unable to find css "[data-action=...]") were
#     secondary to the broken sign_in helper (Turbo navigation race). Those
#     errors are resolved by application_system_test_case.rb v1.2, which adds
#     a `has_no_field?("user_name", wait: 5)` wait after the submit click.
#
# v1.1 (Session 59): Fixed SyntaxError on 4 assert_selector calls where a
#   positional message string followed keyword arguments.
# v1.0 (Session 59): System test for the ConnectionGroup form's Stimulus controller.

require "application_system_test_case"

class ConnectionGroupsTest < ApplicationSystemTestCase
  # ── Form renders ──────────────────────────────────────────────────────────

  test "new connection group form renders the Stimulus controller wrapper" do
    # The outer <form> must carry data-controller="connection-members" so that
    # Stimulus attaches. If this attribute is absent, all JS port-management
    # behavior silently does nothing.
    #
    # WHY has_css? instead of assert_selector with a message string:
    #   Capybara's assert_selector raises ArgumentError on a second positional
    #   string argument. Using Minitest's assert with has_css? routes the
    #   message through Minitest instead.
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    assert page.has_css?("form[data-controller='connection-members']"),
      "Connection group form must have data-controller='connection-members'"
  end

  test "new connection group form renders the Add port button" do
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    assert page.has_css?("[data-action='click->connection-members#add']"),
      "Form must render the Add port button with the correct Stimulus action"
    assert page.has_text?("+ Add port"),
      "Add port button must be visible"
  end

  test "new connection group form renders the port list target" do
    # The Stimulus controller uses data-connection-members-target="membersList"
    # to locate the container for port rows. If this target is absent, the
    # add/remove JS cannot function.
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    assert page.has_css?("[data-connection-members-target='membersList']"),
      "Form must render the membersList Stimulus target"
  end

  test "new connection group form renders the template target" do
    # The <template> element holds the markup that is cloned for each new port.
    # data-connection-members-target="template" is how Stimulus finds it.
    #
    # WHY evaluate_script instead of assert_selector (even with visible: :all):
    #   HTML <template> elements are NOT part of the live document rendering
    #   tree. Their content lives in a DocumentFragment attached to the
    #   element, not as rendered DOM children. Selenium's element-finder
    #   (used by assert_selector and has_css?) cannot locate <template> nodes
    #   even with visible: :all — the flag only relaxes visibility filtering,
    #   it does not change how Selenium traverses the DOM.
    #
    #   document.querySelector CAN find <template> nodes because it operates
    #   on the full element tree (not just the rendered subtree). This is the
    #   only reliable way to assert the element's presence via Capybara/Selenium.
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    template_present = evaluate_script(
      "document.querySelector(\"[data-connection-members-target='template']\") !== null"
    )
    assert template_present,
      "Form must render the <template> element with data-connection-members-target='template'"
  end

  # ── Add port (Stimulus JS) ────────────────────────────────────────────────

  test "clicking Add port appends a new port row to the membersList" do
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    initial_count = all("[data-member-row]").count

    find("[data-action='click->connection-members#add']").click

    # Capybara automatically waits for the DOM to update (up to the
    # Capybara.default_max_wait_time, default 2s). The assertion will pass
    # as soon as a new [data-member-row] element appears.
    # NOTE: count: keyword arg — no trailing positional message (Ruby 3.4 fix).
    assert_selector "[data-member-row]", count: initial_count + 1
  end

  test "clicking Add port twice appends two new port rows" do
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    initial_count = all("[data-member-row]").count

    2.times { find("[data-action='click->connection-members#add']").click }

    # NOTE: count: keyword arg — no trailing positional message (Ruby 3.4 fix).
    assert_selector "[data-member-row]", count: initial_count + 2
  end

  test "new port row added by JS contains a device dropdown" do
    # The cloned template must include the device <select> so the user can
    # assign a device to the new port.
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    find("[data-action='click->connection-members#add']").click

    within all("[data-member-row]").last do
      assert page.has_css?("select[name*='computer_id']"),
        "New port row must contain a device (computer_id) dropdown"
    end
  end

  # ── Remove port (Stimulus JS) ─────────────────────────────────────────────

  test "clicking remove on a new port row removes it from the DOM" do
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    find("[data-action='click->connection-members#add']").click
    count_after_add = all("[data-member-row]").count

    within all("[data-member-row]").last do
      find("[data-action='click->connection-members#remove']").click
    end

    # NOTE: count: keyword arg — no trailing positional message (Ruby 3.4 fix).
    assert_selector "[data-member-row]", count: count_after_add - 1
  end

  # ── Connection ID field ───────────────────────────────────────────────────

  test "form renders the Connection ID (owner_group_id) number field" do
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    assert page.has_css?("input[name='connection_group[owner_group_id]'][type='number']"),
      "Form must render the Connection ID number input"
  end

  # ── Form submission: validation error path ────────────────────────────────

  test "submitting an empty connection group form shows validation errors" do
    sign_in owners(:one)
    visit new_owner_connection_group_path(owners(:one))

    # The submit button text is "Create connection" for new records
    # (form.submit uses connection_group.persisted? ? "Save connection" : "Create connection").
    click_button "Create connection"

    assert page.has_css?(".bg-red-50"),
      "Submitting an invalid connection group must render the validation error block"
    assert page.has_text?("error"),
      "Validation error block must mention 'error'"
  end
end
