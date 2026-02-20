# decor/app/mailers/invite_mailer.rb - version 1.1
# Changes from v1.0:
# - Added reminder_email action for the 20-day reminder

class InviteMailer < ApplicationMailer
  # Initial invitation email sent when an invite is created.
  def invite_email(invite)
    @invite = invite
    @accept_url = new_owner_url(token: invite.token)

    mail(
      to: invite.email,
      subject: "You've been invited to DEC Owner's Registry"
    )
  end

  # Reminder email sent after 20 days if the invite has not been accepted.
  # Called by InviteReminderJob — only sent once (tracked via reminder_sent_at).
  def reminder_email(invite)
    @invite = invite
    @accept_url = new_owner_url(token: invite.token)

    mail(
      to: invite.email,
      subject: "Your DEC Owner's Registry invitation expires soon"
    )
  end
end
