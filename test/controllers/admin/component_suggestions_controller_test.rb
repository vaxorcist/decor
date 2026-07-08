# decor/test/controllers/admin/component_suggestions_controller_test.rb
# version 1.1
# Session 67: Phase 4 additions.
#   - create now sets manual: "added" — added tests confirming this and that
#     the field cannot be spoofed via a raw form param (not in strong params).
#   - update promotes manual from nil to "modified" on first edit, but never
#     overwrites an existing "added" or "modified" value on further edits —
#     added three tests covering all three starting states.
#   - New action download_manual — added tests for CSV content (only manual
#     rows) and the admin-only auth guard.
#   - index is now filterable — added tests for the query (substring) and
#     manual filters. Assertions use assert_select on rendered <td> content
#     rather than asserting on @page directly (Rails 8 controller tests have
#     no instance-variable access — see RAILS_SPECIFICS.md "Rails Version
#     Compatibility").
#
# Session 63: Phase 1 of Component Suggestions feature.
#
# Full CRUD + auth coverage for Admin::ComponentSuggestionsController.
# Pattern: mirrors admin/software_names_controller_test.rb.
#
# Key difference from SoftwareNamesController:
#   ComponentSuggestion has no dependents — destroy always succeeds.
#   There is no restrict_with_error guard to test.
#
# Fixtures used:
#   component_suggestions(:delqa)  — used for duplicate-name tests and
#                                    as the primary record under test.
#                                    manual: nil (untouched bulk-import row).
#   A freshly-created ComponentSuggestion is used for the destroy test and
#   for all manual-flag / filter tests (fixtures are never manual-flagged).

require "test_helper"

