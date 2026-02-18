# decor/app/models/owner.rb - version 1.3
# Added password strength validation using zxcvbn (minimum score 3)
# Password validation: minimum 12 characters + strength check
# Password validation only applies when password is being set (create or update with password change)

class Owner < ApplicationRecord
  has_secure_password

  has_many :computers, dependent: :destroy
  has_many :components, dependent: :destroy

  PASSWORD_RESET_EXPIRY = 2.hours

  enum :real_name_visibility, { public: "public", members_only: "members_only", private: "private" }, prefix: true
  enum :country_visibility, { public: "public", members_only: "members_only", private: "private" }, prefix: true
  enum :email_visibility, { public: "public", members_only: "members_only", private: "private" }, prefix: true

  validates :user_name, presence: true,
                        uniqueness: { case_sensitive: false },
                        length: { maximum: 15 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, inclusion: { in: ISO3166::Country.codes }, allow_blank: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  # Password length validation
  # Minimum 12 characters for security (length-based approach per NIST/OWASP guidance)
  validates :password, length: { minimum: 12 }, if: :password_digest_changed?

  # Password strength validation using zxcvbn
  # Requires score >= 3 (0=very weak, 4=very strong)
  # zxcvbn checks against dictionary words, common patterns, keyboard patterns, etc.
  validate :password_strength, if: :password_digest_changed?

  scope :search, ->(query) do
    return all if query.blank?

    visibility_values = Current.owner.present? ? ["public", "members_only"] : ["public"]
    pattern = "%#{query}%"
    user_name_query = where("LOWER(user_name) LIKE LOWER(?)", pattern)
    real_name_query = where("real_name_visibility IN (?) AND LOWER(real_name) LIKE LOWER(?)", visibility_values, pattern)
    email_query = where("email_visibility IN (?) AND LOWER(email) LIKE LOWER(?)", visibility_values, pattern)

    user_name_query.or(real_name_query).or(email_query)
  end

  def country_name
    ISO3166::Country[country]&.common_name || ISO3166::Country[country]&.name
  end

  def country_emoji
    ISO3166::Country[country]&.emoji_flag
  end

  def self.countries_for_select
    ISO3166::Country.all.map { |c| [ c.common_name || c.name, c.alpha2 ] }.sort_by(&:first)
  end

  def generate_password_reset_token!
    update!(
      reset_password_token: SecureRandom.urlsafe_base64,
      reset_password_sent_at: Time.current
    )
  end

  def password_reset_expired?
    reset_password_sent_at.nil? || reset_password_sent_at < PASSWORD_RESET_EXPIRY.ago
  end

  def clear_password_reset_token!
    update!(reset_password_token: nil, reset_password_sent_at: nil)
  end

  private

  # Validate password strength using zxcvbn
  # Score 0-2: weak/very weak - rejected
  # Score 3-4: strong/very strong - accepted
  def password_strength
    return if password.blank? # presence is validated by has_secure_password

    require "zxcvbn"
    result = Zxcvbn.test(password)

    if result.score < 3
      # Provide helpful feedback from zxcvbn
      message = "is too weak"
      message += ": #{result.feedback.warning}" if result.feedback.warning.present?
      message += ". #{result.feedback.suggestions.first}" if result.feedback.suggestions.any?
      errors.add(:password, message)
    end
  end
end
