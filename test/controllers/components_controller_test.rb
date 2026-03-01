# decor/test/controllers/components_controller_test.rb - version 1.1
# Added: "destroy with source=computer_show redirects to computer show page"
#   Covers the new source=computer_show branch added in components_controller v1.5
#   (deletion from computers/show stays on the computer show page).
#
# Fixture notes:
#   owners(:one)            = alice (admin)
#   components(:pdp11_cpu)  = KD11-A CPU board, owner: alice, computer: alice_pdp11
#   computers(:alice_pdp11) = alice's PDP-11/70 — redirect target for computer_show test
#   Each test runs in a rolled-back transaction, so the same fixture is
#   available independently in every test.

require "test_helper"

class ComponentsControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Destroy — source param redirect behaviour
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

  test "destroy with source=computer_show redirects to computer show page" do
    # When a component is deleted from the computer show page, the user should
    # stay on that computer's show page (not be sent to the edit page or index).
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "computer_show" }
    end
    assert_redirected_to computer_path(computers(:alice_pdp11))
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  test "destroy with source=computer redirects to computer edit page" do
    # Regression guard: the pre-existing source=computer behaviour (added before
    # Session 11) must not have been broken by the new branches.
    # Deleting a component from the computer edit page returns the user there.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "computer" }
    end
    assert_redirected_to edit_computer_path(computers(:alice_pdp11))
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
end
