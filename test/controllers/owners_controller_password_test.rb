# decor/test/controllers/owners_controller_password_test.rb - version 1.3
# Tests for password change functionality - CORRECTED authentication
# Uses user_name (not email) to match SessionsController#create expectations

require "test_helper"

class OwnersControllerPasswordTest < ActionDispatch::IntegrationTest
  def setup
    @owner = owners(:one)
  end

  def login_as(owner, password = "password123")
    post session_path, params: { 
      user_name: owner.user_name,  # SessionsController expects user_name, not email
      password: password 
    }
  end

  test "should update profile without changing password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { real_name: "Updated Name", website: "https://newwebsite.com" } }
    assert_redirected_to owner_path(@owner)
    @owner.reload
    assert_equal "Updated Name", @owner.real_name
    assert @owner.authenticate("password123")
  end

  test "should change password with correct current password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "password123", password: "newpass456", password_confirmation: "newpass456" } }
    assert_redirected_to owner_path(@owner)
    @owner.reload
    assert @owner.authenticate("newpass456")
  end

  test "should not change password with incorrect current password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "wrong", password: "newpass456", password_confirmation: "newpass456" } }
    assert_response :unprocessable_entity
    @owner.reload
    assert @owner.authenticate("password123")
  end

  test "should not change password when confirmation does not match" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "password123", password: "newpass456", password_confirmation: "different" } }
    assert_response :unprocessable_entity
    @owner.reload
    assert @owner.authenticate("password123")
  end

  test "should not accept only current password without new password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "password123", password: "", password_confirmation: "" } }
    assert_response :unprocessable_entity
  end

  test "should not accept new password without current password" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { current_password: "", password: "newpass456", password_confirmation: "newpass456" } }
    assert_response :unprocessable_entity
  end

  test "should change password and update profile fields simultaneously" do
    login_as(@owner)
    patch owner_path(@owner), params: { owner: { real_name: "New Name", website: "https://newsite.com", current_password: "password123", password: "newpass456", password_confirmation: "newpass456" } }
    assert_redirected_to owner_path(@owner)
    @owner.reload
    assert_equal "New Name", @owner.real_name
    assert @owner.authenticate("newpass456")
  end
end
