# decor/test/controllers/sessions_controller_test.rb
# version 1.0
# v1.0 (Session 20): New file. Tests SessionsController login/logout behaviour,
#   focused on last_login_at stamping introduced in v1.1 of the controller.
#   Covers: successful login stamps timestamp, failed login does not stamp,
#   logout works and destroys session.

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  # ── login (create) ──────────────────────────────────────────────────────────

  test "successful login stamps last_login_at" do
    alice = owners(:one)

    # Confirm no timestamp before login
    assert_nil alice.last_login_at

    freeze_time do
      post session_path, params: { user_name: "alice", password: "DecorAdmin2026!" }
      alice.reload
      assert_equal Time.current, alice.last_login_at
    end

    assert_redirected_to root_path
  end

  test "failed login does not stamp last_login_at" do
    alice = owners(:one)

    post session_path, params: { user_name: "alice", password: "wrongpassword" }
    alice.reload

    assert_nil alice.last_login_at
    assert_response :unprocessable_entity
  end

  test "successful login redirects to root with notice" do
    post session_path, params: { user_name: "alice", password: "DecorAdmin2026!" }
    assert_redirected_to root_path
    assert_equal "Logged in successfully.", flash[:notice]
  end

  test "failed login renders login form again" do
    post session_path, params: { user_name: "alice", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_equal "Invalid username or password.", flash[:alert]
  end

  test "login is case-insensitive on user_name" do
    post session_path, params: { user_name: "ALICE", password: "DecorAdmin2026!" }
    assert_redirected_to root_path
  end

  # ── logout (destroy) ────────────────────────────────────────────────────────

  test "logout redirects to root with notice" do
    login_as owners(:one)
    delete session_path
    assert_redirected_to root_path
    assert_equal "Logged out successfully.", flash[:notice]
  end
end
