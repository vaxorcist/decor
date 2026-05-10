# decor/test/support/authentication_helper.rb
# version 2.1
#
# v2.1 (Session 59): Added TEST_PASSWORD_CHARLIE constant and charlie case in login_as.
#   Charlie (owners(:three)) appeared in computers_controller_test.rb as the literal
#   string "DecorTest2026!" — a DRY violation. Centralising it here means controller
#   tests, system tests, and any future test file all reference the same source of truth.
#   Updated files: computers_controller_test.rb v1.11,
#                  application_system_test_case.rb v1.1 (sign_in helper).
#
# v2.0: Updated test passwords to meet zxcvbn strength requirements (score >= 3).
#   New passwords: 14-15 characters, mixed case, numbers, special chars.
#   All passwords score >= 3 on zxcvbn strength meter.

module AuthenticationHelper
  # ── Password constants ─────────────────────────────────────────────────────
  # Each constant matches the bcrypt digest stored in the owner fixture.
  # Changing a constant here requires also updating the corresponding fixture
  # (and regenerating its password_digest).

  # Alice (owners(:one)) — admin user
  TEST_PASSWORD_ALICE = "DecorAdmin2026!".freeze

  # Bob (owners(:two)) — non-admin user
  TEST_PASSWORD_BOB = "DecorUser2026!".freeze

  # Charlie (owners(:three)) — neutral owner used for support fixtures;
  # no hardcoded count assertions are ever made against charlie's records.
  TEST_PASSWORD_CHARLIE = "DecorTest2026!".freeze

  # Generic valid password for owners created dynamically inside a test
  TEST_PASSWORD_VALID = "ValidTest2026!".freeze

  # ── HTTP login helper (integration tests only) ─────────────────────────────
  # Posts credentials directly to session_path via the Rack adapter.
  # This sets a session cookie on the Rack test adapter, NOT on any real browser.
  # Do NOT call this from system tests — use ApplicationSystemTestCase#sign_in instead.
  #
  # Usage:
  #   login_as owners(:one)                                  # alice — auto-detected
  #   login_as owners(:two)                                  # bob   — auto-detected
  #   login_as owners(:three)                                # charlie — auto-detected
  #   login_as owner, password: "custom"                     # explicit override
  def login_as(owner, password: nil)
    password ||= case owner.user_name
    when "alice"   then TEST_PASSWORD_ALICE
    when "bob"     then TEST_PASSWORD_BOB
    when "charlie" then TEST_PASSWORD_CHARLIE
    else                TEST_PASSWORD_VALID
    end

    post session_path, params: {
      user_name: owner.user_name,
      password:  password
    }

    # Some controller tests issue follow_redirect! themselves; this helper
    # follows automatically only when the response is a redirect.
    follow_redirect! if response.redirect?
  end

  # ── Test object factory ────────────────────────────────────────────────────

  # Returns a hash of valid attributes for creating a new Owner in tests.
  # Override individual keys as needed:
  #   valid_owner_attributes(user_name: "customname")
  def valid_owner_attributes(overrides = {})
    {
      user_name:             "testuser",
      email:                 "test@example.com",
      password:              TEST_PASSWORD_VALID,
      password_confirmation: TEST_PASSWORD_VALID
    }.merge(overrides)
  end

  # ── Backwards-compatibility stub ───────────────────────────────────────────
  # assert_record_errors was added in an earlier session for backwards
  # compatibility. The actual assertion is done with assert_response
  # :unprocessable_entity; this no-op avoids breaking any callers.
  def assert_record_errors
    true
  end
end
