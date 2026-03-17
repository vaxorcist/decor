# decor/test/controllers/admin/computer_models_controller_test.rb
# version 1.2
# Session 27: peripheral context tests added (index, new, create, create-validation,
#   edit, update, destroy, authorization) — mirrors appliance context tests exactly.
#   Uses computer_models(:dec_vt278) fixture (device_type: 2, added in v1.2 of the
#   fixture file, Session 26).
#
# Tests Admin::ComputerModelsController in all three contexts:
#   - computer   context → /admin/computer_models   (device_context: "computer")
#   - appliance  context → /admin/appliance_models  (device_context: "appliance")
#   - peripheral context → /admin/peripheral_models (device_context: "peripheral")
# Covers: index scoping, create (stamps correct device_type, redirects correctly),
# update, destroy, validation failures, and authorization.
# Pattern follows conditions_controller_test.rb v1.3.

require "test_helper"

module Admin
  class ComputerModelsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin     = owners(:one)
      @non_admin = owners(:two)
      @computer_model  = computer_models(:pdp11_70)   # device_type: 0 (computer)
      @appliance_model = computer_models(:hsc50)      # device_type: 1 (appliance)
      @peripheral_model = computer_models(:dec_vt278) # device_type: 2 (peripheral)
    end

    # ── Index — computer context ────────────────────────────────────────────

    test "index shows computer models only" do
      login_as(@admin)
      get admin_computer_models_url
      assert_response :success
      assert_select "h1", "Computer Models"
      assert_select "td", @computer_model.name
      # Appliance models must not appear on the computer models index
      assert_select "td", { text: @appliance_model.name, count: 0 }
    end

    # ── Index — appliance context ───────────────────────────────────────────

    test "index shows appliance models only" do
      login_as(@admin)
      get admin_appliance_models_url
      assert_response :success
      assert_select "h1", "Appliance Models"
      assert_select "td", @appliance_model.name
      # Computer models must not appear on the appliance models index
      assert_select "td", { text: @computer_model.name, count: 0 }
    end

    # ── Index — peripheral context ──────────────────────────────────────────

    test "index shows peripheral models only" do
      login_as(@admin)
      get admin_peripheral_models_url
      assert_response :success
      assert_select "h1", "Peripheral Models"
      assert_select "td", @peripheral_model.name
      # Computer models must not appear on the peripheral models index
      assert_select "td", { text: @computer_model.name, count: 0 }
    end

    # ── New ─────────────────────────────────────────────────────────────────

    test "new computer model displays correct heading" do
      login_as(@admin)
      get new_admin_computer_model_url
      assert_response :success
      assert_select "h1", "New Computer Model"
    end

    test "new appliance model displays correct heading" do
      login_as(@admin)
      get new_admin_appliance_model_url
      assert_response :success
      assert_select "h1", "New Appliance Model"
    end

    test "new peripheral model displays correct heading" do
      login_as(@admin)
      get new_admin_peripheral_model_url
      assert_response :success
      assert_select "h1", "New Peripheral Model"
    end

    # ── Create — computer context ───────────────────────────────────────────

    test "create computer model stamps device_type 0 and redirects to computer models" do
      login_as(@admin)

      assert_difference "ComputerModel.count", 1 do
        post admin_computer_models_url, params: {
          computer_model: { name: "PDP-11/44" }
        }
      end

      created = ComputerModel.find_by!(name: "PDP-11/44")
      assert_equal "computer", created.device_type
      assert_redirected_to admin_computer_models_path
      assert_match(/successfully created/i, flash[:notice])
    end

    # ── Create — appliance context ──────────────────────────────────────────

    test "create appliance model stamps device_type 1 and redirects to appliance models" do
      login_as(@admin)

      assert_difference "ComputerModel.count", 1 do
        post admin_appliance_models_url, params: {
          computer_model: { name: "HSC70" }
        }
      end

      created = ComputerModel.find_by!(name: "HSC70")
      assert_equal "appliance", created.device_type
      assert_redirected_to admin_appliance_models_path
      assert_match(/successfully created/i, flash[:notice])
    end

    # ── Create — peripheral context ─────────────────────────────────────────

    test "create peripheral model stamps device_type 2 and redirects to peripheral models" do
      login_as(@admin)

      assert_difference "ComputerModel.count", 1 do
        post admin_peripheral_models_url, params: {
          computer_model: { name: "DEC VT100" }
        }
      end

      # Verify correct device_type string was stamped (not the integer 2)
      created = ComputerModel.find_by!(name: "DEC VT100")
      assert_equal "peripheral", created.device_type
      assert_redirected_to admin_peripheral_models_path
      assert_match(/successfully created/i, flash[:notice])
    end

    # ── Create — validation failures ────────────────────────────────────────

    test "create computer model fails with blank name" do
      login_as(@admin)

      assert_no_difference "ComputerModel.count" do
        post admin_computer_models_url, params: { computer_model: { name: "" } }
      end

      assert_response :unprocessable_entity
    end

    test "create appliance model fails with blank name" do
      login_as(@admin)

      assert_no_difference "ComputerModel.count" do
        post admin_appliance_models_url, params: { computer_model: { name: "" } }
      end

      assert_response :unprocessable_entity
    end

    test "create appliance model fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "ComputerModel.count" do
        post admin_appliance_models_url, params: {
          computer_model: { name: @appliance_model.name }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create peripheral model fails with blank name" do
      login_as(@admin)

      assert_no_difference "ComputerModel.count" do
        post admin_peripheral_models_url, params: { computer_model: { name: "" } }
      end

      assert_response :unprocessable_entity
    end

    test "create peripheral model fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "ComputerModel.count" do
        post admin_peripheral_models_url, params: {
          computer_model: { name: @peripheral_model.name }
        }
      end

      assert_response :unprocessable_entity
    end

    # ── Edit ────────────────────────────────────────────────────────────────

    test "edit computer model displays correct heading" do
      login_as(@admin)
      get edit_admin_computer_model_url(@computer_model)
      assert_response :success
      assert_select "h1", "Edit Computer Model"
      assert_select "input[value='#{@computer_model.name}']"
    end

    test "edit appliance model displays correct heading" do
      login_as(@admin)
      get edit_admin_appliance_model_url(@appliance_model)
      assert_response :success
      assert_select "h1", "Edit Appliance Model"
      assert_select "input[value='#{@appliance_model.name}']"
    end

    test "edit peripheral model displays correct heading" do
      login_as(@admin)
      get edit_admin_peripheral_model_url(@peripheral_model)
      assert_response :success
      assert_select "h1", "Edit Peripheral Model"
      assert_select "input[value='#{@peripheral_model.name}']"
    end

    # ── Update ──────────────────────────────────────────────────────────────

    test "update computer model changes name and redirects to computer models" do
      login_as(@admin)

      patch admin_computer_model_url(@computer_model), params: {
        computer_model: { name: "PDP-11/70 Updated" }
      }

      assert_redirected_to admin_computer_models_path
      assert_equal "PDP-11/70 Updated", @computer_model.reload.name
    end

    test "update appliance model changes name and redirects to appliance models" do
      login_as(@admin)

      patch admin_appliance_model_url(@appliance_model), params: {
        computer_model: { name: "HSC50 Updated" }
      }

      assert_redirected_to admin_appliance_models_path
      assert_equal "HSC50 Updated", @appliance_model.reload.name
    end

    test "update peripheral model changes name and redirects to peripheral models" do
      login_as(@admin)

      patch admin_peripheral_model_url(@peripheral_model), params: {
        computer_model: { name: "DEC VT278 Updated" }
      }

      assert_redirected_to admin_peripheral_models_path
      assert_equal "DEC VT278 Updated", @peripheral_model.reload.name
    end

    test "update fails with blank name" do
      login_as(@admin)
      original = @computer_model.name

      patch admin_computer_model_url(@computer_model), params: {
        computer_model: { name: "" }
      }

      assert_response :unprocessable_entity
      assert_equal original, @computer_model.reload.name
    end

    # ── Destroy ─────────────────────────────────────────────────────────────

    test "destroy computer model with no computers" do
      login_as(@admin)
      model = ComputerModel.create!(name: "Deletable Computer Model", device_type: 0)

      assert_difference "ComputerModel.count", -1 do
        delete admin_computer_model_url(model)
      end

      assert_redirected_to admin_computer_models_path
    end

    test "destroy appliance model with no computers" do
      login_as(@admin)
      model = ComputerModel.create!(name: "Deletable Appliance Model", device_type: 1)

      assert_difference "ComputerModel.count", -1 do
        delete admin_appliance_model_url(model)
      end

      assert_redirected_to admin_appliance_models_path
    end

    test "destroy peripheral model with no computers" do
      login_as(@admin)
      # Create a peripheral model with no associated computers so destroy succeeds
      model = ComputerModel.create!(name: "Deletable Peripheral Model", device_type: 2)

      assert_difference "ComputerModel.count", -1 do
        delete admin_peripheral_model_url(model)
      end

      assert_redirected_to admin_peripheral_models_path
    end

    test "destroy fails when computer model has computers" do
      login_as(@admin)
      # @computer_model (pdp11_70) has computers via fixtures

      assert_no_difference "ComputerModel.count" do
        delete admin_computer_model_url(@computer_model)
      end

      assert_redirected_to admin_computer_models_path
      assert flash[:alert].present?
    end

    # ── Authorization ────────────────────────────────────────────────────────

    test "non-admin cannot access computer models" do
      login_as(@non_admin)
      get admin_computer_models_url
      assert_redirected_to root_path
    end

    test "non-admin cannot access appliance models" do
      login_as(@non_admin)
      get admin_appliance_models_url
      assert_redirected_to root_path
    end

    test "non-admin cannot access peripheral models" do
      login_as(@non_admin)
      get admin_peripheral_models_url
      assert_redirected_to root_path
    end

    test "guest cannot access computer models" do
      get admin_computer_models_url
      assert_redirected_to root_path
    end
  end
end
