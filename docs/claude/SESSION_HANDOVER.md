# decor/docs/claude/SESSION_HANDOVER.md
# version 62.0
# Session 58: Newsletter feature — tests.

**Date:** May 3, 2026
**Branch:** main (Sessions 49–57 committed, pushed, merged, deployed)
**Status:** Session 58 complete — ready to commit, push, merge, deploy.

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
Session 57 ended at ~85% token use.
Session 58 ended at ~70% token use.
Estimates were consistently too optimistic. The floor in COMMON_BEHAVIOR.md
has been raised from 40% to 50% for sessions with 5+ large documents.
Start Session 59 fresh.

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
See RAILS_SPECIFICS.md v3.0 for the full rule.

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

See RAILS_SPECIFICS.md v3.0 for the full rule.

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

See RAILS_SPECIFICS.md v3.0 for the full rule.

---

## !! before_validation vs before_save — Generated fields that are also validated (learned Session 56) !!

If a model generates a field via callback AND validates it for presence, the
callback MUST be `before_validation` — NOT `before_save`. Validations run
before before_save; the presence check fires first and rejects the record.
See RAILS_SPECIFICS.md v3.0 for the full rule.

---

## !! Mailer views directory — Check existing structure first (learned Session 56) !!

This project stores mailer views under `app/views/mailers/<mailer_name>/`,
NOT the Rails default `app/views/<mailer_name>/`.
Always grep for existing mailer views before creating a new directory.
See RAILS_SPECIFICS.md v3.0 for the full rule.

---

## !! deliver_later vs deliver_now — Admin tools use deliver_now (learned Session 56) !!

`deliver_later` hands off to ActiveJob — letter_opener never intercepts it.
For admin-initiated sends, use `deliver_now` for immediate delivery and
letter_opener preview.
See RAILS_SPECIFICS.md v3.0 for the full rule.

---

## !! Email HTML — Gmail strips data: URIs; old clients ignore CSS sizing (learned Session 57) !!

Three rules added to RAILS_SPECIFICS.md v3.0:
1. Gmail strips data: URIs from img src — no image workaround; style the <img>
   for readable alt text using font-size/family/color on the element itself.
2. img display:block misaligns alt text beside inline text — use
   display:inline-block + vertical-align:middle.
3. Old email clients (Firebird, Thunderbird, Outlook) ignore CSS height/width on
   <img> — always add HTML height= and width= attributes alongside CSS.
See RAILS_SPECIFICS.md v3.0 "Email HTML" section for full rules with examples.

---

## !! ActionMailer::TestHelper in integration tests — include explicitly (learned Session 58) !!

ActionDispatch::IntegrationTest does NOT include ActionMailer::TestHelper
automatically. Any integration test file that needs assert_emails /
assert_no_emails / assert_enqueued_emails must include it explicitly:

    class Admin::NewslettersControllerTest < ActionDispatch::IntegrationTest
      include ActionMailer::TestHelper
      ...
    end

ActionMailer::TestCase DOES include it automatically — no explicit include
needed in files that inherit ActionMailer::TestCase.

---

## !! Newsletter fixture html_body — Set explicitly (learned Session 58) !!

Rails fixture loading uses direct SQL INSERT and bypasses all model callbacks,
including Newsletter#generate_html_body (before_validation). Without an explicit
html_body value in the fixture, the column is NULL. The presence validation
does NOT fire during fixture loading, but any test that accesses newsletter.html_body
and expects a non-blank value will fail. Always set html_body explicitly in
newsletters.yml, using plausible Redcarpet output for the markdown_body value.

---

## !! Admin update tests — include admin: "true" when updating self (learned Session 58) !!

In Admin::OwnersController#update, :admin is NOT in owner_params (Brakeman fix).
It is read directly from params[:owner][:admin] and cast with
ActiveModel::Type::Boolean. When a param is absent, cast(nil) → false.
The self-demotion guard fires when:
  @owner == Current.owner && !requested_admin
Consequence: any PATCH to update the currently-logged-in admin's own record
MUST include `admin: "true"` in the params hash — otherwise the guard triggers
and the test gets an unexpected redirect to edit_admin_owner_path.
Exception: tests that intentionally test the self-demotion guard should
omit admin: (or pass admin: "false") to trigger the guard.

---

## Session 58 Summary

**Focus: Newsletter feature — full test suite.**

### Files delivered this session (8 files)

    decor/test/fixtures/newsletters.yml                                    v1.0  NEW
    decor/test/fixtures/owners.yml                                         v2.2
    decor/test/models/owner_test.rb                                        v1.5
    decor/test/models/newsletter_test.rb                                   v1.0  NEW
    decor/test/controllers/admin/newsletters_controller_test.rb            v1.0  NEW
    decor/test/controllers/admin/owners_controller_test.rb                 v1.0  NEW
    decor/test/mailers/newsletter_mailer_test.rb                           v1.0  NEW
    decor/test/controllers/owners_controller_test.rb                       v2.0
    decor/docs/claude/SESSION_HANDOVER.md                                  v62.0

