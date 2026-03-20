# decor/test/controllers/connection_groups_controller_test.rb - version 1.0
# Session 36: Part 4 — Owner ConnectionGroup CRUD.
#
# Covers:
#   Authentication:  unauthenticated requests redirect to new_session_path.
#   Authorisation:   an owner cannot access or modify another owner's groups
#                    (set_owner redirects to root_path).
#   index:           renders successfully, shows own groups, does not show
#                    another owner's groups.
#   new:             renders the form.
#   create (valid):  creates the group, redirects to index with notice.
#   create (invalid): only 1 member fails minimum_two_members validation;
#                     re-renders new with status 422.
#   edit:            renders the form with existing data.
#   update (valid):  updates the group, redirects to index with notice.
#   update (invalid): label over 100 chars fails validation; re-renders edit 422.
#   destroy:         destroys the group, redirects to index with notice.
#   auth-destroy:    bob cannot destroy alice's group.
#
# Fixture notes:
#   owners(:one)                    = alice (admin, password via detect_password)
#   owners(:two)                    = bob   (non-admin, password via detect_password)
#   connection_groups(:alice_pdp11_vax)  — alice's group, label: "Lab setup"
#   connection_groups(:bob_pdp8_vt100)   — bob's group
#   computers(:alice_pdp11)              — alice's PDP-11/70
#   computers(:alice_vax)                — alice's VAX-11/780
#
# All tests run in a rolled-back transaction (standard minitest fixtures).

require "test_helper"

class ConnectionGroupsControllerTest < ActionDispatch::IntegrationTest

  # ---------------------------------------------------------------------------
  # Authentication — unauthenticated access
  # ---------------------------------------------------------------------------

  test "index redirects to login when not authenticated" do
    get owner_connection_groups_path(owners(:one))
    assert_redirected_to new_session_path
  end

  test "new redirects to login when not authenticated" do
    get new_owner_connection_group_path(owners(:one))
    assert_redirected_to new_session_path
  end

  test "create redirects to login when not authenticated" do
    post owner_connection_groups_path(owners(:one)), params: {
      connection_group: { label: "Test" }
    }
    assert_redirected_to new_session_path
  end

  # ---------------------------------------------------------------------------
  # Authorisation — owner can only access their own groups
  # ---------------------------------------------------------------------------

  test "index redirects to root when accessing another owner's groups" do
    # Bob tries to view alice's connection groups — set_owner fires and redirects.
    login_as owners(:two)
    get owner_connection_groups_path(owners(:one))
    assert_redirected_to root_path
  end

  test "edit redirects to root when accessing another owner's group" do
    login_as owners(:two)
    get edit_owner_connection_group_path(owners(:one), connection_groups(:alice_pdp11_vax))
    assert_redirected_to root_path
  end

  test "destroy redirects to root and does not destroy another owner's group" do
    login_as owners(:two)
    assert_no_difference "ConnectionGroup.count" do
      delete owner_connection_group_path(owners(:one), connection_groups(:alice_pdp11_vax))
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test "index renders successfully for the authenticated owner" do
    login_as owners(:one)
    get owner_connection_groups_path(owners(:one))
    assert_response :success
  end

  test "index shows own connection group label" do
    login_as owners(:one)
    get owner_connection_groups_path(owners(:one))
    assert_includes response.body, connection_groups(:alice_pdp11_vax).label,
      "Alice's group label should appear on her own connections index"
  end

  test "index does not show another owner's group label" do
    login_as owners(:one)
    get owner_connection_groups_path(owners(:one))
    assert_not_includes response.body, connection_groups(:bob_pdp8_vt100).label,
      "Bob's group label should not appear on alice's connections index"
  end

  # ---------------------------------------------------------------------------
  # New
  # ---------------------------------------------------------------------------

  test "new renders the connection group form" do
    login_as owners(:one)
    get new_owner_connection_group_path(owners(:one))
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # Create
  # ---------------------------------------------------------------------------

  test "create with valid params (2 members) creates group and redirects" do
    login_as owners(:one)
    assert_difference "ConnectionGroup.count", 1 do
      post owner_connection_groups_path(owners(:one)), params: {
        connection_group: {
          label: "New test group",
          connection_members_attributes: {
            "0" => { computer_id: computers(:alice_pdp11).id },
            "1" => { computer_id: computers(:alice_vax).id }
          }
        }
      }
    end
    assert_redirected_to owner_connection_groups_path(owners(:one))
    assert_equal "Connection group was successfully created.", flash[:notice]
  end

  test "create with only 1 member re-renders new with validation error" do
    # minimum_two_members validation requires at least 2 active members.
    login_as owners(:one)
    assert_no_difference "ConnectionGroup.count" do
      post owner_connection_groups_path(owners(:one)), params: {
        connection_group: {
          label: "Undersized group",
          connection_members_attributes: {
            "0" => { computer_id: computers(:alice_pdp11).id }
          }
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with no members re-renders new with validation error" do
    # An empty submission (all blank rows discarded by reject_if: :all_blank)
    # produces zero members — also fails minimum_two_members.
    login_as owners(:one)
    assert_no_difference "ConnectionGroup.count" do
      post owner_connection_groups_path(owners(:one)), params: {
        connection_group: { label: "No members" }
      }
    end
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # Edit
  # ---------------------------------------------------------------------------

  test "edit renders the form with existing group data" do
    login_as owners(:one)
    get edit_owner_connection_group_path(owners(:one), connection_groups(:alice_pdp11_vax))
    assert_response :success
    assert_includes response.body, connection_groups(:alice_pdp11_vax).label,
      "Edit form should display the group's existing label"
  end

  # ---------------------------------------------------------------------------
  # Update
  # ---------------------------------------------------------------------------

  test "update with valid params updates the group and redirects" do
    login_as owners(:one)
    patch owner_connection_group_path(owners(:one), connection_groups(:alice_pdp11_vax)), params: {
      connection_group: { label: "Updated label" }
    }
    assert_redirected_to owner_connection_groups_path(owners(:one))
    assert_equal "Connection group was successfully updated.", flash[:notice]
    assert_equal "Updated label", connection_groups(:alice_pdp11_vax).reload.label
  end

  test "update with a label over 100 characters re-renders edit with validation error" do
    # Label validates length: maximum 100 (from ConnectionGroup model).
    login_as owners(:one)
    patch owner_connection_group_path(owners(:one), connection_groups(:alice_pdp11_vax)), params: {
      connection_group: { label: "x" * 101 }
    }
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test "destroy deletes the group and redirects to index with notice" do
    login_as owners(:one)
    assert_difference "ConnectionGroup.count", -1 do
      delete owner_connection_group_path(owners(:one), connection_groups(:alice_pdp11_vax))
    end
    assert_redirected_to owner_connection_groups_path(owners(:one))
    assert_equal "Connection group was successfully deleted.", flash[:notice]
  end

end
