# decor/test/models/owner_test.rb - version 1.4
# Updated to use strong test passwords that pass zxcvbn validation
# Added password strength validation tests
# All password references use TEST_PASSWORD_VALID constant from AuthenticationHelper

require "test_helper"

class OwnerTest < ActiveSupport::TestCase
  def valid_attributes
    {
      user_name: "testuser",
      email: "test@example.com",
      password: TEST_PASSWORD_VALID,
      password_confirmation: TEST_PASSWORD_VALID
    }
  end

  # Valid owner
  test "valid owner with required attributes" do
    owner = Owner.new(valid_attributes)
    assert owner.valid?
  end

  test "valid owner with all attributes" do
    owner = Owner.new(
      valid_attributes.merge(
        real_name: "Test User",
        website: "https://example.com",
        country: "US",
        real_name_visibility: :public,
        country_visibility: :members_only,
        email_visibility: :private
      )
    )
    assert owner.valid?
  end

  # User name validations
  test "user_name is required" do
    owner = Owner.new(valid_attributes.merge(user_name: nil))
    assert_not owner.valid?
    assert_includes owner.errors[:user_name], "can't be blank"
  end

  test "user_name must be unique case-insensitively" do
    Owner.create!(valid_attributes)
    duplicate = Owner.new(valid_attributes.merge(user_name: "TESTUSER", email: "other@example.com"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_name], "has already been taken"
  end

  test "user_name must be 15 characters or less" do
    owner = Owner.new(valid_attributes.merge(user_name: "a" * 16))
    assert_not owner.valid?
    assert_includes owner.errors[:user_name], "is too long (maximum is 15 characters)"
  end

  test "user_name accepts 15 characters" do
    owner = Owner.new(valid_attributes.merge(user_name: "a" * 15))
    assert owner.valid?
  end

  # Email validations
  test "email is required" do
    owner = Owner.new(valid_attributes.merge(email: nil))
    assert_not owner.valid?
    assert_includes owner.errors[:email], "can't be blank"
  end

  test "email must be unique case-insensitively" do
    Owner.create!(valid_attributes)
    duplicate = Owner.new(valid_attributes.merge(user_name: "other", email: "TEST@EXAMPLE.COM"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "email must be valid format" do
    invalid_emails = [ "invalid", "invalid@", "@example.com", "invalid@.com" ]
    invalid_emails.each do |email|
      owner = Owner.new(valid_attributes.merge(email: email))
      assert_not owner.valid?, "#{email} should be invalid"
    end
  end

  test "email accepts valid formats" do
    valid_emails = [ "user@example.com", "user+tag@example.com", "user@sub.example.com" ]
    valid_emails.each do |email|
      owner = Owner.new(valid_attributes.merge(email: email))
      assert owner.valid?, "#{email} should be valid: #{owner.errors.full_messages}"
    end
  end

  # Password validations
  test "password is required on create" do
    owner = Owner.new(valid_attributes.merge(password: nil))
    assert_not owner.valid?
    assert_includes owner.errors[:password], "can't be blank"
  end

  test "password must be at least 12 characters" do
    owner = Owner.new(valid_attributes.merge(password: "short", password_confirmation: "short"))
    assert_not owner.valid?
    assert_includes owner.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "password with 11 characters is invalid" do
    password = "a" * 11
    owner = Owner.new(valid_attributes.merge(password: password, password_confirmation: password))
    assert_not owner.valid?
    assert_includes owner.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "password with exactly 12 characters is valid if strong" do
    # 12 characters with good strength
    password = "Strong12!@#*"
    owner = Owner.new(valid_attributes.merge(password: password, password_confirmation: password))
    assert owner.valid?, "Should be valid: #{owner.errors.full_messages}"
  end

  test "password with 16 characters is valid if strong" do
    # 16 characters with good strength
    password = "VeryStrong16!@#*"
    owner = Owner.new(valid_attributes.merge(password: password, password_confirmation: password))
    assert owner.valid?, "Should be valid: #{owner.errors.full_messages}"
  end

  test "password authentication works" do
    owner = Owner.create!(valid_attributes)
    assert owner.authenticate(TEST_PASSWORD_VALID)
    assert_not owner.authenticate("wrongpassword")
  end

  # Password strength validations (zxcvbn)
  test "password must have sufficient strength (score >= 3)" do
    weak_passwords = [
      "password12345",      # dictionary word + sequential
      "123456789012",       # sequential numbers
      "aaaaaaaaaaaa",       # repeated characters
      "qwertyuiop12"        # keyboard pattern
    ]

    weak_passwords.each do |password|
      owner = Owner.new(valid_attributes.merge(password: password, password_confirmation: password))
      assert_not owner.valid?, "#{password} should be invalid (too weak)"
      assert owner.errors[:password].any? { |msg| msg.include?("too weak") },
             "Should have 'too weak' error for #{password}"
    end
  end

  test "password with good strength passes validation" do
    strong_passwords = [
      "DecorAdmin2026!",        # mixed case, numbers, special (our test password)
      "VeryStrongPass2026!",    # mixed case, numbers, special
      "correct-horse-battery"   # passphrase style (xkcd classic)
    ]

    strong_passwords.each do |password|
      owner = Owner.new(valid_attributes.merge(password: password, password_confirmation: password))
      assert owner.valid?, "#{password} should be valid: #{owner.errors.full_messages}"
    end
  end

  test "password strength validation provides helpful feedback" do
    owner = Owner.new(valid_attributes.merge(password: "password12345", password_confirmation: "password12345"))
    assert_not owner.valid?

    error_message = owner.errors[:password].first
    assert_not_nil error_message
    # zxcvbn provides suggestions in the error message
    assert error_message.length > 15, "Error should include feedback: #{error_message}"
  end

  test "password length validation only applies when password is being set" do
    # Create owner with valid password
    owner = Owner.create!(valid_attributes)

    # Update other attributes without touching password - should be valid
    owner.real_name = "Updated Name"
    assert owner.valid?, "Should be valid when not changing password: #{owner.errors.full_messages}"
  end

  # Country validations
  test "country can be blank" do
    owner = Owner.new(valid_attributes.merge(country: nil))
    assert owner.valid?
  end

  test "country must be valid ISO code" do
    owner = Owner.new(valid_attributes.merge(country: "XX"))
    assert_not owner.valid?
    assert_includes owner.errors[:country], "is not included in the list"
  end

  test "country accepts valid ISO codes" do
    %w[US GB DE FR JP AU].each do |code|
      owner = Owner.new(valid_attributes.merge(country: code))
      assert owner.valid?, "#{code} should be valid"
    end
  end

  # Website validations
  test "website can be blank" do
    owner = Owner.new(valid_attributes.merge(website: nil))
    assert owner.valid?
  end

  test "website must be valid URL" do
    invalid_urls = [ "not-a-url", "ftp://example.com", "javascript:alert(1)" ]
    invalid_urls.each do |url|
      owner = Owner.new(valid_attributes.merge(website: url))
      assert_not owner.valid?, "#{url} should be invalid"
    end
  end

  test "website accepts valid HTTP/HTTPS URLs" do
    valid_urls = [ "http://example.com", "https://example.com", "https://sub.example.com/path" ]
    valid_urls.each do |url|
      owner = Owner.new(valid_attributes.merge(website: url))
      assert owner.valid?, "#{url} should be valid: #{owner.errors.full_messages}"
    end
  end

  # Visibility enums
  test "visibility enums accept valid values" do
    %i[public members_only private].each do |visibility|
      owner = Owner.new(valid_attributes.merge(
        real_name_visibility: visibility,
        country_visibility: visibility,
        email_visibility: visibility
      ))
      assert owner.valid?
    end
  end

  test "visibility enum query methods work" do
    owner = Owner.new(valid_attributes.merge(email_visibility: :members_only))
    assert owner.email_visibility_members_only?
    assert_not owner.email_visibility_public?
    assert_not owner.email_visibility_private?
  end

  # Helper methods
  test "country_name returns full country name" do
    owner = Owner.new(valid_attributes.merge(country: "US"))
    assert_equal "United States", owner.country_name
  end

  test "country_name returns nil for blank country" do
    owner = Owner.new(valid_attributes.merge(country: nil))
    assert_nil owner.country_name
  end

  test "countries_for_select returns sorted array of name and code pairs" do
    countries = Owner.countries_for_select
    assert_kind_of Array, countries
    assert countries.length > 200
    assert_equal 2, countries.first.length
    assert_equal "Afghanistan", countries.first[0]
    assert_equal "AF", countries.first[1]
  end

  # Associations
  test "has many computers" do
    owner = owners(:one)
    assert_respond_to owner, :computers
    assert owner.computers.count >= 0
  end

  test "has many components" do
    owner = owners(:one)
    assert_respond_to owner, :components
    assert owner.components.count >= 0
  end

  # Fixtures
  test "fixtures are valid" do
    assert owners(:one).valid?, owners(:one).errors.full_messages.join(", ")
    assert owners(:two).valid?, owners(:two).errors.full_messages.join(", ")
  end
end
