# decor/docs/claude/SESSION_HANDOVER.md
# version 60.0
# Session 56: Newsletter feature — complete implementation.

**Date:** May 1, 2026
**Branch:** main (Sessions 49–55 committed, pushed, merged, deployed)
**Status:** Session 56 complete — ready to commit, push, merge, deploy.

---

## !! RELIABILITY NOTICE — READ FIRST !!

The `decor-session-rules` skill (v1.3) is installed. Read it before anything else.

**MANDATORY at every session start:**

STEP 0 — Tool sanity check:
```bash
echo "bash_tool OK"
```

STEP 1 — Read ALL five rule documents via bash cat:
```bash
cat /mnt/user-data/uploads/COMMON_BEHAVIOR.md
cat /mnt/user-data/uploads/RAILS_SPECIFICS.md
cat /mnt/user-data/uploads/PROGRAMMING_GENERAL.md
cat /mnt/user-data/uploads/DECOR_PROJECT.md
cat /mnt/user-data/uploads/SESSION_HANDOVER.md
```
After each: log "Read FILENAME — N lines, complete."

---

## !! TOKEN BUDGET WARNING !!

Session 55 ended with the user calling for a wrap-up mid-session due to token
pressure. Session 56 also ended with the user calling for a wrap-up.
Estimates were consistently too optimistic. The floor in COMMON_BEHAVIOR.md
has been raised from 40% to 50% for sessions with 5+ large documents.
Start Session 57 fresh.

---

## !! OUTPUT PATH COLLISION — NEVER write two files to the same output path !!

See COMMON_BEHAVIOR.md v2.7 for the full rule.

---

## !! OUTPUT FILE NAMING — NEVER substitute underscores for dots !!

See COMMON_BEHAVIOR.md v2.7 for the full rule.

---

## !! FIXTURE DELIVERY RULE !!

Whenever a fixture file is modified, upload it to verify before closing the session.

---

## !! NEVER GUESS RULE (added Session 39) !!

Before writing any code or test that depends on a value, path, method name,
or behaviour in the codebase: READ THE FILE.

---

## !! REMOVE ROUTES AFTER VIEWS (learned Session 41) !!

When removing a route, always update the views that call that path helper FIRST.

---

## !! MANUAL DATA MIGRATIONS — CHECK ALL TABLES (learned Session 42) !!

When running a manual data migration that changes an enum value, grep for ALL
tables that share that enum/column before assuming the migration is complete.

---

## !! before_action :set_resource — ALWAYS scope with only: (learned Session 46) !!

When a controller has new/create actions alongside show/edit/update/destroy,
the set_resource before_action MUST be scoped with only: %i[show edit update destroy].

---

## !! paginate — NEVER assign the return value (learned Session 48) !!

`paginate scope` — no assignment. `@page = paginate(scope)` overwrites @page with nil.

---

## !! EXPORT/IMPORT — ALWAYS include a stable unique key (learned Session 49) !!

Every exported record type must carry a stable unique field for duplicate detection.
See PROGRAMMING_GENERAL.md v2.0 for the full rule.

---

## !! RESPONSE BODY ASSERTIONS — Use assert_body_includes (learned Session 50) !!

In integration tests, NEVER use `assert_match(text, response.body)` or
`refute_match(text, response.body)`. Use `assert_body_includes` /
`refute_body_includes` from ResponseHelpers instead.
See RAILS_SPECIFICS.md v2.9 for the full rule.

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

See RAILS_SPECIFICS.md v2.9 for the full rule.

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

See RAILS_SPECIFICS.md v2.9 for the full rule.

---

## !! before_validation vs before_save — Generated fields that are also validated (learned Session 56) !!

If a model generates a field via callback AND validates it for presence, the
callback MUST be `before_validation` — NOT `before_save`. Validations run
before before_save; the presence check fires first and rejects the record.
See RAILS_SPECIFICS.md v2.9 for the full rule.

---

## !! Mailer views directory — Check existing structure first (learned Session 56) !!

This project stores mailer views under `app/views/mailers/<mailer_name>/`,
NOT the Rails default `app/views/<mailer_name>/`.
Always grep for existing mailer views before creating a new directory.
See RAILS_SPECIFICS.md v2.9 for the full rule.

