# decor/test/controllers/admin/software_names_controller_test.rb
# version 1.0
# Session 44: Software feature Session B.
# Full CRUD + auth coverage for Admin::SoftwareNamesController.
#
# Modeled on admin/component_types_controller_test.rb.
#
# Fixtures used:
#   software_names(:vms)    — has software_items (vms + rt11 referenced); used for
#                             destroy-blocked and duplicate-name tests.
#   software_names(:tops20) — no description; used for edit/update display tests.
#   A freshly-created SoftwareName is used for the destroy-succeeds test to avoid
#   coupling to fixture state.

require "test_helper"

module Admin
  class SoftwareNamesControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin        = owners(:one)
      @software_name = software_names(:vms)
    end

    # ── Index ────────────────────────────────────────────────────────────────

    test "index displays software names" do
      login_as(@admin)

      get admin_software_names_url

      assert_response :success
      assert_select "h1", "Software Names"
      assert_select "td", @software_name.name
    end

    # ── New ──────────────────────────────────────────────────────────────────

    test "new displays form" do
      login_as(@admin)

      get new_admin_software_name_url

      assert_response :success
      assert_select "h1", "New Software Name"
      assert_select "input[name='software_name[name]']"
    end

    # ── Create ───────────────────────────────────────────────────────────────

    test "create adds new software name" do
      login_as(@admin)

      assert_difference "SoftwareName.count", 1 do
        post admin_software_names_url, params: {
          software_name: { name: "RSTS/E-Plus", description: "Extended RSTS" }
        }
      end

      assert_redirected_to admin_software_names_path
      assert_match(/successfully created/i, flash[:notice])
    end

    test "create adds new software name without description" do
      login_as(@admin)

      assert_difference "SoftwareName.count", 1 do
        post admin_software_names_url, params: {
          software_name: { name: "RSX-11M" }
        }
      end

      assert_redirected_to admin_software_names_path
    end

    test "create fails with blank name" do
      login_as(@admin)

      assert_no_difference "SoftwareName.count" do
        post admin_software_names_url, params: {
          software_name: { name: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "SoftwareName.count" do
        post admin_software_names_url, params: {
          software_name: { name: @software_name.name }
        }
      end

      assert_response :unprocessable_entity
    end

    # ── Edit ─────────────────────────────────────────────────────────────────

    test "edit displays form" do
      login_as(@admin)

      get edit_admin_software_name_url(@software_name)

      assert_response :success
      assert_select "h1", "Edit Software Name"
      assert_select "input[value='#{@software_name.name}']"
    end

    # ── Update ───────────────────────────────────────────────────────────────

    test "update changes software name" do
      login_as(@admin)

      patch admin_software_name_url(@software_name), params: {
        software_name: { name: "VMS Updated" }
      }

      assert_redirected_to admin_software_names_path
      @software_name.reload
      assert_equal "VMS Updated", @software_name.name
    end

    test "update changes description" do
      login_as(@admin)

      patch admin_software_name_url(@software_name), params: {
        software_name: { name: @software_name.name, description: "Updated description" }
      }

      assert_redirected_to admin_software_names_path
      @software_name.reload
      assert_equal "Updated description", @software_name.description
    end

    test "update fails with blank name" do
      login_as(@admin)
      original_name = @software_name.name

      patch admin_software_name_url(@software_name), params: {
        software_name: { name: "" }
      }

      assert_response :unprocessable_entity
      @software_name.reload
      assert_equal original_name, @software_name.name
    end

    test "update fails with duplicate name" do
      login_as(@admin)
      other = SoftwareName.create!(name: "Unique Name")

      patch admin_software_name_url(other), params: {
        software_name: { name: @software_name.name }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "Unique Name", other.name
    end

    # ── Destroy ──────────────────────────────────────────────────────────────

    test "destroy deletes software name without items" do
      login_as(@admin)
      deletable = SoftwareName.create!(name: "Deletable Title")

      assert_difference "SoftwareName.count", -1 do
        delete admin_software_name_url(deletable)
      end

      assert_redirected_to admin_software_names_path
    end

    test "destroy fails when software name has software items" do
      login_as(@admin)
      # @software_name (vms) is referenced by software_items fixtures

      assert_no_difference "SoftwareName.count" do
        delete admin_software_name_url(@software_name)
      end

      # Controller redirects with alert (restrict_with_error pattern)
      assert_redirected_to admin_software_names_path
      assert flash[:alert].present?
    end

    # ── Authorization ────────────────────────────────────────────────────────

    test "non-admin cannot access software names" do
      non_admin = owners(:two)
      login_as(non_admin)

      get admin_software_names_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage software names" do
      non_admin = owners(:two)
      login_as(non_admin)
      software_name = software_names(:vms)

      get new_admin_software_name_url
      assert_redirected_to root_path

      assert_no_difference "SoftwareName.count" do
        post admin_software_names_url, params: { software_name: { name: "Blocked" } }
      end
      assert_redirected_to root_path

      get edit_admin_software_name_url(software_name)
      assert_redirected_to root_path

      patch admin_software_name_url(software_name), params: { software_name: { name: "Blocked" } }
      assert_redirected_to root_path

      assert_no_difference "SoftwareName.count" do
        delete admin_software_name_url(software_name)
      end
      assert_redirected_to root_path
    end
  end
end
