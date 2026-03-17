# decor/test/controllers/owners_controller_destroy_test.rb - version 1.3
# v1.3 (Session 28): Changed serial numbers in "should delete all associated computers"
#   test from "TEST-001"/"TEST-002" to "DESTROY-SN-001"/"DESTROY-SN-002".
#   alice has a pdp11_70 fixture (unassigned_condition_test) with serial_number
#   "TEST-001". The new unique index on (owner_id, computer_model_id, serial_number)
#   correctly rejects a second pdp11_70/"TEST-001" for the same owner, causing a
#   RecordInvalid error. Fix: use serials guaranteed not to appear in any fixture.
# v1.2: Added test to verify delete form uses DELETE method (not caught by nested
#   form bug). Fixed fixture references, authorization redirect, bob's asset count.

require "test_helper"

class OwnersControllerDestroyTest < ActionDispatch::IntegrationTest
  # Test uses centralized authentication from test/support/authentication_helper.rb
  # Password constants: TEST_PASSWORD_ALICE, TEST_PASSWORD_BOB

  setup do
    @alice = owners(:one)  # Admin user
    @bob = owners(:two)    # Regular user
  end

  # Successful deletion tests

  test "should delete own account with correct password" do
    login_as(@alice)

    assert_difference("Owner.count", -1) do
      delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    end

    assert_redirected_to root_path
    assert_equal "Account 'alice' and all associated data have been permanently deleted.", flash[:notice]
  end

  test "delete form uses DELETE method not PATCH" do
    login_as(@alice)

    assert_difference("Owner.count", -1) do
      delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    end

    assert_redirected_to root_path
    assert_nil flash[:alert]&.match(/Current password/)
  end

  test "should logout user after account deletion" do
    login_as(@alice)

    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }

    assert_nil session[:owner_id]

    get admin_owners_path
    assert_redirected_to root_path
    assert_equal "You must be an admin to do that.", flash[:alert]
  end

  test "should delete all associated computers when owner is deleted" do
    login_as(@alice)

    # Use serials that do not appear in any fixture.
    # Note: alice's fixtures include a pdp11_70 with serial "TEST-001"
    # (unassigned_condition_test), so "TEST-001"/"TEST-002" would violate
    # the unique index on (owner_id, computer_model_id, serial_number).
    computer1 = Computer.create!(
      owner: @alice,
      computer_model: computer_models(:pdp11_70),
      serial_number: "DESTROY-SN-001"
    )
    computer2 = Computer.create!(
      owner: @alice,
      computer_model: computer_models(:pdp11_70),
      serial_number: "DESTROY-SN-002"
    )

    alice_computer_ids = [@alice.computers.first.id, computer1.id, computer2.id]

    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }

    alice_computer_ids.each do |computer_id|
      assert_nil Computer.find_by(id: computer_id), "Computer #{computer_id} should be deleted"
    end
  end

  test "should delete all associated components when owner is deleted" do
    login_as(@alice)

    component1 = Component.create!(
      owner: @alice,
      component_type: component_types(:cpu_board),
      description: "Test component 1"
    )
    component2 = Component.create!(
      owner: @alice,
      component_type: component_types(:cpu_board),
      description: "Test component 2"
    )

    alice_component_ids = [component1.id, component2.id]

    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }

    alice_component_ids.each do |component_id|
      assert_nil Component.find_by(id: component_id), "Component #{component_id} should be deleted"
    end
  end

  # Password verification tests

  test "should not delete account with incorrect password" do
    login_as(@alice)

    assert_no_difference("Owner.count") do
      delete owner_path(@alice), params: { password: "wrongpassword" }
    end

    assert_redirected_to edit_owner_path(@alice)
    assert_equal "Incorrect password. Account was not deleted.", flash[:alert]
  end

  test "should not delete account without password" do
    login_as(@alice)

    assert_no_difference("Owner.count") do
      delete owner_path(@alice), params: { password: "" }
    end

    assert_redirected_to edit_owner_path(@alice)
    assert_equal "Incorrect password. Account was not deleted.", flash[:alert]
  end

  test "should not delete account when password param is missing" do
    login_as(@alice)

    assert_no_difference("Owner.count") do
      delete owner_path(@alice)
    end

    assert_redirected_to edit_owner_path(@alice)
    assert_equal "Incorrect password. Account was not deleted.", flash[:alert]
  end

  # Authorization tests

  test "should not allow user to delete another user's account" do
    login_as(@bob)

    assert_no_difference("Owner.count") do
      delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    end

    assert_redirected_to root_path
    assert_equal "You are not authorized to do that.", flash[:alert]
  end

  test "should require login to delete account" do
    assert_no_difference("Owner.count") do
      delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    end

    assert_redirected_to root_path
    assert_equal "You are not authorized to do that.", flash[:alert]
  end

  # Edge cases

  test "should delete account even when user has computers and components" do
    login_as(@bob)

    assert_equal 2, @bob.computers.count, "Bob should have 2 computers"
    assert_equal 2, @bob.components.count, "Bob should have 2 components"

    bob_computer_ids = @bob.computers.pluck(:id)
    bob_component_ids = @bob.components.pluck(:id)

    assert_difference("Owner.count", -1) do
      delete owner_path(@bob), params: { password: TEST_PASSWORD_BOB }
    end

    bob_computer_ids.each do |computer_id|
      assert_nil Computer.find_by(id: computer_id), "Computer #{computer_id} should be deleted"
    end

    bob_component_ids.each do |component_id|
      assert_nil Component.find_by(id: component_id), "Component #{component_id} should be deleted"
    end

    assert_redirected_to root_path
  end
end
