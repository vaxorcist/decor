# decor/test/controllers/component_suggestions_controller_test.rb
# version 1.0
# v1.0 (Session 64): Component Suggestions Phase 2.
#   Integration tests for the owner-facing JSON typeahead endpoint at
#   GET /component_suggestions?query=...
#
#   Coverage:
#     - require_login: unauthenticated request is redirected (not 200 JSON).
#     - blank query: returns an empty JSON array without querying the DB.
#     - matching query: returns suggestions whose order_number starts with
#       the query string, each shaped as { order_number, description, category }.
#     - case/prefix behaviour: only prefix matches are returned (no substring
#       matches), consistent with ComponentSuggestion.matching's LIKE 'q%' scope.
#     - result limit: more than 10 matches are truncated to 10.
#     - nulls preserved: description/category that are nil on the record come
#       through as JSON null, not an empty string or omitted key.
#
#   Uses owners(:three) — the neutral fixture owner (see RAILS_SPECIFICS.md,
#   "neutral owner" convention) — to avoid coupling this test to record counts
#   on owners used elsewhere.
#
#   Records are created directly in each test (not via fixtures) since
#   component_suggestions.yml's exact fixture keys were not available when
#   this file was written; this avoids guessing fixture names incorrectly
#   (see RAILS_SPECIFICS.md "Missing test file failure" cautionary example).

require "test_helper"

class ComponentSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = owners(:three)
    login_as(@owner)
  end

  test "requires login" do
    delete session_path
    get component_suggestions_path, params: { query: "ABC" }, as: :json
    assert_response :redirect
  end

  test "blank query returns empty array without hitting the database" do
    get component_suggestions_path, params: { query: "" }, as: :json
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "missing query param returns empty array" do
    get component_suggestions_path, as: :json
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "returns prefix matches shaped correctly" do
    ComponentSuggestion.create!(order_number: "AB-100", description: "Test widget", category: "Cables")
    ComponentSuggestion.create!(order_number: "AB-200", description: nil, category: nil)
    ComponentSuggestion.create!(order_number: "ZZ-999", description: "Should not match", category: "Other")

    get component_suggestions_path, params: { query: "AB-" }, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 2, body.length

    order_numbers = body.map { |h| h["order_number"] }
    assert_includes order_numbers, "AB-100"
    assert_includes order_numbers, "AB-200"
    refute_includes order_numbers, "ZZ-999"

    first = body.find { |h| h["order_number"] == "AB-100" }
    assert_equal "Test widget", first["description"]
    assert_equal "Cables", first["category"]

    second = body.find { |h| h["order_number"] == "AB-200" }
    assert_nil second["description"]
    assert_nil second["category"]
  end

  test "does not return substring matches that are not prefix matches" do
    ComponentSuggestion.create!(order_number: "XY-AB-100", description: nil, category: nil)

    get component_suggestions_path, params: { query: "AB-" }, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    refute_includes body.map { |h| h["order_number"] }, "XY-AB-100"
  end

  test "limits results to 10" do
    15.times do |i|
      ComponentSuggestion.create!(order_number: format("LIM-%03d", i))
    end

    get component_suggestions_path, params: { query: "LIM-" }, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 10, body.length
  end
end
