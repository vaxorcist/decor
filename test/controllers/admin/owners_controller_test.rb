# decor/test/controllers/admin/owners_controller_test.rb
# version 1.3
# v1.3 (Session 58): Fixed 5 test failures found on first run.
#   1. "non-admin cannot access" — added `delete session_path` before
#      `login_as non_admin`. Setup logs in as alice; if login_as(bob) fails
#      silently, alice's admin session persists → 200 instead of redirect.
#      Explicit logout guarantees a clean session before the non-admin login.
#   2. "update sets newsletter to 1" — added `admin: "false"` to params.
#   3. "update shows a success notice" — added `admin: "false"` to params.
#   4. "update changes user_name" — added `admin: "false"` to params.
#   5. "update rejects blank user_name" — added `admin: "false"` to params.
#   Root cause of 2–5: ActiveModel::Type::Boolean.cast(nil) returns nil (not false).
#   When admin: is absent from params, @owner.admin = nil → NOT NULL constraint.
#   Rule: every PATCH to a non-self owner record MUST include an explicit
#   admin: value. See SESSION_HANDOVER.md v62.0 "Admin update tests" notice.
# v1.2 (Session 58): Merged v1.1 with Session 58 v1.0.
#
#   Changes vs v1.1 (existing file):
#     - Renamed from admin_owners_controller_test.rb to owners_controller_test.rb
#       (wrong filename caused the file to be silently skipped by the test runner).
#     - Class declaration changed from `module Admin; class OwnersControllerTest`
#       to `class Admin::OwnersControllerTest` — consistent with the rest of the
#       project's controller test files.
#     - Added `include ActionMailer::TestHelper` — required for assert_emails /
#       assert_enqueued_emails; ActionDispatch::IntegrationTest does not include it.
#     - `login_as @admin` and `ActionMailer::Base.deliveries.clear` moved into setup.
#     - send_password_reset test: kept `perform_enqueued_jobs` from v1.1 (correct —
#       the controller uses deliver_later, not deliver_now). The bare assert_emails
#       in the Session 58 v1.0 file was wrong and is replaced here.
#     - Added tests from Session 58 v1.0:
#         unauthenticated redirect (auth guard)
#         update newsletter to 0 / to 1 / shows notice
#         update user_name — success and blank-name rejection
#         destroy — non-self owner and self-delete block
#         send_password_reset — token generation
#
#   Tests retained from v1.1:
#     index lists owners (assert_select version)
#     send_password_reset sends email (perform_enqueued_jobs version)
#     edit displays owner admin form (assert_select version)
#     can grant admin to another owner
#     can revoke admin from another owner
#     cannot remove own admin privileges
#     can edit own profile but admin stays true
#     non-admin cannot access admin owners index
#
# v1.1: Refactored to use centralized AuthenticationHelper.
# v1.0: Initial file (Session 58, produced but never committed — superseded here).

require "test_helper"

