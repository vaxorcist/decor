# decor/test/controllers/admin/component_conditions_controller_test.rb
# version 1.0
# Full CRUD + authorization tests for Admin::ComponentConditionsController.
#
# Key differences from conditions_controller_test:
#   - Fixtures: component_conditions(:working) / (:defective)
#   - Column is :condition (not :name) — params use component_condition[condition]
#   - Route helpers: admin_component_conditions_url / admin_component_condition_url
#   - Destroy-blocked test: assigns a component_condition to an existing component
#     programmatically (no fixture has component_condition set by default)
#   - Destroy failure redirects with alert (not a 422) — the controller handles
#     restrict_with_error gracefully rather than raising

require "test_helper"

module Admin
  class ComponentConditionsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = owners(:one)
      @component_condition = component_conditions(:working)
    end

    # Index
    test "index displays component conditions" do
      login_as(@admin)

      get admin_component_conditions_url

      assert_response :success
      assert_select "h1", "Component Conditions"
      assert_select "td", @component_condition.condition
    end

    # New
    test "new displays form" do
      login_as(@admin)

      get new_admin_component_condition_url

      assert_response :success
      assert_select "h1", "New Component Condition"
      assert_select "input[name='component_condition[condition]']"
    end

    # Create
    test "create adds new component condition" do
      login_as(@admin)

      assert_difference "ComponentCondition.count", 1 do
        post admin_component_conditions_url, params: {
          component_condition: { condition: "For Parts" }
        }
      end

      assert_redirected_to admin_component_conditions_path
      assert_match(/successfully created/i, flash[:notice])
    end

    test "create fails with blank condition" do
      login_as(@admin)

      assert_no_difference "ComponentCondition.count" do
        post admin_component_conditions_url, params: {
          component_condition: { condition: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate condition" do
      login_as(@admin)

      assert_no_difference "ComponentCondition.count" do
        post admin_component_conditions_url, params: {
          component_condition: { condition: @component_condition.condition }
        }
      end

      assert_response :unprocessable_entity
    end

    # Edit
    test "edit displays form" do
      login_as(@admin)

      get edit_admin_component_condition_url(@component_condition)

      assert_response :success
      assert_select "h1", "Edit Component Condition"
      assert_select "input[value='#{@component_condition.condition}']"
    end

    # Update
    test "update changes component condition" do
      login_as(@admin)

      patch admin_component_condition_url(@component_condition), params: {
        component_condition: { condition: "Refurbished" }
      }

      assert_redirected_to admin_component_conditions_path
      @component_condition.reload
      assert_equal "Refurbished", @component_condition.condition
    end

    test "update fails with blank condition" do
      login_as(@admin)
      original = @component_condition.condition

      patch admin_component_condition_url(@component_condition), params: {
        component_condition: { condition: "" }
      }

      assert_response :unprocessable_entity
      @component_condition.reload
      assert_equal original, @component_condition.condition
    end

    test "update fails with duplicate condition" do
      login_as(@admin)
      other = component_conditions(:defective)

      patch admin_component_condition_url(other), params: {
        component_condition: { condition: @component_condition.condition }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "Defective", other.condition
    end

    # Destroy
    test "destroy deletes component condition without components" do
      login_as(@admin)
      condition = ComponentCondition.create!(condition: "Deletable")

      assert_difference "ComponentCondition.count", -1 do
        delete admin_component_condition_url(condition)
      end

      assert_redirected_to admin_component_conditions_path
      assert_match(/successfully deleted/i, flash[:notice])
    end

    test "destroy fails when component condition has components" do
      login_as(@admin)
      # Assign the fixture component to @component_condition so it is blocked
      components(:pdp11_memory).update_columns(component_condition_id: @component_condition.id)

      assert_no_difference "ComponentCondition.count" do
        delete admin_component_condition_url(@component_condition)
      end

      # Controller redirects with alert (not 422) on restrict_with_error failure
      assert_redirected_to admin_component_conditions_path
      assert flash[:alert].present?
    end

    # Authorization
    test "non-admin cannot access component conditions" do
      non_admin = owners(:two)
      login_as(non_admin)

      get admin_component_conditions_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage component conditions" do
      non_admin = owners(:two)
      login_as(non_admin)

      get new_admin_component_condition_url
      assert_redirected_to root_path

      assert_no_difference "ComponentCondition.count" do
        post admin_component_conditions_url, params: { component_condition: { condition: "Blocked" } }
      end
      assert_redirected_to root_path

      get edit_admin_component_condition_url(@component_condition)
      assert_redirected_to root_path

      patch admin_component_condition_url(@component_condition), params: { component_condition: { condition: "Blocked" } }
      assert_redirected_to root_path

      assert_no_difference "ComponentCondition.count" do
        delete admin_component_condition_url(@component_condition)
      end
      assert_redirected_to root_path
    end
  end
end
