# decor/app/models/owner.rb
# version 1.7
# v1.7 (Session A, Storage Locations feature): Added
#   has_many :storage_locations, dependent: :destroy. Unlike the
#   has_many :computers / :connection_groups ordering note below, this
#   addition has no equivalent ordering dependency: when an owner is
#   destroyed, each StorageLocation's own has_many (added in Session C)
#   will nullify storage_location_id on any still-existing Computer/
#   Component/SoftwareItem before that record is itself destroyed via the
#   owner's other has_many associations — regardless of which collection
#   Rails processes first, no error results (a nullify against an
#   already-destroyed record simply finds nothing to update; a destroy
#   against a record whose storage_location_id was already nullified
#   destroys it as normal either way).
# v1.6 (Session 56): Newsletter feature.
#   - Added newsletter integer column support (0 = no newsletter, 1 = newsletter).
#   - Added validates :newsletter inclusion [0, 1].
#   - Added scope :newsletter_subscribed — returns all owners with newsletter = 1.
#     Used by Admin::NewslettersController to find send targets for "send to all".
#   - Added newsletter_subscribed? predicate — returns true when newsletter == 1.
#     Used by mailer and views to read preference as a boolean without repeating
#     the integer comparison throughout the codebase.
# v1.5 (Session 43): Added has_many :software_items, dependent: :destroy.
# v1.4 (Session 31): Added has_many :connection_groups, dependent: :destroy.
# v1.3: Added password strength validation using zxcvbn (minimum score 3).

class Owner < ApplicationRecord
  has_secure_password

  # NOTE: has_many :computers must be declared BEFORE has_many :connection_groups
  # so that Rails processes computer deletions first during owner destroy. This
  # ensures the ConnectionMember after_destroy callbacks fire before Rails
  # attempts to destroy connection_groups directly.
  has_many :computers, dependent: :destroy
  has_many :components, dependent: :destroy

  # Software items owned by this owner. Destroyed when the owner is deleted.
  has_many :software_items, dependent: :destroy

  # Connection groups owned by this owner. Destroyed after computers (see note above).
  has_many :connection_groups, dependent: :destroy

  # Private, owner-defined storage locations (Session A, Storage Locations
  # feature). Destroyed along with the owner — no ordering dependency on the
  # other associations above (see v1.7 changelog note).
  has_many :storage_locations, dependent: :destroy

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

  # newsletter column: 0 = opted out, 1 = subscribed (default).
  # Validated at application level; database enforces NOT NULL DEFAULT 1.
  validates :newsletter, inclusion: { in: [0, 1] }

  # Password length validation (minimum 12 characters per NIST/OWASP guidance).
  validates :password, length: { minimum: 12 }, if: :password_digest_changed?

  # Password strength validation using zxcvbn (requires score >= 3).
  validate :password_strength, if: :password_digest_changed?

  # Returns all owners who have opted in to the newsletter (newsletter = 1).
  # Used by Admin::NewslettersController#send_newsletter for "send to all".
  scope :newsletter_subscribed, -> { where(newsletter: 1) }

  scope :search, ->(query) do
    return all if query.blank?

    visibility_values = Current.owner.present? ? ["public", "members_only"] : ["public"]
    pattern = "%#{query}%"
    user_name_query = where("LOWER(user_name) LIKE LOWER(?)", pattern)
    real_name_query = where("real_name_visibility IN (?) AND LOWER(real_name) LIKE LOWER(?)", visibility_values, pattern)
    email_query = where("email_visibility IN (?) AND LOWER(email) LIKE LOWER(?)", visibility_values, pattern)

    user_name_query.or(real_name_query).or(email_query)
  end

  # Returns true when this owner is subscribed to the newsletter.
  # Convenience predicate: keeps integer-comparison logic in one place.
  # Example usage: owner.newsletter_subscribed? → true / false
  def newsletter_subscribed?
    newsletter == 1
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

  # Validate password strength using zxcvbn.
  # Score 0-2: weak/very weak — rejected.
  # Score 3-4: strong/very strong — accepted.
  def password_strength
    return if password.blank?

    require "zxcvbn"
    result = Zxcvbn.test(password)

    if result.score < 3
      message = "is too weak"
      message += ": #{result.feedback.warning}" if result.feedback.warning.present?
      message += ". #{result.feedback.suggestions.first}" if result.feedback.suggestions.any?
      errors.add(:password, message)
    end
  end
end
