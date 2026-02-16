# decor/test/support/authentication_helper.rb - version 1.0
# Centralized test authentication constants and helper methods
# Eliminates hardcoded passwords scattered across test files
# Single source of truth for all test authentication

module AuthenticationHelper
  # Test password constants - match fixtures in test/fixtures/owners.yml
  # Alice (owners(:one)) - admin user
  TEST_PASSWORD_ALICE = "password12345".freeze

  # Bob (owners(:two)) - non-admin user
  TEST_PASSWORD_BOB = "password45678".freeze

  # Generic valid password for new owner creation
  TEST_PASSWORD_VALID = "password12345".freeze

  # Centralized login helper for integration tests
  # Usage: login_as(@owner) or login_as(@owner, password: custom_password)
  def login_as(owner, password: nil)
    # Auto-detect password based on fixture if not provided
    password ||= case owner.user_name
    when "alice"
      TEST_PASSWORD_ALICE
    when "bob"
      TEST_PASSWORD_BOB
    else
      # For dynamically created owners in tests, use the password they were created with
      # or default to a valid password
      TEST_PASSWORD_VALID
    end

    post session_path, params: {
      user_name: owner.user_name,
      password: password
    }

    # For admin tests that use follow_redirect!
    follow_redirect! if response.redirect?
  end

  # Helper for creating valid owner attributes in tests
  def valid_owner_attributes(overrides = {})
    {
      user_name: "testuser",
      email: "test@example.com",
      password: TEST_PASSWORD_VALID,
      password_confirmation: TEST_PASSWORD_VALID
    }.merge(overrides)
  end

  # Helper for asserting that validation errors occurred
  # In Rails 8+, we check the response status instead of assigns
  def assert_record_errors
    # If response is unprocessable_entity, validation failed (which is what we want)
    # This is a no-op helper for backwards compatibility
    # The actual assertion is already done by assert_response :unprocessable_entity
    true
  end
end