---

## !! deliver_later vs deliver_now — Admin tools use deliver_now (learned Session 56) !!

`deliver_later` hands off to ActiveJob — letter_opener never intercepts it.
For admin-initiated sends, use `deliver_now` for immediate delivery and
letter_opener preview.
See RAILS_SPECIFICS.md v2.9 for the full rule.

---

## Session 56 Summary

**Focus: Newsletter feature — full implementation.**

### Files delivered this session (21 files)

    decor/db/migrate/20260430000000_add_newsletter_to_owners.rb    v1.0  NEW
    decor/db/migrate/20260430000100_create_newsletters.rb          v1.0  NEW
    decor/app/models/owner.rb                                      v1.6
    decor/app/models/newsletter.rb                                 v1.0  NEW
    decor/app/mailers/newsletter_mailer.rb                         v1.0  NEW
    decor/app/views/mailers/newsletter_mailer/send_newsletter.html.erb  v2.0
    decor/app/views/shared/_newsletter_email_chrome.html.erb       v1.0  NEW
    decor/app/controllers/admin/newsletters_controller.rb          v1.0  NEW
    decor/app/views/admin/newsletters/index.html.erb               v1.0  NEW
    decor/app/views/admin/newsletters/new.html.erb                 v1.0  NEW
    decor/app/views/admin/newsletters/show.html.erb                v2.0
    decor/app/views/admin/newsletters/send_newsletter.html.erb     v1.0  NEW
    decor/app/views/layouts/admin.html.erb                         v2.3
    decor/config/routes.rb                                         v3.1
    decor/app/controllers/owners_controller.rb                     v2.1
    decor/app/controllers/admin/owners_controller.rb               v1.1
    decor/app/views/owners/show.html.erb                           v2.5
    decor/app/views/admin/owners/index.html.erb                    v1.4
    decor/app/views/admin/owners/edit.html.erb                     v1.1
    decor/app/views/owners/new.html.erb                            v1.3
    decor/app/views/owners/_form.html.erb                          v1.9
    decor/docs/claude/RAILS_SPECIFICS.md                           v2.9
    decor/docs/claude/SESSION_HANDOVER.md                          v60.0

### Changes

**Feature: Newsletter column on owners table**
- Migration adds `newsletter INTEGER NOT NULL DEFAULT 1`.
- SQLite back-fills all existing rows with 1 (subscribed) automatically.
- No data migration needed.

**Feature: Newsletter model**
- `newsletters` table: subject VARCHAR(200), markdown_body TEXT, html_body TEXT.
- TEXT approved by user (Session 56).
- `before_validation :generate_html_body` — converts markdown_body to HTML using
  identical Redcarpet config as ApplicationHelper#render_markdown.
- Lesson: `before_save` was used initially — produced "Html body can't be blank"
  because validations run before before_save. Fixed to `before_validation`.

**Feature: Newsletter mailer**
- `NewsletterMailer#send_newsletter(owner, newsletter)` — substitutes
  `{{user_name}}` in html_body and markdown_body, sends via deliver_now.
- Lesson: `deliver_later` was used initially — letter_opener never intercepted it.
  Fixed to `deliver_now` so the browser tab opens immediately.

**Feature: Shared email chrome partial**
- `app/views/shared/_newsletter_email_chrome.html.erb` — single source of truth
  for email layout (styles, header with base64-embedded logo, body, footer).
