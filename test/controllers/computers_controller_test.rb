# decor/test/controllers/computers_controller_test.rb
# version 1.9
# v1.9 (Session 47): Software feature Session E.
#   Added two show-action tests for the Software section:
#     "show with software renders software name in software section"
#     "show without software renders software empty-state message"
#   alice_pdp11 has alice_vms (software_name: vms) — used for the populated test.
#   unassigned_condition_test has no software items — used for the empty-state test.
#   Software name string derived from fixture at test time (software_items(:alice_vms)
#   .software_name.name) — never hardcoded, follows derive-from-data rule.
#
# v1.8 (Session 41): Appliances → Peripherals merger Phase 2.
#   Removed appliance route tests (route gone):
#     "GET /appliances loads successfully"
#     "GET /appliances shows only appliances, not computers"
#   Removed appliance filter test (enum value gone):
#     "index filtered by device_type=appliance excludes computers"
#   Removed appliance create test (enum value gone):
#     "create with device_type=appliance stamps appliance and shows correct flash"
#   Removed appliance-to-computer update test (appliance gone):
#     "update computer record to device_type=appliance shows appliance flash"
#   Updated peripheral-to-computer update test: dec_unibus_router is now a
#     peripheral (not appliance) after fixture v1.9 change; test renamed accordingly.
#   Updated destroy test: dec_unibus_router is now peripheral; expected flash
#     changed from "Appliance was successfully deleted." to
#     "Peripheral was successfully deleted."
#   Updated fixture notes in this header comment.
#
# v1.7 (Session 35): Added two show-action tests for Part 3 connections display.
# v1.6 (Session 22): Added barter_status filter tests.
# v1.5 (Session 18): Fixed charlie password in login_as call.
# v1.4 (Session 18): Added tests for device_type selector on new/edit form.
# v1.3 (Session 17): Corrected stale filter test for unfiltered index.
# v1.2: Added two appliances route tests.
# v1.1: Three device_type filter tests for the computers index action.
# v1.0 (Session 11): destroy action source-param redirect tests.
#
# Fixture notes:
#   owners(:one)                   = alice (admin)
#   owners(:three)                 = charlie (neutral owner; no hardcoded count assertions)
#   computers(:alice_pdp11)        = alice's PDP-11/70, serial SN12345, device_type: computer, barter_status: 0 (no_barter)
#   computers(:alice_vax)          = alice's VAX,       device_type: computer, barter_status: 2 (wanted)
#   computers(:dec_unibus_router)  = charlie's router,  device_type: peripheral (formerly appliance), barter_status: 1 (offered)
#   computers(:unassigned_condition_test) = alice's device, not in any connection group, no software items
#   software_items(:alice_vms)     = installed on alice_pdp11; software_name: vms
#   Each test runs in a rolled-back transaction.

require "test_helper"

class ComputersControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Computers index — device_type filter
  # ---------------------------------------------------------------------------

  test "index without device_type param shows only computers, not peripherals" do
    # Computers page defaults to device_type=computer when no param is present.
    # Peripherals must not bleed through to the Computers page.
    login_as owners(:one)
    get computers_path
    assert_response :success
    assert_includes     response.body, computers(:alice_pdp11).serial_number
    assert_not_includes response.body, computers(:dec_unibus_router).serial_number
  end

  test "index filtered by device_type=computer excludes peripherals" do
    login_as owners(:one)
    get computers_path(device_type: "computer")
    assert_response :success
    assert_includes     response.body, computers(:alice_pdp11).serial_number
    assert_not_includes response.body, computers(:dec_unibus_router).serial_number
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

  test "create with device_type=peripheral stamps peripheral and shows correct flash" do
    login_as owners(:one)
    assert_difference "Computer.count", 1 do
      post computers_path, params: {
        computer: {
          computer_model_id: computer_models(:pdp11_70).id,
          serial_number:     "NEW-PERI-001",
          device_type:       "peripheral"
        }
      }
    end
    created = Computer.last
    assert_equal "peripheral", created.device_type
    assert_redirected_to edit_computer_path(created)
    assert_equal "Peripheral was successfully created. You can now add components below.", flash[:notice]
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

  test "update peripheral record to device_type=computer shows computer flash" do
    # dec_unibus_router is a peripheral owned by charlie (owners(:three)).
    # Charlie's password is not in detect_password — must be passed explicitly.
    # Flash must reflect the new type ("computer") after the update.
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

  test "destroy peripheral shows peripheral flash" do
    # dec_unibus_router is a peripheral (formerly appliance) owned by charlie.
    # Charlie's password is not in detect_password — must be passed explicitly.
    # device_label is captured before destroy in v1.10, so the flash is
    # available even after the record is gone.
    login_as owners(:three), password: "DecorTest2026!"
    assert_difference "Computer.count", -1 do
      delete computer_url(computers(:dec_unibus_router))
    end
    assert_redirected_to computers_path
    assert_equal "Peripheral was successfully deleted.", flash[:notice]
  end

  # ---------------------------------------------------------------------------
  # Barter filter — logged-in users see filtered results; logged-out see all
  # ---------------------------------------------------------------------------
  #
  # Fixture barter_status values on the computers index (/computers route,
  # device_type=computer by default):
  #   alice_pdp11  barter_status: 0 (no_barter)
  #   alice_vax    barter_status: 2 (wanted)
  #   (dec_unibus_router is a peripheral — never shown on /computers)
  #
  # Default filter for logged-in users: "0+1" (no_barter + offered).
  # alice_vax (wanted) must be hidden; alice_pdp11 (no_barter) must be visible.

  test "logged-in index default barter filter hides wanted computers" do
    # No barter_status param → controller uses default "0+1" (no_barter + offered).
    # alice_vax has barter_status: wanted (2) → must be excluded.
    login_as owners(:one)
    get computers_path
    assert_response :success
    assert_includes     response.body, computers(:alice_pdp11).serial_number,
      "alice_pdp11 (no_barter) should be visible under the default 0+1 filter"
    assert_not_includes response.body, computers(:alice_vax).serial_number,
      "alice_vax (wanted) should be hidden under the default 0+1 filter"
  end

  test "logged-in index barter_status=2 shows only wanted computers" do
    # Explicitly requesting wanted (2) → alice_vax visible, alice_pdp11 hidden.
    login_as owners(:one)
    get computers_path(barter_status: "2")
    assert_response :success
    assert_includes     response.body, computers(:alice_vax).serial_number,
      "alice_vax (wanted) should be visible when filtering by barter_status=2"
    assert_not_includes response.body, computers(:alice_pdp11).serial_number,
      "alice_pdp11 (no_barter) should be hidden when filtering by barter_status=2"
  end

  test "logged-in index barter_status=0 shows only no_barter computers" do
    # Filtering by no_barter only → alice_pdp11 visible, alice_vax hidden.
    login_as owners(:one)
    get computers_path(barter_status: "0")
    assert_response :success
    assert_includes     response.body, computers(:alice_pdp11).serial_number,
      "alice_pdp11 (no_barter) should be visible when filtering by barter_status=0"
    assert_not_includes response.body, computers(:alice_vax).serial_number,
      "alice_vax (wanted) should be hidden when filtering by barter_status=0"
  end

  test "logged-out index shows all computers regardless of barter_status" do
    # Non-logged-in visitors: no barter filter applied.
    # Both alice_pdp11 (no_barter) and alice_vax (wanted) must be visible.
    get computers_path
    assert_response :success
    assert_includes response.body, computers(:alice_pdp11).serial_number,
      "alice_pdp11 should be visible to logged-out visitors (no filter)"
    assert_includes response.body, computers(:alice_vax).serial_number,
      "alice_vax (wanted) should be visible to logged-out visitors (no filter)"
  end

  # ---------------------------------------------------------------------------
  # Show — connections display (Part 3)
  # ---------------------------------------------------------------------------
  #
  # Fixture connection data:
  #   alice_pdp11  → group alice_pdp11_vax (label: "Lab setup", no connection_type)
  #                   peer: alice_vax (serial: VAX-780-001)
  #   bob_pdp8     → group bob_pdp8_vt100 (label: "PDP-8 terminal connection",
  #                   connection_type: rs232 / label: "RS-232 serial port connection")
  #                   peer: bob_vt100
  #   unassigned_condition_test — alice's device, not in any group → empty state

  test "show with connections renders connection group label and peer computer" do
    # alice_pdp11 belongs to group alice_pdp11_vax.
    # Group label "Lab setup" must appear in the Connections section.
    # Peer alice_vax must appear in the Connected-to column rendered as a link
    # with the computer model name ("VAX-11/780") as link text — NOT the serial
    # number. The view uses computer_model.name for peer display.
    # No connection_type is set on this group, so the Type column renders "—".
    login_as owners(:one)
    get computer_path(computers(:alice_pdp11))
    assert_response :success
    assert_includes response.body, "Lab setup",
      "Group label should appear in the Connections section"
    assert_includes response.body, computer_models(:vax11_780).name,
      "Peer computer model name should appear as link text in the Connected-to column"
  end

  test "show without connections renders empty-state message" do
    # unassigned_condition_test is owned by alice and has no connection_members.
    # The Connections section must show the empty-state paragraph rather than
    # a table.
    login_as owners(:one)
    get computer_path(computers(:unassigned_condition_test))
    assert_response :success
    assert_includes response.body, "No connections recorded",
      "Empty-state message should appear for a device with no connections"
  end

  # ---------------------------------------------------------------------------
  # Show — software section (Session E)
  # ---------------------------------------------------------------------------
  #
  # Fixture software data:
  #   alice_pdp11           → alice_vms (software_name: vms) — populated state
  #   unassigned_condition_test → no software items           — empty state

  test "show with software renders software name in software section" do
    # alice_pdp11 has alice_vms installed on it.
    # The software name (derived from the fixture at test time — never hardcoded)
    # must appear in the Software section as a link to software_item_path.
    # The link text is software_name.name; the href contains the item's id.
    item = software_items(:alice_vms)
    login_as owners(:one)

    get computer_path(computers(:alice_pdp11))

    assert_response :success
    assert_includes response.body, item.software_name.name,
      "Software name should appear in the Software section table"
    assert_includes response.body, software_item_path(item),
      "Link to software_items/show should appear in the Software section"
  end

  test "show without software renders software empty-state message" do
    # unassigned_condition_test has no software items.
    # The Software section must show the empty-state paragraph.
    login_as owners(:one)

    get computer_path(computers(:unassigned_condition_test))

    assert_response :success
    assert_includes response.body, "No software installed on this",
      "Empty-state message should appear for a device with no software"
  end
end
