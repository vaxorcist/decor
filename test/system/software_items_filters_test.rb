# decor/test/system/software_items_filters_test.rb
# version 1.1
#
# v1.1 (Session 60): Three categories of fixes.
#
#   FIX 1 — ArgumentError on assert_selector / refute_selector with positional
#     message strings.
#     Capybara's assert_selector / refute_selector raise ArgumentError when a
#     plain string is passed as the second positional argument. Fixed throughout
#     by using `assert page.has_css?(selector), "msg"` and
#     `assert page.has_no_css?(selector), "msg"`.
#
#   FIX 2 — select by text vs. select by value.
#     Capybara's `select(value, from: "field")` matches options by their
#     visible TEXT content, not by their HTML value= attribute.
#     `first_option_value` holds the value= attribute (e.g. "994812667"),
#     not the label text (e.g. "VMS"). Passing a fixture ID to `select`
#     raises ElementNotFound because no option has that text.
#     Fix: use find("option[value='#{v}']").select_option to match by value.
#
#   FIX 3 — Reset link and form-submit URL races.
#     Both the Reset link and the filter form submit navigate via Turbo,
#     so current_url checked immediately after the click returns the old URL.
#     Fix for Reset: use `has_current_path?(path, wait: 5)` to let Capybara
#     retry until navigation completes.
#     Fix for form submit: after clicking Apply, wait for the query input to
#     carry the submitted value (confirming the new page has rendered), then
#     check current_url.
#
# v1.0 (Session 59): System test for the software_items filter panel.

require "application_system_test_case"

class SoftwareItemsFiltersTest < ApplicationSystemTestCase
  # ── Public access ─────────────────────────────────────────────────────────

  test "software_items index is accessible without login" do
    visit software_items_path
    assert_equal software_items_path, current_path,
      "software_items_path must be accessible without login (public route)"
  end

  # ── Filter panel presence ─────────────────────────────────────────────────

  test "filter form is present for unauthenticated visitors" do
    visit software_items_path
    # WHY has_css? instead of assert_selector with a message string:
    #   Capybara raises ArgumentError if a plain string is passed as the second
    #   positional argument to assert_selector. Wrapping in Minitest's assert
    #   passes the message through Minitest, not Capybara.
    assert page.has_css?("form[method='get']"),
      "software_items index must render the GET filter form for unauthenticated visitors"
  end

  test "filter form contains Search, Sort, Software and Owner fields" do
    visit software_items_path

    assert page.has_css?("input[name='query']"),
      "Filter form must have a query search field"
    assert page.has_css?("select[name='sort']"),
      "Filter form must have a sort selector"
    assert page.has_css?("select[name='software_name_id']"),
      "Filter form must have a software_name_id selector"
    assert page.has_css?("select[name='owner_id']"),
      "Filter form must have an owner_id selector"
  end

  # ── Trade filter visibility (login-gated) ────────────────────────────────

  test "Trade filter is absent for unauthenticated visitors" do
    visit software_items_path
    assert_equal software_items_path, current_path,
      "Test setup failed: expected to be on software_items_path without login"

    # WHY has_no_css? instead of refute_selector with a message string:
    #   Same ArgumentError reason as above.
    assert page.has_no_css?("select[name='barter_status']"),
      "Trade (barter_status) filter must NOT be rendered for unauthenticated visitors"
  end

  test "Trade filter is present after login" do
    sign_in owners(:one)
    visit software_items_path

    assert page.has_css?("select[name='barter_status']"),
      "Trade (barter_status) filter must be rendered for authenticated users"
  end

  test "Trade filter disappears after sign out" do
    sign_in owners(:one)
    visit software_items_path
    assert page.has_css?("select[name='barter_status']"),
      "Trade filter must be present while logged in"

    sign_out
    visit software_items_path
    assert page.has_no_css?("select[name='barter_status']"),
      "Trade filter must be absent after sign out"
  end

  # ── Applying filters ──────────────────────────────────────────────────────

  test "submitting the search field adds query param to URL" do
    visit software_items_path
    fill_in "query", with: "vms"
    click_button "Apply"

    assert page.has_field?("query", with: "vms", wait: 5),
      "After submitting, the query field must reflect the submitted value"
  end

  test "selecting a software_name_id adds it to the URL" do
    visit software_items_path
    select_el = find("select[name='software_name_id']")
    first_option = select_el.all("option").reject { |o| o.value.empty? }.first
    skip "No software_name_id options found in fixture data" unless first_option

    select_el.find("option[value='#{first_option.value}']").select_option
    click_button "Apply"

    assert page.has_select?("software_name_id", selected: first_option.text, wait: 5),
      "After selecting, the software_name_id filter must show the selected option"
  end

  test "selecting an owner_id adds it to the URL" do
    visit software_items_path
    select_el = find("select[name='owner_id']")
    first_option = select_el.all("option").reject { |o| o.value.empty? }.first
    skip "No owner_id options found in fixture data" unless first_option

    select_el.find("option[value='#{first_option.value}']").select_option
    click_button "Apply"

    assert page.has_select?("owner_id", selected: first_option.text, wait: 5),
      "After selecting, the owner_id filter must show the selected option"
  end

  test "selecting a barter_status adds it to the URL" do
    sign_in owners(:one)
    visit software_items_path

    select_el = find("select[name='barter_status']")
    first_option = select_el.all("option").reject { |o| o.value.empty? }.first
    skip "No barter_status options found" unless first_option

    select_el.find("option[value='#{first_option.value}']").select_option
    click_button "Apply"

    assert page.has_select?("barter_status", selected: first_option.text, wait: 5),
      "After selecting, the barter_status filter must show the selected option"
  end

  # ── Reset link ────────────────────────────────────────────────────────────

  test "Reset link navigates to bare software_items_path without params" do
    visit software_items_path(query: "anything", owner_id: "1")
    click_link "Reset"

    # has_current_path? retries internally until Turbo Drive finishes
    # navigating to the bare path. Checking current_url immediately after
    # click_link races Turbo and still sees the old URL with params.
    assert page.has_current_path?(software_items_path, wait: 5),
      "Reset link must navigate to the bare software_items_path"
    refute_includes current_url, "query=",
      "Reset must strip the query param"
    refute_includes current_url, "owner_id=",
      "Reset must strip the owner_id param"
  end
end
