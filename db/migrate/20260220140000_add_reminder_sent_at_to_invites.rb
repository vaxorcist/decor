# decor/db/migrate/20260220140000_add_reminder_sent_at_to_invites.rb - version 1.0
# Adds reminder_sent_at column to invites table.
# This timestamp is set when the 20-day reminder email is sent, preventing
# duplicate reminders from the daily InviteReminderJob.
# Nullable: nil means no reminder has been sent yet.

class AddReminderSentAtToInvites < ActiveRecord::Migration[8.1]
  def change
    # Nullable datetime — nil = reminder not yet sent, value = reminder was sent at this time
    add_column :invites, :reminder_sent_at, :datetime
  end
end
