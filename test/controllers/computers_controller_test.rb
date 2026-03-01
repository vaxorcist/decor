# decor/test/controllers/computers_controller_test.rb - version 1.0
# Tests for ComputersController — destroy action source-param redirect behaviour.
# Added Session 11 (March 1, 2026): source=owner redirects to owner page;
# default (no source) redirects to computers index.
#
# Fixture notes:
#   owners(:one)          = alice (admin)
#   computers(:alice_pdp11) = alice's PDP-11/70, serial SN12345
#   alice_pdp11 has dependent components (nullify) — deletion is safe.
#   Each test runs in a rolled-back transaction, so the same fixture is
#   available independently in every test.

require "test_helper"

class ComputersControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Destroy — source=owner redirect
  # ---------------------------------------------------------------------------

  test "destroy with source=owner redirects to owner page" do
    # When a computer is deleted from the owner's show page, the user should
    # be returned to that owner's page, not the computers index.
    login_as owners(:one) # alice
    assert_difference "Computer.count", -1 do
      delete computer_url(computers(:alice_pdp11)), params: { source: "owner" }
    end
    assert_redirected_to owner_path(owners(:one))
    assert_equal "Computer was successfully deleted.", flash[:notice]
  end

  test "destroy without source redirects to computers index" do
    # Default behaviour (no source param): redirect to the computers index.
    login_as owners(:one) # alice
    assert_difference "Computer.count", -1 do
      delete computer_url(computers(:alice_pdp11))
    end
    assert_redirected_to computers_path
    assert_equal "Computer was successfully deleted.", flash[:notice]
  end
end
