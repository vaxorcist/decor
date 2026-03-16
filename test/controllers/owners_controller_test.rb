# decor/test/controllers/owners_controller_test.rb - version 1.4
# v1.4 (Session 25): Added peripherals sub-page smoke test.
#   Uses owner three (charlie) who has the charlie_dec_vt278 peripheral fixture,
#   so both the non-empty table path and the controller query are exercised.
# v1.3 (Session 23): Added three smoke tests for the new owner sub-page actions
#   (computers / appliances / components) introduced in owners_controller.rb v1.6.
# v1.2: Refactored to use centralized AuthenticationHelper constants.
# All password references use TEST_PASSWORD_VALID constant.

require "test_helper"

class OwnersControllerTest < ActionDispatch::IntegrationTest
  # Invite acceptance flow tests
  test "new displays invite acceptance form with valid token" do
    invite = Invite.create!(email: "newuser@example.com")

    get new_owner_url(token: invite.token)

    assert_response :success
    assert_select "h1", "Create Your Account"
    assert_select "input[type=email][value=?]", invite.email
  end

  test "new redirects with invalid token" do
    get new_owner_url(token: "invalid-token")

    assert_redirected_to root_path
    assert_equal "Invalid or expired invitation.", flash[:alert]
  end

  test "new redirects with expired token" do
    invite = Invite.create!(email: "expired@example.com")
    invite.update_column(:sent_at, 31.days.ago)

    get new_owner_url(token: invite.token)

    assert_redirected_to root_path
    assert_equal "Invalid or expired invitation.", flash[:alert]
  end

  test "new redirects with already accepted token" do
    invite = Invite.create!(email: "accepted@example.com")
    invite.accept!

    get new_owner_url(token: invite.token)

    assert_redirected_to root_path
    assert_equal "Invalid or expired invitation.", flash[:alert]
  end

  test "create accepts invite and creates owner account" do
    invite = Invite.create!(email: "newowner@example.com")

    assert_difference "Owner.count", 1 do
      post owners_url(token: invite.token), params: {
        owner: {
          user_name: "newuser",
          email: invite.email,
          password: TEST_PASSWORD_VALID,
          password_confirmation: TEST_PASSWORD_VALID,
          real_name: "New User",
          country: "US"
        }
      }
    end

    assert_redirected_to owner_path(Owner.last)
    assert_equal "Welcome! Your account has been created.", flash[:notice]

    # Verify invite was accepted
    invite.reload
    assert invite.accepted?

    # Verify owner was created correctly
    owner = Owner.last
    assert_equal "newuser", owner.user_name
    assert_equal invite.email, owner.email
    assert_equal "New User", owner.real_name
    assert_equal "US", owner.country

    # Verify user is logged in
    assert_equal owner.id, session[:owner_id]
  end

  test "create fails with invalid owner data" do
    invite = Invite.create!(email: "newowner@example.com")

    assert_no_difference "Owner.count" do
      post owners_url(token: invite.token), params: {
        owner: {
          user_name: "", # Invalid: blank username
          email: invite.email,
          password: TEST_PASSWORD_VALID,
          password_confirmation: TEST_PASSWORD_VALID
        }
      }
    end

    assert_response :unprocessable_entity
    assert_record_errors

    # Verify invite was not accepted
    invite.reload
    assert_not invite.accepted?
  end

  test "create fails with mismatched passwords" do
    invite = Invite.create!(email: "newowner@example.com")

    assert_no_difference "Owner.count" do
      post owners_url(token: invite.token), params: {
        owner: {
          user_name: "newuser",
          email: invite.email,
          password: TEST_PASSWORD_VALID,
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create redirects with expired token" do
    invite = Invite.create!(email: "expired@example.com")
    invite.update_column(:sent_at, 31.days.ago)

    assert_no_difference "Owner.count" do
      post owners_url(token: invite.token), params: {
        owner: {
          user_name: "newuser",
          email: invite.email,
          password: TEST_PASSWORD_VALID,
          password_confirmation: TEST_PASSWORD_VALID
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Invalid or expired invitation.", flash[:alert]
  end

  test "create redirects with already accepted token" do
    invite = Invite.create!(email: "accepted@example.com")
    invite.accept!

    assert_no_difference "Owner.count" do
      post owners_url(token: invite.token), params: {
        owner: {
          user_name: "newuser",
          email: invite.email,
          password: TEST_PASSWORD_VALID,
          password_confirmation: TEST_PASSWORD_VALID
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Invalid or expired invitation.", flash[:alert]
  end

  # ── Owner sub-page smoke tests ────────────────────────────────────────────
  # Each sub-page requires a logged-in user and renders a single collection
  # table. Tests verify that the routes resolve, the actions complete without
  # error, and the response is 200 OK.

  test "computers sub-page returns 200 when logged in" do
    # Log in as alice (owners(:one)) and view her computers sub-page.
    # alice has at least one computer in the fixtures (alice_vax).
    owner = owners(:one)
    login_as owner

    get computers_owner_url(owner)

    assert_response :success
  end

  test "appliances sub-page returns 200 when logged in" do
    # Log in as alice and view her appliances sub-page.
    # The page renders correctly even when the owner has no appliances
    # (the empty-state branch is exercised in that case).
    owner = owners(:one)
    login_as owner

    get appliances_owner_url(owner)

    assert_response :success
  end

  test "peripherals sub-page returns 200 when logged in" do
    # Log in as charlie (owners(:three)) and view the peripherals sub-page.
    # charlie has the charlie_dec_vt278 fixture (device_type: 2), so this
    # test exercises the non-empty table path as well as the controller query.
    owner = owners(:three)
    login_as owner

    get peripherals_owner_url(owner)

    assert_response :success
  end

  test "components sub-page returns 200 when logged in" do
    # Log in as alice and view her components sub-page.
    owner = owners(:one)
    login_as owner

    get components_owner_url(owner)

    assert_response :success
  end
end
