# decor/app/jobs/invite_reminder_job.rb - version 1.0
# Finds all pending invites that have passed the 20-day reminder threshold
# and sends a reminder email to each, then records the time the reminder was sent.
#
# Designed to run daily via Solid Queue (config/recurring.yml).
# Uses find_each for memory efficiency (batched loading, not all at once).
# Sets reminder_sent_at via update_column to skip callbacks and validations —
# this is intentional: we only want to stamp the timestamp, not trigger callbacks.
#
# Idempotent: the :needs_reminder scope filters on reminder_sent_at: nil,
# so running the job multiple times on the same day is safe — each invite
# only ever receives one reminder.

class InviteReminderJob < ApplicationJob
  queue_as :default

  def perform
    Invite.needs_reminder.find_each do |invite|
      InviteMailer.reminder_email(invite).deliver_now
      # Use update_column to bypass validations/callbacks — we only want
      # to record the timestamp without triggering model logic
      invite.update_column(:reminder_sent_at, Time.current)
    end
  end
end
