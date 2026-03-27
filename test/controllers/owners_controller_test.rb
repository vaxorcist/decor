# decor/test/controllers/owners_controller_test.rb
# version 1.8
# v1.8 (Session 41): Appliances → Peripherals merger Phase 2.
#   Removed "appliances sub-page returns 200 when logged in" test — the
#   appliances action and its route have been removed from OwnersController.
# v1.7 (Session 39): Corrected the unauthenticated connections test.
# v1.6 (Session 39): Corrected two connections sub-page tests.
# v1.5 (Session 39): Added three smoke tests for the connections sub-page.
# v1.4 (Session 25): Added peripherals sub-page smoke test.
# v1.3 (Session 23): Added computers / appliances / components sub-page smoke tests.
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
  # OwnersController has no require_login before_action. All read-only
  # sub-pages (computers, peripherals, components, connections) are publicly
  # accessible. Tests verify routes resolve and actions succeed.

  test "computers sub-page returns 200 when logged in" do
    owner = owners(:one)
    login_as owner

    get computers_owner_url(owner)

    assert_response :success
  end

  test "peripherals sub-page returns 200 when logged in" do
    # charlie has both dec_unibus_router and charlie_dec_vt278 (device_type: peripheral),
    # exercising the non-empty table path. dec_unibus_router was formerly an appliance;
    # it is now a peripheral after the Session 41 merger.
    owner = owners(:three)
    login_as owner

    get peripherals_owner_url(owner)

    assert_response :success
  end

  test "components sub-page returns 200 when logged in" do
    owner = owners(:one)
    login_as owner

    get components_owner_url(owner)

    assert_response :success
  end

  # ── Connections sub-page tests ────────────────────────────────────────────
  # connections has no ownership guard and no login requirement —
  # consistent with all other read-only sub-pages in this controller.

  test "connections sub-page returns 200 when logged in as own page" do
    # bob has the bob_pdp8_vt100 fixture (2 members), exercising the
    # non-empty table path and the eager-load query.
    owner = owners(:two)
    login_as owner

    get connections_owner_url(owner)

    assert_response :success
  end

  test "connections sub-page returns 200 when a different logged-in owner views it" do
    # No ownership guard on read-only sub-pages — any logged-in user may view.
    alice = owners(:one)
    bob   = owners(:two)
    login_as alice

    get connections_owner_url(bob)

    assert_response :success
  end

  test "connections sub-page returns 200 when not authenticated" do
    # OwnersController has no require_login before_action.
    # Unauthenticated requests to read-only sub-pages are permitted.
    owner = owners(:two)

    get connections_owner_url(owner)

    assert_response :success
  end
end
