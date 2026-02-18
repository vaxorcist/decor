# decor/test/controllers/admin/conditions_controller_test.rb - version 1.1
# Refactored to use centralized AuthenticationHelper
# Removed local log_in_as method - now inherited from test/support/authentication_helper.rb
# All login_as() calls use auto-detection for correct password

require "test_helper"

module Admin
  class ConditionsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = owners(:one)
      @condition = conditions(:original)
    end

    # Index
    test "index displays conditions" do
      login_as(@admin)

      get admin_conditions_url

      assert_response :success
      assert_select "h1", "Conditions"
      assert_select "td", @condition.name
    end

    # New
    test "new displays form" do
      login_as(@admin)

      get new_admin_condition_url

      assert_response :success
      assert_select "h1", "New Condition"
      assert_select "input[name='condition[name]']"
    end

    # Create
    test "create adds new condition" do
      login_as(@admin)

      assert_difference "Condition.count", 1 do
        post admin_conditions_url, params: {
          condition: { name: "New Condition" }
        }
      end

      assert_redirected_to admin_conditions_path
      assert_match /successfully created/i, flash[:notice]
    end

    test "create fails with blank name" do
      login_as(@admin)

      assert_no_difference "Condition.count" do
        post admin_conditions_url, params: {
          condition: { name: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "Condition.count" do
        post admin_conditions_url, params: {
          condition: { name: @condition.name }
        }
      end

      assert_response :unprocessable_entity
    end

    # Edit
    test "edit displays form" do
      login_as(@admin)

      get edit_admin_condition_url(@condition)

      assert_response :success
      assert_select "h1", "Edit Condition"
      assert_select "input[value='#{@condition.name}']"
    end

    # Update
    test "update changes condition" do
      login_as(@admin)

      patch admin_condition_url(@condition), params: {
        condition: { name: "Updated Name" }
      }

      assert_redirected_to admin_conditions_path
      @condition.reload
      assert_equal "Updated Name", @condition.name
    end

    test "update fails with blank name" do
      login_as(@admin)
      original_name = @condition.name

      patch admin_condition_url(@condition), params: {
        condition: { name: "" }
      }

      assert_response :unprocessable_entity
      @condition.reload
      assert_equal original_name, @condition.name
    end

    test "update fails with duplicate name" do
      login_as(@admin)
      other = Condition.create!(name: "Other Condition")

      patch admin_condition_url(other), params: {
        condition: { name: @condition.name }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "Other Condition", other.name
    end

    # Destroy
    test "destroy deletes condition without computers" do
      login_as(@admin)
      condition = Condition.create!(name: "Deletable")

      assert_difference "Condition.count", -1 do
        delete admin_condition_url(condition)
      end

      assert_redirected_to admin_conditions_path
    end

    test "destroy fails when condition has computers" do
      login_as(@admin)
      # @condition has computers via fixtures

      assert_no_difference "Condition.count" do
        delete admin_condition_url(@condition)
      end

      assert_redirected_to admin_conditions_path
    end

    # Authorization
    test "non-admin cannot access conditions" do
      non_admin = owners(:two)
      login_as(non_admin)

      get admin_conditions_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage conditions" do
      non_admin = owners(:two)
      login_as(non_admin)
      condition = conditions(:original)

      get new_admin_condition_url
      assert_redirected_to root_path

      assert_no_difference "Condition.count" do
        post admin_conditions_url, params: { condition: { name: "Blocked" } }
      end
      assert_redirected_to root_path

      get edit_admin_condition_url(condition)
      assert_redirected_to root_path

      patch admin_condition_url(condition), params: { condition: { name: "Blocked" } }
      assert_redirected_to root_path

      assert_no_difference "Condition.count" do
        delete admin_condition_url(condition)
      end
      assert_redirected_to root_path
    end
  end
end
