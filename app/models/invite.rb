# decor/app/models/invite.rb - version 1.1
# Changes from v1.0:
# - Added REMINDER_AT constant (20 days)
# - Added :needs_reminder scope — finds pending invites past 20 days with no reminder sent
# - Added reminder_sent? helper method

class Invite < ApplicationRecord
  EXPIRY     = 30.days
  REMINDER_AT = 20.days  # Send reminder after this many days of inactivity

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { conditions: -> { where(accepted_at: nil) } }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_sent_at, on: :create

  scope :pending,      -> { where(accepted_at: nil) }
  scope :accepted,     -> { where.not(accepted_at: nil) }
  scope :expired,      -> { pending.where("sent_at < ?", EXPIRY.ago) }
  scope :valid_invites, -> { pending.where("sent_at >= ?", EXPIRY.ago) }

  # Invites that need a reminder email:
  # - Not yet accepted
  # - Not yet expired (sent_at within the 30-day window)
  # - More than 20 days have passed since the invite was sent
  # - No reminder has been sent yet (reminder_sent_at is nil)
  scope :needs_reminder, -> {
    pending
      .where("sent_at < ?", REMINDER_AT.ago)
      .where("sent_at >= ?", EXPIRY.ago)
      .where(reminder_sent_at: nil)
  }

  def expired?
    accepted_at.nil? && sent_at < EXPIRY.ago
  end

  def accepted?
    accepted_at.present?
  end

  def reminder_sent?
    reminder_sent_at.present?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_sent_at
    self.sent_at ||= Time.current
  end
end
