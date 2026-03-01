# decor/test/controllers/components_controller_test.rb - version 1.0
# Tests for ComponentsController — destroy action source-param redirect behaviour.
# Added Session 11 (March 1, 2026): source=owner redirects to owner page;
# source=computer redirects to computer edit page (regression guard);
# default (no source) redirects to components index.
#
# Fixture notes:
#   owners(:one)            = alice (admin)
#   components(:pdp11_cpu)  = KD11-A CPU board, owner: alice, computer: alice_pdp11
#   computers(:alice_pdp11) = alice's PDP-11/70 — used as redirect target in
#                             source=computer test; survives component deletion.
#   Each test runs in a rolled-back transaction, so the same fixture is
#   available independently in every test.

require "test_helper"

class ComponentsControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Destroy — source=owner redirect
  # ---------------------------------------------------------------------------

  test "destroy with source=owner redirects to owner page" do
    # When a component is deleted from the owner's show page, the user should
    # be returned to that owner's page, not the components index.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "owner" }
    end
    assert_redirected_to owner_path(owners(:one))
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  test "destroy without source redirects to components index" do
    # Default behaviour (no source param): redirect to the components index.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu))
    end
    assert_redirected_to components_path
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  test "destroy with source=computer redirects to computer edit page" do
    # Regression guard: the pre-existing source=computer behaviour (added before
    # Session 11) must not have been broken by the new source=owner branch.
    # Deleting a component from the computer edit page returns the user there.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "computer" }
    end
    assert_redirected_to edit_computer_path(computers(:alice_pdp11))
    assert_equal "Component was successfully deleted.", flash[:notice]
  end
end
