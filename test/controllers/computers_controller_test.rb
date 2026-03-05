# decor/test/controllers/computers_controller_test.rb - version 1.3
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
  # Destroy — source=owner redirect
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
end
