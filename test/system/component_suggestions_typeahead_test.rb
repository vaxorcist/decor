# decor/test/system/component_suggestions_typeahead_test.rb
# version 1.0
# v1.0 (Session 64): Component Suggestions Phase 2.
#   System tests for the order_number typeahead (component_suggestion_controller.js).
#   Controller tests (component_suggestions_controller_test.rb) already cover the
#   JSON endpoint itself; these tests cover behaviour that only exists client-side
#   and cannot be verified without a real browser: debounced fetch triggering,
#   auto-accept on a single match, and keyboard navigation across multiple matches.
#
#   Fixtures used: component_suggestions.yml (delqa, m7516, pcb_assembly, rev_a3_rom).
#   None of the four fixture order_numbers share a common prefix, so the
#   multi-match keyboard nav test creates two extra ComponentSuggestion records
#   locally inside that test rather than editing the shared fixture file — this
#   avoids disturbing row-count assertions in ComponentSuggestionExportServiceTest
#   and similar tests that depend on the fixture file's exact contents.
#
#   Both tests visit new_component_path while signed in (component creation
#   requires login — see ComponentsController#new / Current.owner.components.new).
#
#   Wait strategy: page.has_css?(..., wait: 5) / has_field?(..., wait: 5) is used
#   throughout, matching the convention established in components_filters_test.rb,
#   to tolerate the controller's 250ms debounce plus the network round trip to
#   the JSON endpoint.

require "application_system_test_case"

class ComponentSuggestionsTypeaheadTest < ApplicationSystemTestCase
  test "typing a prefix matching exactly one suggestion auto-fills and moves focus to serial number" do
    sign_in owners(:one)
    visit new_component_path

    # "M75" matches only the m7516 fixture (order_number "M7516") — no other
    # fixture order_number starts with that prefix.
    fill_in "component_order_number", with: "M75"

    # Auto-accept fills description and focuses serial_number once the single
    # match is confirmed; wait for description to populate as the signal that
    # the debounced fetch + accept cycle has completed.
    assert page.has_field?("component_description", with: "DELQA Module", wait: 5),
      "Description should auto-fill from the single matching suggestion"

    assert page.has_field?("component_order_number", with: "M7516", wait: 5),
      "Order number should be completed to the full matched value"

    assert_equal "true", find("input[name='component[order_number_verified]']", visible: false).value,
      "order_number_verified hidden field should be set to true after auto-accept"

    assert_equal "component_serial_number", page.evaluate_script("document.activeElement.id"),
      "Focus should move to the serial number field after accepting a suggestion"
  end

  test "keyboard navigation selects the correct suggestion among multiple matches" do
    # Two extra records sharing a "KEY-" prefix, created locally so the shared
    # fixture file (and tests that depend on its exact row count) are untouched.
    ComponentSuggestion.create!(order_number: "KEY-100", description: "First match",  category: "Test")
    ComponentSuggestion.create!(order_number: "KEY-200", description: "Second match", category: "Test")

    sign_in owners(:one)
    visit new_component_path

    fill_in "component_order_number", with: "KEY-"

    # Wait for the dropdown to render both options before navigating.
    assert page.has_css?("[data-component-suggestion-target='dropdown'] li", minimum: 2, wait: 5),
      "Dropdown should list both KEY- prefixed suggestions"

    order_number_field = find_field("component_order_number")
    # The controller highlights index 0 (KEY-100) immediately after rendering
    # the dropdown, so a single ArrowDown moves the highlight to index 1
    # (KEY-200) — see component_suggestion_controller.js _fetchSuggestions(),
    # which calls _setHighlight(0) right after _renderDropdown().
    order_number_field.send_keys(:down)  # move highlight from KEY-100 to KEY-200
    order_number_field.send_keys(:enter) # accept highlighted item

    assert page.has_field?("component_order_number", with: "KEY-200", wait: 5),
      "Order number should be filled with the second (KEY-200) suggestion after ArrowDown + Enter"
    assert page.has_field?("component_description", with: "Second match", wait: 5),
      "Description should match the second suggestion, confirming correct keyboard selection"
  end
end
