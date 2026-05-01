# decor/app/mailers/newsletter_mailer.rb
# version 1.0
# Session 56: Newsletter feature — initial implementation.
#
# Sends a single newsletter email to one owner.
# Called once per recipient from Admin::NewslettersController#send_newsletter
# (either for a specific owner or looped over all Owner.newsletter_subscribed).
#
# {{user_name}} substitution:
#   html_body in the Newsletter record contains the literal string "{{user_name}}".
#   This mailer replaces every occurrence with the recipient's actual user_name
#   before passing the body to the view. The plain-text part is generated from
#   the newsletter's markdown_body using the same substitution.
#
# Delivery:
#   deliver_later is used in the controller so that sending to all subscribers
#   does not block the HTTP request. Individual sends also use deliver_later
#   for consistency.

class NewsletterMailer < ApplicationMailer
  # Prepares and sends one newsletter email to a single owner.
  #
  # @param owner       [Owner]      the recipient
  # @param newsletter  [Newsletter] the newsletter record to send
  def send_newsletter(owner, newsletter)
    @owner       = owner
    @subject     = newsletter.subject

    # Replace {{user_name}} placeholder with the recipient's actual user_name.
    # gsub replaces ALL occurrences — a newsletter may address the user by name
    # in the body more than once.
    @html_body   = newsletter.html_body.gsub("{{user_name}}", owner.user_name)

    # Plain-text fallback: substitute in the raw markdown body so that email
    # clients without HTML support see the correct name too.
    @plain_body  = newsletter.markdown_body.gsub("{{user_name}}", owner.user_name)

    mail(
      to:      owner.email,
      subject: newsletter.subject
    )
  end
end
