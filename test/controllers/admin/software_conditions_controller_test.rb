# decor/test/controllers/admin/software_conditions_controller_test.rb
# version 1.0
# Session 44: Software feature Session B.
# Full CRUD + auth coverage for Admin::SoftwareConditionsController.
#
# Modeled on admin/component_types_controller_test.rb and the software_names
# controller test above.
#
# IMPORTANT: The value column is :name (not :condition). All param keys,
# assert_select selectors, and reload assertions use :name accordingly.
#
# Fixtures used:
#   software_conditions(:complete) — referenced by software_items fixtures;
#                                    used for destroy-blocked test.
#   A freshly-created SoftwareCondition is used for destroy-succeeds test.

require "test_helper"

module Admin
  class SoftwareConditionsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin              = owners(:one)
      @software_condition  = software_conditions(:complete)
    end

    # ── Index ────────────────────────────────────────────────────────────────

    test "index displays software conditions" do
      login_as(@admin)

      get admin_software_conditions_url

      assert_response :success
      assert_select "h1", "Software Conditions"
      assert_select "td", @software_condition.name
    end

    # ── New ──────────────────────────────────────────────────────────────────

    test "new displays form" do
      login_as(@admin)

      get new_admin_software_condition_url

      assert_response :success
      assert_select "h1", "New Software Condition"
      # Field name is :name (not :condition)
      assert_select "input[name='software_condition[name]']"
    end

    # ── Create ───────────────────────────────────────────────────────────────

    test "create adds new software condition" do
      login_as(@admin)

      assert_difference "SoftwareCondition.count", 1 do
        post admin_software_conditions_url, params: {
          software_condition: { name: "Partial", description: "Partially complete" }
        }
      end

      assert_redirected_to admin_software_conditions_path
      assert_match(/successfully created/i, flash[:notice])
    end

    test "create adds new software condition without description" do
      login_as(@admin)

      assert_difference "SoftwareCondition.count", 1 do
        post admin_software_conditions_url, params: {
          software_condition: { name: "Unknown" }
        }
      end

      assert_redirected_to admin_software_conditions_path
    end

    test "create fails with blank name" do
      login_as(@admin)

      assert_no_difference "SoftwareCondition.count" do
        post admin_software_conditions_url, params: {
          software_condition: { name: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "SoftwareCondition.count" do
        post admin_software_conditions_url, params: {
          software_condition: { name: @software_condition.name }
        }
      end

      assert_response :unprocessable_entity
    end

    # ── Edit ─────────────────────────────────────────────────────────────────

    test "edit displays form" do
      login_as(@admin)

      get edit_admin_software_condition_url(@software_condition)

      assert_response :success
      assert_select "h1", "Edit Software Condition"
      assert_select "input[value='#{@software_condition.name}']"
    end

    # ── Update ───────────────────────────────────────────────────────────────

    test "update changes software condition" do
      login_as(@admin)

      patch admin_software_condition_url(@software_condition), params: {
        software_condition: { name: "Complete Updated" }
      }

      assert_redirected_to admin_software_conditions_path
      @software_condition.reload
      assert_equal "Complete Updated", @software_condition.name
    end

    test "update changes description" do
      login_as(@admin)

      patch admin_software_condition_url(@software_condition), params: {
        software_condition: { name: @software_condition.name, description: "Updated description" }
      }

      assert_redirected_to admin_software_conditions_path
      @software_condition.reload
      assert_equal "Updated description", @software_condition.description
    end

    test "update fails with blank name" do
      login_as(@admin)
      original_name = @software_condition.name

      patch admin_software_condition_url(@software_condition), params: {
        software_condition: { name: "" }
      }

      assert_response :unprocessable_entity
      @software_condition.reload
      assert_equal original_name, @software_condition.name
    end

    test "update fails with duplicate name" do
      login_as(@admin)
      other = SoftwareCondition.create!(name: "Unique Condition")

      patch admin_software_condition_url(other), params: {
        software_condition: { name: @software_condition.name }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "Unique Condition", other.name
    end

    # ── Destroy ──────────────────────────────────────────────────────────────

    test "destroy deletes software condition without items" do
      login_as(@admin)
      deletable = SoftwareCondition.create!(name: "Deletable Condition")

      assert_difference "SoftwareCondition.count", -1 do
        delete admin_software_condition_url(deletable)
      end

      assert_redirected_to admin_software_conditions_path
    end

    test "destroy fails when software condition has software items" do
      login_as(@admin)
      # @software_condition (complete) is referenced by software_items fixtures

      assert_no_difference "SoftwareCondition.count" do
        delete admin_software_condition_url(@software_condition)
      end

      # Controller redirects with alert (restrict_with_error pattern)
      assert_redirected_to admin_software_conditions_path
      assert flash[:alert].present?
    end

    # ── Authorization ────────────────────────────────────────────────────────

    test "non-admin cannot access software conditions" do
      non_admin = owners(:two)
      login_as(non_admin)

      get admin_software_conditions_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage software conditions" do
      non_admin = owners(:two)
      login_as(non_admin)
      software_condition = software_conditions(:complete)

      get new_admin_software_condition_url
      assert_redirected_to root_path

      assert_no_difference "SoftwareCondition.count" do
        post admin_software_conditions_url, params: { software_condition: { name: "Blocked" } }
      end
      assert_redirected_to root_path

      get edit_admin_software_condition_url(software_condition)
      assert_redirected_to root_path

      patch admin_software_condition_url(software_condition), params: { software_condition: { name: "Blocked" } }
      assert_redirected_to root_path

      assert_no_difference "SoftwareCondition.count" do
        delete admin_software_condition_url(software_condition)
      end
      assert_redirected_to root_path
    end
  end
end
