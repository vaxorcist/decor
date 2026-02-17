# decor/test/controllers/owners_controller_destroy_test.rb - version 1.2
# Added test to verify delete form uses DELETE method (not caught by nested form bug)
# Fixed test issues based on actual fixture data:
# - Fixed fixture references: pdp11 → pdp11_70, cpu → cpu_board
# - Fixed authorization redirect: require_owner redirects to root (not session)
# - Fixed logout test: use admin_owners_path instead of deleted owner's path
# - Fixed bob's asset test: bob has 2 computers + 2 components (not 0)

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
    
    # This test verifies the form calls destroy action, not update action
    # If form is nested incorrectly, it would trigger update and give password validation error
    assert_difference("Owner.count", -1) do
      delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    end
    
    # Should redirect to root, not back to edit page (which would indicate update action)
    assert_redirected_to root_path
    # Should NOT have password validation error from update action
    assert_nil flash[:alert]&.match(/Current password/)
  end

  test "should logout user after account deletion" do
    login_as(@alice)
    
    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    
    # Verify session is cleared
    assert_nil session[:owner_id]
    
    # Verify user cannot access protected admin pages (alice was admin)
    get admin_owners_path
    assert_redirected_to root_path
    assert_equal "You must be an admin to do that.", flash[:alert]
  end

  test "should delete all associated computers when owner is deleted" do
    login_as(@alice)
    
    # Create test computers for alice
    computer1 = Computer.create!(
      owner: @alice,
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-001"
    )
    computer2 = Computer.create!(
      owner: @alice,
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-002"
    )
    
    alice_computer_ids = [@alice.computers.first.id, computer1.id, computer2.id]
    
    # Delete account
    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    
    # Verify all computers are deleted
    alice_computer_ids.each do |computer_id|
      assert_nil Computer.find_by(id: computer_id), "Computer #{computer_id} should be deleted"
    end
  end

  test "should delete all associated components when owner is deleted" do
    login_as(@alice)
    
    # Create test components for alice
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
    
    # Delete account
    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    
    # Verify all components are deleted
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
    # Not logged in
    
    assert_no_difference("Owner.count") do
      delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
    end
    
    # require_owner before_action redirects to root when not authorized
    assert_redirected_to root_path
    assert_equal "You are not authorized to do that.", flash[:alert]
  end

  # Edge cases

  test "should delete account even when user has computers and components" do
    login_as(@bob)
    
    # Verify bob has computers and components (from fixtures)
    # bob_pdp8, bob_vt100 (2 computers)
    # pdp8_memory, spare_power_supply (2 components)
    assert_equal 2, @bob.computers.count, "Bob should have 2 computers"
    assert_equal 2, @bob.components.count, "Bob should have 2 components"
    
    bob_computer_ids = @bob.computers.pluck(:id)
    bob_component_ids = @bob.components.pluck(:id)
    
    assert_difference("Owner.count", -1) do
      delete owner_path(@bob), params: { password: TEST_PASSWORD_BOB }
    end
    
    # Verify all of bob's computers were deleted
    bob_computer_ids.each do |computer_id|
      assert_nil Computer.find_by(id: computer_id), "Computer #{computer_id} should be deleted"
    end
    
    # Verify all of bob's components were deleted
    bob_component_ids.each do |component_id|
      assert_nil Component.find_by(id: component_id), "Component #{component_id} should be deleted"
    end
    
    assert_redirected_to root_path
  end
end
