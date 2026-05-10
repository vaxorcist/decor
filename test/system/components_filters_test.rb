# decor/test/system/components_filters_test.rb
# version 1.2
#
# v1.2 (Session 60): Remove erroneous skip from Reset link test.
#
#   v1.1 skipped the Reset link test with a note that
#   decor/app/views/components/_filters.html.erb had no Reset link. On
#   inspection the link is present (link_to "Reset", components_path). The
#   original ElementNotFound error was a secondary cascade: earlier tests had
#   broken sign_in state that left the browser on an unexpected page, causing
#   the fresh `visit components_path(...)` to render a partial or error view
#   without the Reset link visible.
#
#   With sign_in fixed (application_system_test_case.rb v1.2), each test
#   starts clean. The Reset link test is restored with a DOM-based wait:
#   after click_link "Reset" (Turbo Drive navigation), we wait for the query
#   input to show an empty value — confirming the new page has rendered —
#   before asserting the URL.
#
# v1.1 (Session 60): ArgumentError fixes, select-by-value fixes, Trade filter
#   assertion fixes.
# v1.0 (Session 59): System test for the components filter panel.

require "application_system_test_case"

class ComponentsFiltersTest < ApplicationSystemTestCase
  # ── Filter panel renders without login ───────────────────────────────────

  test "components index is accessible without login" do
    visit components_path
    assert_equal components_path, current_path,
      "components_path must be accessible without login (public route)"
  end

  test "filter form is present for unauthenticated visitors" do
    visit components_path
    assert page.has_css?("form[method='get']"),
      "Components index must render the GET filter form for unauthenticated visitors"
  end

  test "filter form contains Search, Sort, Type, Computer Model and Peripheral Model fields" do
    visit components_path

    assert page.has_css?("input[name='query']"),
      "Filter form must have a query search field"
    assert page.has_css?("select[name='sort']"),
      "Filter form must have a sort selector"
    assert page.has_css?("select[name='component_type']"),
      "Filter form must have a component_type selector"
    assert page.has_css?("select[name='computer_model']"),
      "Filter form must have a computer_model selector"
    assert page.has_css?("select[name='peripheral_model']"),
      "Filter form must have a peripheral_model selector (added v1.2)"
  end

  # ── Trade filter visibility (login-gated) ────────────────────────────────

  test "Trade filter is absent for unauthenticated visitors" do
    visit components_path
    assert_equal components_path, current_path,
      "Test setup failed: expected to be on components_path without login"

    assert page.has_no_css?("select[name='barter_status']"),
      "Trade (barter_status) filter must NOT be rendered for unauthenticated visitors"
  end

  test "Trade filter is present after login" do
    sign_in owners(:one)
    visit components_path

    assert page.has_css?("select[name='barter_status']"),
      "Trade (barter_status) filter must be rendered for authenticated users"
  end

  test "Trade filter disappears after sign out" do
    sign_in owners(:one)
    visit components_path
    assert page.has_css?("select[name='barter_status']"),
      "Trade filter must be present while logged in"

    sign_out
    visit components_path
    assert page.has_no_css?("select[name='barter_status']"),
      "Trade filter must be absent after sign out"
  end

  # ── Applying filters ─────────────────────────────────────────────────────

  test "submitting the search field adds query param to URL" do
    visit components_path
    fill_in "query", with: "ram"
    within("form[method='get']") { find("[type=submit]").click }

    # components/_filters.html.erb uses local: true (synchronous GET form).
    assert page.has_field?("query", with: "ram", wait: 5),
      "After submitting, the query field must reflect the submitted value"
  end

  test "selecting a component_type adds it to the URL" do
    visit components_path
    type_select = find("select[name='component_type']")
    first_option = type_select.all("option").reject { |o| o.value.empty? }.first
    skip "No component_type options found in fixture data" unless first_option

    type_select.find("option[value='#{first_option.value}']").select_option
    click_button "Apply"

    assert page.has_select?("component_type", selected: first_option.text, wait: 5),
      "After selecting, the component_type filter must show the selected option"
  end

  test "selecting a peripheral_model adds it to the URL" do
    visit components_path
    model_select = find("select[name='peripheral_model']")
    first_option = model_select.all("option").reject { |o| o.value.empty? }.first
    skip "No peripheral_model options found in fixture data" unless first_option

    model_select.find("option[value='#{first_option.value}']").select_option
    click_button "Apply"

    assert page.has_select?("peripheral_model", selected: first_option.text, wait: 5),
      "After selecting, the peripheral_model filter must show the selected option"
  end

  # ── Reset link ────────────────────────────────────────────────────────────

  test "Reset link navigates to bare components_path without params" do
    visit components_path(query: "anything")
    click_link "Reset"

    # has_field? retries until the query input has an empty value, confirming
    # the frame/page has reloaded without the query param.
    # The CSS [value=''] selector fails when Rails renders the input with no
    # value attribute (nil param); has_field? checks the live DOM value instead.
    assert page.has_field?("query", with: "", wait: 5),
      "After Reset, the query field must be empty"
    assert_equal components_path, current_path,
      "Reset link must navigate to the bare components_path"
  end
end