class Admin::OwnersControllerTest < ActionDispatch::IntegrationTest
  # ActionMailer::TestHelper provides assert_emails / assert_enqueued_emails.
  # Must be included explicitly — ActionDispatch::IntegrationTest does not
  # include it automatically (unlike ActionMailer::TestCase which does).
  include ActionMailer::TestHelper

  setup do
    @admin = owners(:one)  # alice — admin: true
    login_as @admin
    # Clear deliveries before each test so email counts are independent.
    ActionMailer::Base.deliveries.clear
  end

  # ── Auth guards ───────────────────────────────────────────────────────────

  test "unauthenticated request to index redirects" do
    # Log out and verify the admin namespace is guarded.
    delete session_path
    get admin_owners_url
    assert_response :redirect
  end

  test "non-admin cannot access admin owners index" do
    # Setup logs in as alice (admin). Log out first so alice's session doesn't
    # persist — otherwise login_as(non_admin) may fail silently and alice's
    # admin session remains active, giving a 200 instead of a redirect.
    delete session_path
    login_as owners(:two)  # bob — admin: false

    get admin_owners_url

    assert_redirected_to root_path
  end

  # ── index ─────────────────────────────────────────────────────────────────

  test "index lists owners" do
    get admin_owners_url

    assert_response :success
    assert_select "h1", "Manage Owners"
    assert_select "td", owners(:two).user_name  # bob appears in the table
  end

  # ── edit ──────────────────────────────────────────────────────────────────

  test "edit displays owner admin form" do
    get edit_admin_owner_url(owners(:two))

    assert_response :success
    assert_select "h1", /Edit Owner/
    assert_select "input[type=checkbox][name='owner[admin]']"
  end

  # ── update — admin flag ───────────────────────────────────────────────────
  #
  # Admin::OwnersController#update (v1.2) reads :admin directly from params
  # and assigns it explicitly BEFORE calling update() to avoid Brakeman's
  # mass-assignment warning. :admin is NOT in owner_params.
  #
  # Self-demotion guard: fires when @owner == Current.owner && !requested_admin.
  # When :admin is absent from params, ActiveModel::Type::Boolean.cast(nil) → false,
  # so any PATCH to alice's own record that omits admin: triggers the guard.
  # Tests that update alice's own record for other reasons must include admin: "true".

  test "can grant admin to another owner" do
    other_owner = owners(:two)
    assert_not other_owner.admin?, "Precondition: bob should not be admin"

    patch admin_owner_url(other_owner), params: { owner: { admin: true } }

    assert_redirected_to admin_owners_path
    other_owner.reload
    assert other_owner.admin?
  end

  test "can revoke admin from another owner" do
    other_admin = owners(:two)
    other_admin.update!(admin: true)

    patch admin_owner_url(other_admin), params: { owner: { admin: false } }

    assert_redirected_to admin_owners_path
    other_admin.reload
    assert_not other_admin.admin?
  end

  test "cannot remove own admin privileges" do
    # Omitting admin: → cast(nil) = false → self-demotion guard fires.
    patch admin_owner_url(@admin), params: { owner: { admin: false } }

    assert_redirected_to edit_admin_owner_path(@admin)
    assert_match(/cannot remove your own admin/, flash[:alert])
    @admin.reload
    assert @admin.admin?
  end

  test "can edit own profile but admin stays true" do
    # Passing admin: true passes the self-demotion guard and saves normally.
    patch admin_owner_url(@admin), params: { owner: { admin: true } }

    assert_redirected_to admin_owners_path
    @admin.reload
    assert @admin.admin?
  end

  # ── update — newsletter preference ────────────────────────────────────────
  # owner_params permits :newsletter (0/1). These tests verify the toggle
  # works correctly via the admin interface independent of the owner interface.

  test "update sets newsletter to 0 (unsubscribe)" do
    # alice (one) starts at newsletter: 1 (subscribed per owners.yml v2.2).
    # Include admin: "true" to pass the self-demotion guard (alice == Current.owner).
    alice = owners(:one)
    assert_equal 1, alice.newsletter, "Precondition: alice starts subscribed"

    patch admin_owner_url(alice), params: {
      owner: {
        user_name:  alice.user_name,
        email:      alice.email,
        newsletter: 0,
        admin:      "true"  # prevents self-demotion redirect for alice's own record
      }
    }

    alice.reload
    assert_equal 0, alice.newsletter,
      "newsletter should be 0 after the admin sets it to 0"
    assert_redirected_to admin_owners_path
  end

  test "update sets newsletter to 1 (subscribe)" do
    # bob (two) starts at newsletter: 0 (unsubscribed per owners.yml v2.2).
    bob = owners(:two)
    assert_equal 0, bob.newsletter, "Precondition: bob starts unsubscribed"

    patch admin_owner_url(bob), params: {
      owner: {
        user_name:  bob.user_name,
        email:      bob.email,
        newsletter: 1,
        admin:      "false"  # must be explicit — cast(nil) → nil → NOT NULL violation
      }
    }

    bob.reload
    assert_equal 1, bob.newsletter,
      "newsletter should be 1 after the admin sets it to 1"
    assert_redirected_to admin_owners_path
  end

  test "update shows a success notice including the owner's user_name" do
    bob = owners(:two)
    patch admin_owner_url(bob), params: {
      owner: { user_name: bob.user_name, email: bob.email, newsletter: 1, admin: "false" }
    }
    assert_includes flash[:notice], bob.user_name
  end

  # ── update — user_name ────────────────────────────────────────────────────

  test "update changes user_name" do
    bob = owners(:two)

    patch admin_owner_url(bob), params: {
      owner: { user_name: "bobby", email: bob.email, newsletter: bob.newsletter, admin: "false" }
    }

    bob.reload
    assert_equal "bobby", bob.user_name
    assert_redirected_to admin_owners_path
  end

  test "update rejects blank user_name" do
    bob = owners(:two)

    patch admin_owner_url(bob), params: {
      owner: { user_name: "", email: bob.email, newsletter: bob.newsletter, admin: "false" }
    }

    assert_response :unprocessable_entity
    bob.reload
    assert_equal "bob", bob.user_name, "user_name should be unchanged after failed update"
  end

  # ── destroy ───────────────────────────────────────────────────────────────

  test "destroy removes a non-self owner" do
    bob = owners(:two)

    assert_difference "Owner.count", -1 do
      delete admin_owner_url(bob)
    end

    assert_redirected_to admin_owners_path
    assert_nil Owner.find_by(id: bob.id), "bob should be gone from the DB after destroy"
  end

  test "destroy cannot delete the currently logged-in admin" do
    alice = owners(:one)

    assert_no_difference "Owner.count" do
      delete admin_owner_url(alice)
    end

    assert_redirected_to admin_owners_path
    assert_includes flash[:alert], "cannot delete yourself"
    assert Owner.exists?(alice.id), "alice should still exist after self-delete attempt"
  end

  # ── send_password_reset ───────────────────────────────────────────────────
  # The controller calls PasswordResetMailer.reset_email(@owner).deliver_later.
  # deliver_later enqueues an ActiveJob — ActionMailer::Base.deliveries is NOT
  # populated until the job runs. perform_enqueued_jobs executes the queued
  # jobs synchronously within the block so deliveries is populated by the time
  # the assertions run.

  test "send_password_reset sends a password reset email" do
    owner = owners(:two)

    perform_enqueued_jobs do
      post send_password_reset_admin_owner_url(owner)
    end

    assert_redirected_to admin_owners_path
    assert_match(/password reset email/i, flash[:notice])
    assert ActionMailer::Base.deliveries.size > 0, "At least one email should have been delivered"
  end

  test "send_password_reset generates a reset token for the owner" do
    owner = owners(:two)
    assert_nil owner.reset_password_token, "Precondition: no existing token"

    perform_enqueued_jobs do
      post send_password_reset_admin_owner_url(owner)
    end

    owner.reload
    assert owner.reset_password_token.present?,
      "A reset token should be generated after send_password_reset"
    assert owner.reset_password_sent_at.present?,
      "reset_password_sent_at should be set after send_password_reset"
  end
end