### Test case inventory (~50 tests across 6 files)

**decor/test/fixtures/newsletters.yml (v1.0 NEW)**
- Fixture `one`: subject with placeholder body ({{user_name}} present)
- Fixture `two`: subject with plain body (no placeholder)
- html_body set explicitly for both (bypasses before_validation — see notice above)

**decor/test/fixtures/owners.yml (v2.2)**
- Added newsletter column to all three fixtures
- alice (one): newsletter: 1  charlie (three): newsletter: 1  bob (two): newsletter: 0
- Design intent: alice+charlie subscribed, bob unsubscribed — enables
  assert_includes/refute_includes scope tests without hardcoded counts

**decor/test/models/owner_test.rb (v1.5) — 7 new tests**
1. newsletter defaults to 1 (reflects DB column DEFAULT)
2. newsletter_subscribed? returns true when newsletter == 1
3. newsletter_subscribed? returns false when newsletter == 0
4. newsletter validates inclusion — rejects value 2
5. newsletter validates inclusion — rejects nil
6. newsletter_subscribed scope includes subscribed owners (alice, charlie)
7. newsletter_subscribed scope excludes unsubscribed owner (bob)

**decor/test/models/newsletter_test.rb (v1.0 NEW) — 17 tests**
- Validity: valid newsletter saves; invalid records rejected
- subject: presence, max 200 chars, accepts 200 chars, accepts typical subject
- markdown_body: presence (nil and blank string)
- before_validation callback: html_body generated before validation fires;
  rendered HTML contains expected Redcarpet output; early return when blank;
  html_body presence validated independently
- {{user_name}} placeholder preserved in html_body and markdown_body
- html_body regenerated on update
- Fixture smoke tests (x4): present, non-blank, placeholder present/absent

**decor/test/controllers/admin/newsletters_controller_test.rb (v1.0 NEW) — 16 tests**
- Auth guard: unauthenticated redirect
- index: 200, lists subjects
- new: 200
- create: valid upload saves + redirects to show; missing file → 422;
  blank subject → 422
- show: 200, displays subject
- destroy: removes record, redirects, notice includes subject
- send_newsletter GET: 200
- send_newsletter POST recipient=all: delivers one email per subscribed owner;
  to addresses correct (alice+charlie in, bob out)
- send_newsletter POST recipient=specific: delivers 1 email, correct address;
  blank owner_id → 422
- send_newsletter POST no recipient: → 422

**decor/test/controllers/admin/owners_controller_test.rb (v1.0 NEW) — 12 tests**
- Auth guard: unauthenticated redirect
- index: 200, lists all owner usernames
- edit: 200
- update newsletter: sets to 0 (alice own record, admin:"true" supplied);
  sets to 1 (bob, no self-demotion concern); notice includes username
- update user_name: changes username; rejects blank username
- Self-demotion guard: redirect + alert + admin unchanged
- destroy: removes non-self owner; blocks self-delete
- send_password_reset: delivers 1 email, generates token

**decor/test/mailers/newsletter_mailer_test.rb (v1.0 NEW) — 7 tests**
- Correct to: address
- Correct subject:
- {{user_name}} replaced with recipient's user_name (alice)
- Raw {{user_name}} not present in rendered body (alice)
- Substitution works for a different recipient (charlie)
- Newsletter without placeholder renders without error
- deliver_now stores mail in ActionMailer deliveries

**decor/test/controllers/owners_controller_test.rb (v2.0) — 2 new tests**
- PATCH update saves newsletter: 0 (alice opts out)
- PATCH update saves newsletter: 1 (bob opts in)

### Deployment checklist for Session 58:
No migrations. No schema changes. Test files only. Deploy as normal.

---

## Session 57 Summary

**Focus: Newsletter email chrome — four rendering fixes.**

### Files delivered this session (2 files)

    decor/app/views/shared/_newsletter_email_chrome.html.erb    v2.3
    decor/docs/claude/RAILS_SPECIFICS.md                        v3.0
    decor/docs/claude/SESSION_HANDOVER.md                       v61.0

### Changes

**Fix 1: Table borders, header colour, column padding (v2.0)**
**Fix 2: Logo embedded as hardcoded base64 constant (v2.1)**
**Fix 3: Firebird renders logo at full 680×282px (v2.2)**
**Fix 4: Gmail shows alt text "DECOR" at wrong size and alignment (v2.2 → v2.3)**

---

## Priority 1 — Future Sessions

1. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
2. **System tests** — decor/test/system/ still empty.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.
6. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
   `production.rb` to the app's public hostname, and use `asset_url('logo.png')`
   in the partial instead of the data: URI. Gmail will then load the real image.
   The data: URI fallback can remain for letter_opener (development).

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
