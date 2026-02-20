# decor/test/jobs/invite_reminder_job_test.rb - version 1.0
# Tests for InviteReminderJob and the needs_reminder scope on Invite.
#
# Scenarios covered:
# - Invite past 20 days, not accepted, no reminder sent → reminder is sent
# - Invite past 20 days, not accepted, reminder already sent → no second reminder
# - Invite past 20 days, already accepted → no reminder sent
# - Invite past 30 days (expired) → no reminder sent
# - Invite under 20 days old → no reminder sent
# - Job sets reminder_sent_at on the invite after sending

require "test_helper"

class InviteReminderJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  # Helper: creates an invite with sent_at set to `days_ago` days in the past.
  # Uses create! so all before_validation callbacks run (token generation, set_sent_at),
  # then immediately overrides sent_at (and optionally other timestamps) via update_columns,
  # which writes directly to the DB without triggering callbacks or validations.
  def create_invite(email:, days_ago:, accepted_at: nil, reminder_sent_at: nil)
    invite = Invite.create!(email: email)
    invite.update_columns(
      sent_at: days_ago.days.ago,
      accepted_at: accepted_at,
      reminder_sent_at: reminder_sent_at
    )
    invite
  end

  # --- needs_reminder scope tests ---

  test "needs_reminder includes invite past 20 days with no reminder sent" do
    invite = create_invite(email: "pending@example.com", days_ago: 21)
    assert_includes Invite.needs_reminder, invite
  end

  test "needs_reminder excludes invite where reminder already sent" do
    invite = create_invite(email: "reminded@example.com", days_ago: 21,
                           reminder_sent_at: 1.day.ago)
    assert_not_includes Invite.needs_reminder, invite
  end

  test "needs_reminder excludes accepted invite" do
    invite = create_invite(email: "accepted@example.com", days_ago: 21,
                           accepted_at: 1.day.ago)
    assert_not_includes Invite.needs_reminder, invite
  end

  test "needs_reminder excludes expired invite (past 30 days)" do
    invite = create_invite(email: "expired@example.com", days_ago: 31)
    assert_not_includes Invite.needs_reminder, invite
  end

  test "needs_reminder excludes invite under 20 days old" do
    invite = create_invite(email: "fresh@example.com", days_ago: 10)
    assert_not_includes Invite.needs_reminder, invite
  end

  test "needs_reminder includes invite at exactly 20 days" do
    # Boundary: 20 days ago should be included (sent_at < REMINDER_AT.ago)
    invite = create_invite(email: "boundary@example.com", days_ago: 20)
    assert_includes Invite.needs_reminder, invite
  end

  # --- InviteReminderJob tests ---

  test "job sends reminder email to eligible invite" do
    create_invite(email: "toremind@example.com", days_ago: 21)

    assert_emails 1 do
      InviteReminderJob.perform_now
    end
  end

  test "job does not send email when no eligible invites" do
    create_invite(email: "fresh@example.com", days_ago: 5)

    assert_emails 0 do
      InviteReminderJob.perform_now
    end
  end

  test "job sets reminder_sent_at after sending" do
    invite = create_invite(email: "toremind2@example.com", days_ago: 21)
    assert_nil invite.reminder_sent_at

    InviteReminderJob.perform_now

    invite.reload
    assert_not_nil invite.reminder_sent_at
  end

  test "job does not send second reminder if already sent" do
    create_invite(email: "alreadyreminded@example.com", days_ago: 21,
                  reminder_sent_at: 1.day.ago)

    assert_emails 0 do
      InviteReminderJob.perform_now
    end
  end

  test "reminder email is sent to correct address" do
    create_invite(email: "correct@example.com", days_ago: 21)

    InviteReminderJob.perform_now

    email = ActionMailer::Base.deliveries.last
    assert_equal [ "correct@example.com" ], email.to
  end

  test "reminder email has correct subject" do
    create_invite(email: "subjectcheck@example.com", days_ago: 21)

    InviteReminderJob.perform_now

    email = ActionMailer::Base.deliveries.last
    assert_equal "Your DEC Owner's Registry invitation expires soon", email.subject
  end
end
