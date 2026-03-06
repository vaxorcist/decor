# decor/test/controllers/computers_controller_test.rb - version 1.5
# v1.5 (Session 18): Fixed two failing tests — login_as owners(:three) was
#   silently failing because charlie's password ("DecorTest2026!") is not
#   registered in detect_password. Both charlie tests now pass the password
#   explicitly via login_as owners(:three), password: "DecorTest2026!".
# v1.4 (Session 18): Added tests for device_type selector on new/edit form:
#   - create with device_type=computer  → record stamped correctly; flash "Computer…"
#   - create with device_type=appliance → record stamped correctly; flash "Appliance…"
#   - update computer → device_type=appliance → flash "Appliance was successfully updated."
#   - update appliance → device_type=computer → flash "Computer was successfully updated."
#   - destroy appliance (dec_unibus_router / charlie) → flash "Appliance was successfully deleted."
#   Existing destroy tests for alice_pdp11 (device_type: computer) remain valid —
#   "Computer was successfully deleted." is still the correct flash for that record.
#
# v1.3 (Session 17): Corrected stale test "index without device_type filter shows
#   computers and appliances" — that described the old (wrong) behaviour. The
#   Computers page now defaults to device_type=computer when no param is present,
#   so appliances must NOT appear in the unfiltered response. Test updated accordingly.
#
# v1.2: Added two appliances route tests (GET /appliances, device_type locked).
# v1.1: Three device_type filter tests for the computers index action.
# v1.0 (Session 11): destroy action source-param redirect tests.
#
# Fixture notes:
#   owners(:one)                   = alice (admin)
#   owners(:three)                 = charlie (neutral owner; no hardcoded count assertions)
#   computers(:alice_pdp11)        = alice's PDP-11/70, serial SN12345, device_type: computer
#   computers(:dec_unibus_router)  = charlie's router, serial RTR-001, device_type: appliance
#   Each test runs in a rolled-back transaction.

require "test_helper"

class ComputersControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Appliances route — index locked to device_type=appliance
  # ---------------------------------------------------------------------------

  test "GET /appliances loads successfully" do
    login_as owners(:one)
    get appliances_path
    assert_response :success
  end

  test "GET /appliances shows only appliances, not computers" do
    login_as owners(:one)
    get appliances_path
    assert_includes     response.body, computers(:dec_unibus_router).serial_number
    assert_not_includes response.body, computers(:alice_pdp11).serial_number
  end

  # ---------------------------------------------------------------------------
  # Computers index — device_type filter
  # ---------------------------------------------------------------------------

  test "index without device_type param shows only computers, not appliances" do
    # Computers page defaults to device_type=computer when no param is present.
    # Appliances must not bleed through to the Computers page.
    login_as owners(:one)
    get computers_path
    assert_response :success
    assert_includes     response.body, computers(:alice_pdp11).serial_number
    assert_not_includes response.body, computers(:dec_unibus_router).serial_number
  end

  test "index filtered by device_type=computer excludes appliances" do
    login_as owners(:one)
    get computers_path(device_type: "computer")
    assert_response :success
    assert_includes     response.body, computers(:alice_pdp11).serial_number
    assert_not_includes response.body, computers(:dec_unibus_router).serial_number
  end

  test "index filtered by device_type=appliance excludes computers" do
    login_as owners(:one)
    get computers_path(device_type: "appliance")
    assert_response :success
    assert_includes     response.body, computers(:dec_unibus_router).serial_number
    assert_not_includes response.body, computers(:alice_pdp11).serial_number
  end

  # ---------------------------------------------------------------------------
  # Create — device_type stamped correctly; flash reflects device type
  # ---------------------------------------------------------------------------

  test "create with device_type=computer stamps computer and shows correct flash" do
    login_as owners(:one)
    assert_difference "Computer.count", 1 do
      post computers_path, params: {
        computer: {
          computer_model_id: computer_models(:pdp11_70).id,
          serial_number:     "NEW-COMP-001",
          device_type:       "computer"
        }
      }
    end
    created = Computer.last
    assert_equal "computer", created.device_type
    # Redirect goes to edit page so components can be added; flash confirms type.
    assert_redirected_to edit_computer_path(created)
    assert_equal "Computer was successfully created. You can now add components below.", flash[:notice]
  end

  test "create with device_type=appliance stamps appliance and shows correct flash" do
    login_as owners(:one)
    assert_difference "Computer.count", 1 do
      post computers_path, params: {
        computer: {
          computer_model_id: computer_models(:pdp11_70).id,
          serial_number:     "NEW-APPL-001",
          device_type:       "appliance"
        }
      }
    end
    created = Computer.last
    assert_equal "appliance", created.device_type
    assert_redirected_to edit_computer_path(created)
    assert_equal "Appliance was successfully created. You can now add components below.", flash[:notice]
  end

  # ---------------------------------------------------------------------------
  # Update — flash reflects the device_type AFTER the update
  # ---------------------------------------------------------------------------

  test "update computer record shows computer flash" do
    # alice_pdp11 starts as device_type: computer; we update serial_number only
    # to confirm the flash uses the (unchanged) computer device type.
    login_as owners(:one)
    patch computer_path(computers(:alice_pdp11)), params: {
      computer: { serial_number: "SN12345-UPDATED", device_type: "computer" }
    }
    assert_redirected_to computer_path(computers(:alice_pdp11))
    assert_equal "Computer was successfully updated.", flash[:notice]
  end

  test "update computer record to device_type=appliance shows appliance flash" do
    # Changing an existing computer's type to appliance — flash must reflect the
    # new type, not the old one (flash is built from @computer.device_type AFTER
    # the update call in computers_controller.rb v1.10).
    login_as owners(:one)
    patch computer_path(computers(:alice_pdp11)), params: {
      computer: { device_type: "appliance" }
    }
    assert_redirected_to computer_path(computers(:alice_pdp11))
    assert_equal "Appliance was successfully updated.", flash[:notice]
  end

  test "update appliance record to device_type=computer shows computer flash" do
    # dec_unibus_router is owned by charlie (owners(:three)).
    # Charlie's password is not in detect_password — must be passed explicitly.
    login_as owners(:three), password: "DecorTest2026!"
    patch computer_path(computers(:dec_unibus_router)), params: {
      computer: { device_type: "computer" }
    }
    assert_redirected_to computer_path(computers(:dec_unibus_router))
    assert_equal "Computer was successfully updated.", flash[:notice]
  end

  # ---------------------------------------------------------------------------
  # Destroy — source=owner redirect (computer, existing tests)
  # ---------------------------------------------------------------------------

  test "destroy with source=owner redirects to owner page" do
    login_as owners(:one)
    assert_difference "Computer.count", -1 do
      delete computer_url(computers(:alice_pdp11)), params: { source: "owner" }
    end
    assert_redirected_to owner_path(owners(:one))
    assert_equal "Computer was successfully deleted.", flash[:notice]
  end

  test "destroy without source redirects to computers index" do
    login_as owners(:one)
    assert_difference "Computer.count", -1 do
      delete computer_url(computers(:alice_pdp11))
    end
    assert_redirected_to computers_path
    assert_equal "Computer was successfully deleted.", flash[:notice]
  end

  # ---------------------------------------------------------------------------
  # Destroy — flash reflects the device_type of the deleted record
  # ---------------------------------------------------------------------------

  test "destroy appliance shows appliance flash" do
    # dec_unibus_router is an appliance owned by charlie (owners(:three)).
    # Charlie's password is not in detect_password — must be passed explicitly.
    # device_label is captured before destroy in v1.10, so the flash is
    # available even after the record is gone.
    login_as owners(:three), password: "DecorTest2026!"
    assert_difference "Computer.count", -1 do
      delete computer_url(computers(:dec_unibus_router))
    end
    assert_redirected_to computers_path
    assert_equal "Appliance was successfully deleted.", flash[:notice]
  end
end