- Rendered by both the mailer template and the admin preview show view.
- Logo embedded as base64 data URI — works in letter_opener (file:// pages)
  and all email clients without any URL resolution.
- Email width: 900px (widened 50% from initial 600px at user request).
- Font: Arial, Helvetica, sans-serif (matches admin preview body font).

**Feature: Admin Newsletters dropdown**
- admin.html.erb v2.3: "Newsletters" dropdown added between Software and
  Imports/Exports. Two items: "Upload Newsletter" and "Send Newsletter".

**Feature: Admin newsletters controller and views**
- `Admin::NewslettersController`: index, new, create, show, destroy,
  send_newsletter (GET + POST).
- Upload: admin provides subject + .md file; controller reads file, model
  generates html_body via Redcarpet before_validation.
- Send: two options — "All subscribed owners" (Owner.newsletter_subscribed scope)
  or "Specific owner" (searchable select, Tom Select removed — caused stray box).
- Preview: show.html.erb renders shared chrome partial; {{user_name}} shown as-is.

**Feature: Newsletter preference on owner-facing pages**
- owners/show.html.erb v2.5: inline PATCH toggle widget (Subscribed ✓ / Not subscribed),
  visible only to the owner themselves.
- owners/_form.html.erb v1.9: newsletter checkbox in edit profile form.
- owners/new.html.erb v1.3: newsletter checkbox in registration form (checked by default).
- admin/owners/index.html.erb v1.4: Newsletter column (Yes / No badge).
- admin/owners/edit.html.erb v1.1: newsletter checkbox.
- Both controllers permit :newsletter param.

**Rule: before_validation vs before_save (new — RAILS_SPECIFICS.md v2.9)**
- Real example: Newsletter#generate_html_body as before_save produced
  "Html body can't be blank" because presence validation fires first.
  Fixed to before_validation.

**Rule: Mailer views directory (new — RAILS_SPECIFICS.md v2.9)**
- Real example: send_newsletter.html.erb placed at app/views/newsletter_mailer/
  produced ActionView::MissingTemplate. This project uses
  app/views/mailers/newsletter_mailer/ — verified by checking existing
  PasswordResetMailer view location.

**Rule: deliver_later vs deliver_now for admin tools (new — RAILS_SPECIFICS.md v2.9)**
- Real example: deliver_later produced no letter_opener tab. Fixed to deliver_now.

**Deployment checklist for Session 56:**
```bash
bin/rails db:migrate
```
Runs both migrations: adds newsletter to owners, creates newsletters table.

---

## Session 55 Summary

**Focus: Image captions on home page, barter offers stat, admin owners peripherals column.**

### Files delivered this session (5 files)

    decor/app/views/home/index.html.erb                         v4.7
    decor/app/controllers/home_controller.rb                    v1.3
    decor/app/views/admin/owners/index.html.erb                 v1.3
    decor/docs/claude/COMMON_BEHAVIOR.md                        v2.7
    decor/docs/claude/SESSION_HANDOVER.md                       v59.0

---

## Priority 1 — Future Sessions

1. **Tests for Newsletter feature** — see Session 56 wrap-up for the full
   list of ~35 test cases across 5 files. Fixtures and existing test files
   needed at session start:
     test/fixtures/owners.yml
     test/fixtures/newsletters.yml  (new — will need creating)
     test/models/owner_test.rb      (update)
     test/integration/admin_owners_test.rb  (update, if it exists)
     test/integration/owners_test.rb        (update, if it exists)
2. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
3. **System tests** — decor/test/system/ still empty.
4. **Account deletion + data export** (GDPR).
5. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
6. **BulkUploadService stale model references** — low priority.

---

## Connections Feature — Design Reference (updated Session 38)

### Tables

```
connection_groups
  id                  integer  PK
  owner_id            integer  FK → owners.id, NOT NULL
  connection_type_id  integer  FK → connection_types.id, nullable
  label               VARCHAR(100) nullable
  owner_group_id      integer  NOT NULL (≥1, unique per owner)
  created_at / updated_at
  UNIQUE INDEX (owner_id, owner_group_id)

connection_members
  id                   integer  PK
  connection_group_id  integer  FK → connection_groups.id, NOT NULL, ON DELETE CASCADE
  computer_id          integer  FK → computers.id, NOT NULL
  owner_member_id      integer  NOT NULL (≥1, unique per group)
  label                VARCHAR(100) nullable
  created_at / updated_at
  UNIQUE INDEX (connection_group_id, computer_id)
  UNIQUE INDEX (connection_group_id, owner_member_id)
```

### Connections sub-page URL
`/owners/:id/connections` → `connections_owner_path(@owner)`

### Auto-assign rules
- `owner_group_id`: assigned on create as `max(owner.connection_groups.owner_group_id) + 1`
- `owner_member_id`: assigned on create as `max(in-memory siblings, db rows) + 1`
- Guard: `return if field.to_i > 0` — NOT `field.present?` (0.present? is true)

---

**End of SESSION_HANDOVER.md**
