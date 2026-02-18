# decor/test/controllers/owners_controller_password_test.rb - version 1.6
# Updated test passwords to pass zxcvbn strength validation (score >= 3)
# Uses "StrongTestPass2026!" instead of "newpass456789"
# Refactored to use centralized AuthenticationHelper constants
# All password references use TEST_PASSWORD_ALICE and TEST_PASSWORD_BOB constants

require "test_helper"

class OwnersControllerPasswordTest < ActionDispatch::IntegrationTest
  def setup
    @owner = owners(:one)
  end

  test "should update profile without changing password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { real_name: "Updated Name", website: "https://newwebsite.com" } }
    assert_redirected_to owner_path(@owner)
    @owner.reload
    assert_equal "Updated Name", @owner.real_name
    assert @owner.authenticate(TEST_PASSWORD_ALICE)
  end

  test "should change password with correct current password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: TEST_PASSWORD_ALICE, password: "StrongTestPass2026!", password_confirmation: "StrongTestPass2026!" } }
    assert_redirected_to owner_path(@owner)
    @owner.reload
    assert @owner.authenticate("StrongTestPass2026!")
  end

  test "should not change password with incorrect current password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "wrong", password: "StrongTestPass2026!", password_confirmation: "StrongTestPass2026!" } }
    assert_response :unprocessable_entity
    @owner.reload
    assert @owner.authenticate(TEST_PASSWORD_ALICE)
  end

  test "should not change password when confirmation does not match" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: TEST_PASSWORD_ALICE, password: "StrongTestPass2026!", password_confirmation: "different" } }
    assert_response :unprocessable_entity
    @owner.reload
    assert @owner.authenticate(TEST_PASSWORD_ALICE)
  end

  test "should not accept only current password without new password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: TEST_PASSWORD_ALICE, password: "", password_confirmation: "" } }
    assert_response :unprocessable_entity
  end

  test "should not accept new password without current password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "", password: "StrongTestPass2026!", password_confirmation: "StrongTestPass2026!" } }
    assert_response :unprocessable_entity
  end

  test "should change password and update profile fields simultaneously" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { real_name: "New Name", website: "https://newsite.com", current_password: TEST_PASSWORD_ALICE, password: "StrongTestPass2026!", password_confirmation: "StrongTestPass2026!" } }
    assert_redirected_to owner_path(@owner)
    @owner.reload
    assert_equal "New Name", @owner.real_name
    assert @owner.authenticate("StrongTestPass2026!")
  end
end
