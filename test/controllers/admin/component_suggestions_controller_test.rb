# decor/test/controllers/admin/component_suggestions_controller_test.rb
# version 1.0
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
#   A freshly-created ComponentSuggestion is used for the destroy test.

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

    # ── Authorization ─────────────────────────────────────────────────────────

    test "non-admin cannot access component suggestions" do
      login_as(owners(:two))

      get admin_component_suggestions_url

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
