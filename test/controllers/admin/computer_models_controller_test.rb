# decor/test/controllers/admin/computer_models_controller_test.rb
# version 1.3
# v1.3 (Session 41): Appliances → Peripherals merger Phase 2.
#   Removed @appliance_model from setup — hsc50 is now a peripheral fixture.
#   Removed all appliance context tests (admin_appliance_models route is gone):
#     "index shows appliance models only"
#     "new appliance model displays correct heading"
#     "create appliance model stamps device_type 1 and redirects to appliance models"
#     "create appliance model fails with blank name"
#     "create appliance model fails with duplicate name"
#     "edit appliance model displays correct heading"
#     "update appliance model changes name and redirects to appliance models"
#     "destroy appliance model with no computers" (used device_type: 1)
#     "non-admin cannot access appliance models"
#   Updated "index shows computer models only": assertion updated to check that
#     peripheral models (hsc50 and dec_vt278) do not appear on the computer index.
#   Updated "index shows peripheral models only": now also asserts hsc50 appears,
#     since it is now a peripheral fixture after the Session 41 merger.
#
# v1.2 (Session 27): peripheral context tests added — mirrors former appliance
#   context tests. Uses computer_models(:dec_vt278) fixture (device_type: 2).

require "test_helper"

module Admin
  class ComputerModelsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin            = owners(:one)
      @non_admin        = owners(:two)
      @computer_model   = computer_models(:pdp11_70)   # device_type: 0 (computer)
      @peripheral_model = computer_models(:dec_vt278)  # device_type: 2 (peripheral)
      # Note: computer_models(:hsc50) is also device_type: 2 (peripheral) after
      # Session 41 merger; it was formerly device_type: 1 (appliance).
    end

    # ── Index — computer context ────────────────────────────────────────────

    test "index shows computer models only" do
      login_as(@admin)
      get admin_computer_models_url
      assert_response :success
      assert_select "h1", "Computer Models"
      assert_select "td", @computer_model.name
      # Peripheral models (both dec_vt278 and hsc50) must not appear on the
      # computer models index.
      assert_select "td", { text: @peripheral_model.name, count: 0 }
      assert_select "td", { text: computer_models(:hsc50).name, count: 0 }
    end

    # ── Index — peripheral context ──────────────────────────────────────────

    test "index shows peripheral models only" do
      login_as(@admin)
      get admin_peripheral_models_url
      assert_response :success
      assert_select "h1", "Peripheral Models"
      # dec_vt278 and hsc50 are both peripheral fixtures (device_type: 2).
      # hsc50 was formerly an appliance model (device_type: 1); it was merged
      # into the peripheral category in Session 41.
      assert_select "td", @peripheral_model.name
      assert_select "td", computer_models(:hsc50).name
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

    test "destroy peripheral model with no computers" do
      login_as(@admin)
      # Create a peripheral model with no associated computers so destroy succeeds.
      # device_type: 2 (peripheral) — the only valid non-computer value after
      # the Session 41 appliance merger.
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