module Admin
  class ComponentSuggestionsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin      = owners(:one)
      @suggestion = component_suggestions(:delqa)
    end

    # ── Index ────────────────────────────────────────────────────────────────

    test "index displays component suggestions" do
      login_as(@admin)

      get admin_component_suggestions_url

      assert_response :success
      assert_select "h1", "Component Suggestions"
      assert_select "td", @suggestion.order_number
    end

    test "index filters by order_number substring" do
      login_as(@admin)
      match    = ComponentSuggestion.create!(order_number: "FILTER-MATCH-XYZ")
      no_match = ComponentSuggestion.create!(order_number: "COMPLETELY-DIFFERENT")

      get admin_component_suggestions_url, params: { query: "MATCH-XYZ" }

      assert_response :success
      assert_body_includes match.order_number
      refute_body_includes no_match.order_number
    end

    test "index filters by manual flag" do
      login_as(@admin)
      added_row = ComponentSuggestion.create!(order_number: "FILTER-ADDED-ROW", manual: "added")
      # @suggestion (fixture delqa) has manual: nil — must be excluded when filtering to "added"

      get admin_component_suggestions_url, params: { manual: "added" }

      assert_response :success
      assert_body_includes added_row.order_number
      refute_body_includes @suggestion.order_number
    end

    test "index with no filters shows all rows regardless of manual flag" do
      login_as(@admin)
      added_row = ComponentSuggestion.create!(order_number: "NO-FILTER-ADDED", manual: "added")

      get admin_component_suggestions_url

      assert_response :success
      assert_body_includes added_row.order_number
      assert_body_includes @suggestion.order_number
    end

    # ── New ──────────────────────────────────────────────────────────────────

    test "new displays form" do
      login_as(@admin)

      get new_admin_component_suggestion_url

      assert_response :success
      assert_select "h1", "New Component Suggestion"
      assert_select "input[name='component_suggestion[order_number]']"
    end

    # ── Create ───────────────────────────────────────────────────────────────

    test "create adds new component suggestion with all fields" do
      login_as(@admin)

      assert_difference "ComponentSuggestion.count", 1 do
        post admin_component_suggestions_url, params: {
          component_suggestion: {
            order_number: "DEQNA",
            description:  "DEQNA Ethernet Controller",
            category:     "Option"
          }
        }
      end

      assert_redirected_to admin_component_suggestions_path
      assert_match(/successfully created/i, flash[:notice])
    end

    test "create adds new suggestion without optional fields" do
      login_as(@admin)

      assert_difference "ComponentSuggestion.count", 1 do
        post admin_component_suggestions_url, params: {
          component_suggestion: { order_number: "M7622" }
        }
      end

      assert_redirected_to admin_component_suggestions_path
    end

    test "create fails with blank order_number" do
      login_as(@admin)

      assert_no_difference "ComponentSuggestion.count" do
        post admin_component_suggestions_url, params: {
          component_suggestion: { order_number: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate order_number" do
      login_as(@admin)

      assert_no_difference "ComponentSuggestion.count" do
        post admin_component_suggestions_url, params: {
          component_suggestion: { order_number: @suggestion.order_number }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with order_number longer than 20 characters" do
      login_as(@admin)

      assert_no_difference "ComponentSuggestion.count" do
        post admin_component_suggestions_url, params: {
          component_suggestion: { order_number: "A" * 21 }
        }
      end

      assert_response :unprocessable_entity
    end

    # ── Create — manual flag (Session 67) ────────────────────────────────────

    test "create always sets manual to added" do
      login_as(@admin)

      post admin_component_suggestions_url, params: {
        component_suggestion: { order_number: "MANUAL-CREATE-001" }
      }

      suggestion = ComponentSuggestion.find_by!(order_number: "MANUAL-CREATE-001")
      assert suggestion.manual_added?
    end

    test "create ignores a manual param supplied in the request — not in strong params" do
      login_as(@admin)

      post admin_component_suggestions_url, params: {
        component_suggestion: { order_number: "MANUAL-SPOOF-001", manual: "modified" }
      }

      suggestion = ComponentSuggestion.find_by!(order_number: "MANUAL-SPOOF-001")
      assert suggestion.manual_added?, "manual must always be \"added\" on create, regardless of any submitted value"
    end

    # ── Edit ─────────────────────────────────────────────────────────────────

    test "edit displays form" do
      login_as(@admin)

      get edit_admin_component_suggestion_url(@suggestion)

      assert_response :success
      assert_select "h1", "Edit Component Suggestion"
      assert_select "input[value='#{@suggestion.order_number}']"
    end

    # ── Update ───────────────────────────────────────────────────────────────

    test "update changes order_number" do
      login_as(@admin)

      patch admin_component_suggestion_url(@suggestion), params: {
        component_suggestion: { order_number: "DELQA-NEW" }
      }

      assert_redirected_to admin_component_suggestions_path
      @suggestion.reload
      assert_equal "DELQA-NEW", @suggestion.order_number
    end

    test "update changes description" do
      login_as(@admin)

      patch admin_component_suggestion_url(@suggestion), params: {
        component_suggestion: {
          order_number: @suggestion.order_number,
          description:  "Updated description"
        }
      }

      assert_redirected_to admin_component_suggestions_path
      @suggestion.reload
      assert_equal "Updated description", @suggestion.description
    end

    test "update clears category" do
      login_as(@admin)

      patch admin_component_suggestion_url(@suggestion), params: {
        component_suggestion: {
          order_number: @suggestion.order_number,
          category:     ""
        }
      }

      assert_redirected_to admin_component_suggestions_path
      @suggestion.reload
      assert_nil @suggestion.category.presence
    end

    test "update fails with blank order_number" do
      login_as(@admin)
      original = @suggestion.order_number

      patch admin_component_suggestion_url(@suggestion), params: {
        component_suggestion: { order_number: "" }
      }

      assert_response :unprocessable_entity
      @suggestion.reload
      assert_equal original, @suggestion.order_number
    end

    test "update fails with duplicate order_number" do
      login_as(@admin)
      other = ComponentSuggestion.create!(order_number: "UNIQUE-ORD")

      patch admin_component_suggestion_url(other), params: {
        component_suggestion: { order_number: @suggestion.order_number }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "UNIQUE-ORD", other.order_number
    end

    # ── Update — manual flag (Session 67) ────────────────────────────────────

    test "update promotes an untouched row (manual: nil) to modified" do
      login_as(@admin)
      assert_nil @suggestion.manual, "fixture delqa must start as an untouched bulk-import row"

      patch admin_component_suggestion_url(@suggestion), params: {
        component_suggestion: { order_number: @suggestion.order_number, description: "Edited once" }
      }

      @suggestion.reload
      assert @suggestion.manual_modified?
    end

    test "update does not overwrite an already-added row back to modified" do
      login_as(@admin)
      added = ComponentSuggestion.create!(order_number: "MANUAL-STAYS-ADDED", manual: "added")

      patch admin_component_suggestion_url(added), params: {
        component_suggestion: { order_number: added.order_number, description: "Edited again" }
      }

      added.reload
      assert added.manual_added?, "an \"added\" row must remain \"added\" permanently, even after further edits"
    end

    test "update does not change an already-modified row's manual value" do
      login_as(@admin)
      modified = ComponentSuggestion.create!(order_number: "STAYS-MODIFIED-01", manual: "modified")

      patch admin_component_suggestion_url(modified), params: {
        component_suggestion: { order_number: modified.order_number, description: "Edited yet again" }
      }

      modified.reload
      assert modified.manual_modified?
    end

    # ── Destroy ───────────────────────────────────────────────────────────────
    # ComponentSuggestion has no dependents — destroy always succeeds.

    test "destroy deletes a component suggestion" do
      login_as(@admin)
      deletable = ComponentSuggestion.create!(order_number: "DELETE-ME")

      assert_difference "ComponentSuggestion.count", -1 do
        delete admin_component_suggestion_url(deletable)
      end

      assert_redirected_to admin_component_suggestions_path
      assert_match(/successfully deleted/i, flash[:notice])
    end

    # ── Download Manual Changes (Session 67, Phase 4 item 2) ──────────────────

    test "download_manual returns a CSV of only manually-flagged rows" do
      login_as(@admin)
      added_row = ComponentSuggestion.create!(order_number: "DL-MANUAL-ADDED", manual: "added")
      # @suggestion (fixture delqa) has manual: nil — must be excluded

      get download_manual_admin_component_suggestions_url

      assert_response :success
      assert_equal "text/csv", response.media_type
      assert_body_includes added_row.order_number
      refute_body_includes @suggestion.order_number
    end

    test "download_manual includes both added and modified rows together" do
      login_as(@admin)
      added_row    = ComponentSuggestion.create!(order_number: "DL-BOTH-ADDED", manual: "added")
      modified_row = ComponentSuggestion.create!(order_number: "DL-BOTH-MODIFIED", manual: "modified")

      get download_manual_admin_component_suggestions_url

      assert_response :success
      assert_body_includes added_row.order_number
      assert_body_includes modified_row.order_number
    end

    # ── Authorization ─────────────────────────────────────────────────────────

    test "non-admin cannot access component suggestions" do
      login_as(owners(:two))

      get admin_component_suggestions_url

      assert_redirected_to root_path
    end

    test "non-admin cannot access download_manual" do
      login_as(owners(:two))

      get download_manual_admin_component_suggestions_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage component suggestions" do
      non_admin = owners(:two)
      login_as(non_admin)

      get new_admin_component_suggestion_url
      assert_redirected_to root_path

      assert_no_difference "ComponentSuggestion.count" do
        post admin_component_suggestions_url, params: {
          component_suggestion: { order_number: "BLOCKED" }
        }
      end
      assert_redirected_to root_path

      get edit_admin_component_suggestion_url(@suggestion)
      assert_redirected_to root_path

      patch admin_component_suggestion_url(@suggestion), params: {
        component_suggestion: { order_number: "BLOCKED" }
      }
      assert_redirected_to root_path

      assert_no_difference "ComponentSuggestion.count" do
        delete admin_component_suggestion_url(@suggestion)
      end
      assert_redirected_to root_path
    end
  end
end
