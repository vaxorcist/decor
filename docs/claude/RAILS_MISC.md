# decor/docs/claude/RAILS_MISC.md
# version 1.0 NEW
# Session 84 (Reorg Session 3 of 4): Extracted from RAILS_SPECIFICS.md v3.15
# as part of the agreed 4-session documentation reorg (see
# SESSION_HANDOVER.md "Documentation Reorganization — Status"). Contains
# the email/mailer rules that were previously mixed into the single
# monolithic RAILS_SPECIFICS.md file. Each rule's lengthy "why this rule
# exists" incident narrative has been trimmed to one line, per the reorg
# plan — the rule statement and code examples (the load-bearing content
# for Pre-Implementation Verification) are unchanged. Full original
# narrative for every rule below remains recoverable via git history of
# RAILS_SPECIFICS.md prior to this split.
# Load this file only for mailer/email work — it is NOT part of the
# mandatory session-start `cat` list (see RAILS_SPECIFICS.md's topic index).

**Rails-Specific Patterns — Email & Mailers**

**Last Updated:** July 30, 2026 (Session 84 — split out of RAILS_SPECIFICS.md)

---

## Email HTML — Gmail, Old Clients, and img Elements (MANDATORY)

### Rule 1 — Gmail strips data: URIs from img src

**Gmail unconditionally strips `data:` URIs from `<img src="...">`.** There is
no workaround that makes the actual image appear in Gmail. Permanent fix: set
`config.action_mailer.asset_host` in `production.rb`, use `asset_url('logo.png')`
(returns an absolute HTTPS URL in production, which Gmail loads). In
development, fall back to a `data:` URI for letter_opener preview.

**Interim workaround — style the alt text for readability:** Gmail applies
the `<img>`'s own `style=` attribute to its alt text when `src` is stripped,
so font properties on the `<img>` element are the only way to size/style the
fallback text:

```erb
<img src="<%= LOGO_SRC %>"
     alt="DECOR"
     height="40" width="96"
     style="display: inline-block; vertical-align: middle; border: 0;
            height: 40px; width: 96px;
            font-size: 24px; font-family: Arial, Helvetica, sans-serif;
            color: #1c1917; font-weight: normal;">
```

**Why:** the newsletter logo was embedded as a `data:` URI; Gmail stripped it
and the fallback `alt="DECOR"` rendered at browser-default (~12px) size
against 24px adjacent text (Session 57).

---

### Rule 2 — img display:block misaligns alt text beside inline text

**Never use `display: block` on an `<img>` that sits beside inline text** in
an email header. `display: block` removes the element from inline flow, so
when `src` is stripped the alt text renders as a block element and no longer
aligns with adjacent text.

```html
<!-- Wrong — alt text floats above/below adjacent text -->
<img ... style="display: block; ...">

<!-- Correct — aligns with adjacent text -->
<img ... style="display: inline-block; vertical-align: middle; ...">
```

**Why:** after Rule 1's font styling, "DECOR" sat visibly higher than the
adjacent tagline text until `display: block` was changed to
`inline-block; vertical-align: middle` (Session 57).

---

### Rule 3 — Old email clients ignore CSS height/width on img

**Old clients (Firebird, Thunderbird, Outlook/Word renderer) read the HTML
`height=`/`width=` attributes, and may ignore CSS `style="height:...px"`
entirely.** Always provide both:

```html
<img src="..."
     height="40" width="96"
     style="height: 40px; width: 96px;">
```

Calculate proportional width from source dimensions:
`width = round(target_height × (image_width / image_height))`. The DECOR
logo is 680×282px; at height=40, width = round(40 × 680/282) = 96px.

**Why:** Firebird rendered the logo at its native 680×282px, dominating the
email header, until explicit HTML `height=`/`width=` attributes were added
alongside the CSS (Session 57).

---

## before_validation vs before_save — Generated Fields That Are Also Validated (MANDATORY)

**RULE: If a model generates a field via a callback AND validates that field
for presence, use `before_validation` — NOT `before_save`.**

Callback order: `before_validation` → `validate` → `before_save` → save. A
`before_save` callback runs too late to satisfy a presence validation on the
field it generates.

```ruby
# Wrong — presence check fires before generate_html_body runs
validates :html_body, presence: true
before_save :generate_html_body

# Correct
validates :html_body, presence: true
before_validation :generate_html_body
```

**When to use each:** `before_validation` for any callback that fills a
field which is then validated; `before_save` for callbacks that don't touch
validated fields (normalizing a non-validated field, computed cache values).

**Why:** `Newsletter#generate_html_body` was `before_save`; on create, the
`html_body` presence validation ran first and rejected the record even
though the Redcarpet conversion would have succeeded moments later
(Session 56).

---

## Mailer Views Directory — Check Existing Structure Before Creating (MANDATORY)

**RULE: Before creating a new mailer view directory, check where existing
mailer views actually live in this project — do NOT assume
`app/views/<mailer_name>/`.**

**DECOR's actual convention:**
```
decor/app/views/mailers/<mailer_name>/<action>.html.erb
```
NOT `decor/app/views/<mailer_name>/<action>.html.erb`.

**Check command (run once per project):**
```bash
find decor/app/views -name "*.html.erb" | grep -i mail
```

**Why:** `send_newsletter.html.erb` was first placed at
`app/views/newsletter_mailer/`, producing `ActionView::MissingTemplate`; the
project's actual convention (`app/views/mailers/newsletter_mailer/`) was
already visible in `PasswordResetMailer`'s existing view (Session 56).

---

## deliver_later vs deliver_now — Admin Tools and letter_opener (MANDATORY)

**RULE: For admin-initiated email actions, use `deliver_now` — not
`deliver_later`.** `deliver_later` hands off to ActiveJob's background
queue; letter_opener (the dev email interceptor) never sees it, so no
browser tab opens.

```ruby
# Wrong — letter_opener never fires, no tab opens
NewsletterMailer.send_newsletter(owner, newsletter).deliver_later

# Correct
NewsletterMailer.send_newsletter(owner, newsletter).deliver_now
```

**When `deliver_later` IS appropriate:** high-volume sends triggered by user
actions where blocking the request would risk a timeout; background jobs
explicitly tested with `assert_enqueued_emails`.

**When `deliver_now` is appropriate:** admin-triggered sends of any size
where the admin can wait a moment; anywhere letter_opener preview during
development is desired; small transactional emails.

**Addendum — testing `deliver_later` requires `perform_enqueued_jobs`:**
`ActionMailer::Base.deliveries` is only populated once the job actually
runs. Wrap the controller call:

```ruby
# Wrong — deliveries is still empty
post send_password_reset_admin_owner_url(owner)
assert ActionMailer::Base.deliveries.size > 0   # fails: 0

# Correct
perform_enqueued_jobs do
  post send_password_reset_admin_owner_url(owner)
end
assert ActionMailer::Base.deliveries.size > 0   # passes
```
`deliver_now` does NOT need `perform_enqueued_jobs` — only `deliver_later` does.

**Why:** the newsletter send action used `deliver_later`; no letter_opener
tab appeared even though the flash confirmed the send. Switching to
`deliver_now` fixed it immediately. The `perform_enqueued_jobs` addendum
came from `send_password_reset`'s test (correctly using `deliver_later`)
failing with `deliveries.size == 0` until wrapped (Sessions 56, 58).

---

**End of RAILS_MISC.md**
