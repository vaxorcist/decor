# decor/docs/claude/SESSION_HANDOVER.md
# version 71.1
# Session 71: Owner Part Number display fix (9 files — the 8 URLs missing the
#   column/field, per Session 70's own gap flag) delivered. Separately: agreed
#   and implemented a new File Transfer Protocol with the user — COMMON_BEHAVIOR.md
#   bumped to v3.0, replacing the old Download File Naming / Output Path Collision /
#   Upload File Naming rules with export/import shell scripts using @-encoded flat
#   filenames (decor/export/ and decor/import/, both gitignored). Updated the three
#   stale references to the old rules found in this file and in DECOR_PROJECT.md
#   (the "!! OUTPUT PATH COLLISION !!" banner below, the "Upload-collision hit
#   again this session" note, and the Session 63 file-list upload instruction).
# Session 70: Owner Part Number feature — IMPLEMENTED (11 of 12 files;
#   schema.rb regeneration pending an actual db:migrate run). All three open
#   design questions from Session 69 answered and implemented: uniqueness
#   scope keeps model/type dimension; both serial_number and the new
#   owner_part_number default to "-" via before_validation on both models;
#   spares collisions resolved via a one-time "SPARE-#{id}" backfill
#   migration with NO auto-assign going forward (Option B). CSV export/
#   import updated (owner_export_service.rb / owner_import_service.rb only —
#   computer_model_export_service.rb confirmed out of scope). See "Session 70
#   Summary" below for full detail, the resulting CSV re-import behaviour
#   change, and the complete NOT YET DONE checklist.
# Session 69: UI Terminology Rename — IMPLEMENTED (15 files). Owner Part
#   Number feature — design consultation only, NOT implemented, three open
#   questions. Also: this session found no "Session 68 Summary" exists in
#   this file despite Session 68 code changes clearly present in the actual
#   source (component_suggestions views carry "Session 68 (cont'd)" comments).
#   See "!! GAP NOTICE !!" and "Session 69 Summary" below.
# Session 67: Component Suggestions Phase 4 — IMPLEMENTED (migration, manual
#   flag, Download Manual Changes, import rewrite, paginated/filterable admin
#   index). bin/rails test passing locally (900 tests, 0 failures/errors).
#   NOT YET committed/pushed/deployed. See "Session 67 Summary" below.
# Session 66: Order number / variant — design pivot, no implementation. Full
#   multi-column variant-split design worked out in detail, then set aside
#   before implementation began (risk of "self-indulgent featuritis"). Saved
#   for reference at decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md. Adopted
#   a simpler concatenated-field approach instead. See "Session 66 Summary"
#   below for confirmed requirements going into next session.
# Session 65: Component order_number bulk maintenance (admin Components dropdown).

**Date:** July 17, 2026
**Branch:** main (Sessions 49–65 committed, pushed, merged, deployed). Session 67's
  Phase 4 work, Session 68's Component Suggestions UI refinements (status/paper
  trail unclear — see GAP NOTICE below), Session 69's UI Terminology Rename, AND
  Session 70's Owner Part Number feature are ALL sitting locally, uncommitted,
  on top of each other.
**Status:** Session 70 implemented the Owner Part Number feature end to end —
  11 of 12 planned files delivered, code-complete, but NOT migrated against a
  real database, NOT tested (bin/rails test not run, no unit tests written yet —
  6 existing test files are needed first per Never-Guess/Pre-Implementation
  Verification), and NOT lint/security-scanned. See "Session 70 Summary" below
  for full detail, the resulting CSV re-import behaviour change worth knowing
  about, and the complete NOT YET DONE checklist — this is the very first thing
  to pick up next session, starting with an actual `bin/rails db:migrate` run.
  Session 69's UI Terminology Rename (15 files) and Session 67's Phase 4 work
  are both still separately outstanding on their own checklists further down.
  Read the GAP NOTICE below before doing anything else.

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

## !! GAP NOTICE — Session 68 has no formal summary in this document (found Session 69) !!

While reading files for the Session 69 UI rename task, several source files
delivered as part of the project (e.g.
`decor/app/views/admin/component_suggestions/index.html.erb`, which carried
a "Session 68 (cont'd)" changelog comment about dropdown-width/full-bleed
layout fixes) showed clear evidence of Session 68 work having happened and
been delivered. **But this SESSION_HANDOVER.md (as uploaded to the project)
has no "Session 68 Summary" section, and DECOR_PROJECT.md's own header
changelog jumps straight from Session 67 to Session 69 with no Session 68
entry either.**

This was not reconstructed or guessed at — per the Never-Guess rule, no
"Session 68 Summary" has been fabricated from the partial evidence in the
source files. **This is flagged for Ulli to reconcile:** either a newer
version of these two documents (containing the real Session 68 Summary)
exists outside this project and simply wasn't the version uploaded here, or
Session 68's rule-doc updates were never actually produced/delivered despite
the code changes shipping. Worth checking before treating this document as
a complete history.

---

## !! GEARED PAGINATION — paginate() SETS @page AND RENDERS ITSELF (learned Session 67) !!

`paginate(scope)` is not a data-fetch step — it assigns `@page` (never a
model-named ivar) and internally calls `respond_to { format.turbo_stream;
format.html }`, i.e. it renders the response. Every ivar the view needs
(`@page_title`, `@turbo_tbody_id`, `@load_more_id`, `@index_path`) MUST be
set BEFORE calling it — it must be the last line of the action.
See RAILS_SPECIFICS.md v3.6 for the full rule and the actual concern source.

---

## !! RAILS ENUM — read_attribute DOES NOT BYPASS TYPE-CASTING (learned Session 67) !!

To get the raw stored value of an enum column ("a"/"m"), use
`<attribute>_before_type_cast` — NOT `read_attribute(:<attribute>)`, which
still returns the mapped label ("added"/"modified"). See RAILS_SPECIFICS.md
v3.6 for the full rule.

---

## !! COLLECTION ROUTES IN A NAMESPACED resources BLOCK — A SECOND PREFIX SHAPE (learned Session 67) !!

A `collection do get :foo end` route nested inside `resources` already
inside `namespace :admin` prepends the action name to the already-prefixed
resource name (`download_manual_admin_component_suggestions_path`) —
DIFFERENT from a custom `as:` route declared directly in the namespace
(Session 65's `admin_foo_path` shape). Always verify with
`bin/rails routes | grep <name>` — never assume either shape.
See RAILS_SPECIFICS.md v3.6 for the full rule.

---

## !! FLAGGING A GUESS DOES NOT SATISFY NEVER-GUESS (learned Session 67) !!

Writing a file from general convention and labeling it "inferred, please
verify" is still a Never-Guess violation — it shifts verification burden
onto the user instead of Claude asking for the real file. See
COMMON_BEHAVIOR.md v2.8 for the full rule and the real example.

---

## !! SYSTEM TESTS — BROWSER-LAYER LOGIN (learned Session 59) !!

`login_as` (AuthenticationHelper) posts to the Rails Rack adapter. It sets a
session cookie on the Rack test adapter — NOT on the Selenium browser process.
System tests run a real Chrome instance; its cookie jar is completely separate.

**Rule:** Never call `login_as` from a system test file.
Use `sign_in` (defined in ApplicationSystemTestCase v1.3) instead.
`sign_in` drives the real login form through the browser.

See `decor/test/application_system_test_case.rb` v1.3 for implementation.

---

## !! SYSTEM TESTS — CAPYBARA ASSERTION PATTERNS (learned Session 60) !!

### assert_selector with a message string raises ArgumentError

Capybara's `assert_selector` does NOT accept a plain string as its second
positional argument. It raises:
```
ArgumentError: Unused parameters passed to Capybara::Queries::SelectorQuery
```

**Wrong:**
```ruby
assert_selector "input[name='user_name']", "Login form must have this field"
refute_selector "select[name='barter_status']", "Must not be rendered"
```

**Correct — route the message through Minitest's assert:**
```ruby
assert page.has_css?("input[name='user_name']"),    "Login form must have this field"
assert page.has_no_css?("select[name='barter_status']"), "Must not be rendered"
```

Same rule applies to `assert_text "text", "message"` → `assert page.has_text?("text"), "message"`.

### Capybara select(value) matches by TEXT, not by value= attribute

`select "994812667", from: "software_name_id"` raises ElementNotFound because
Capybara looks for an `<option>` whose visible text is "994812667", not one
whose value attribute is "994812667".

**Wrong:**
```ruby
first_option_value = select_el.all("option").first&.value
select first_option_value, from: "field_name"
```

**Correct — select by element, not by text or value string:**
```ruby
first_option = select_el.all("option").reject { |o| o.value.empty? }.first
first_option.select_option
```

To assert the selection persists after form submit, use has_select? with text:
```ruby
assert page.has_select?("field_name", selected: first_option.text, wait: 5)
```

### Filter forms in Turbo Frames — URL does not update

The software_items, components, and computers filter forms are inside Turbo
Frames. After submitting a filter, the frame content updates but the top-level
URL stays at the bare path (e.g. `/software_items`). URL-based assertions fail.

**Wrong:**
```ruby
within("form[method='get']") { find("[type=submit]").click }
assert_includes current_url, "query=vms"
```

**Correct — assert form field value instead of URL:**
```ruby
click_button "Apply"
assert page.has_field?("query", with: "vms", wait: 5),
  "Query field must reflect submitted value after filter applies"
```

For select filters, use has_select? with option text:
```ruby
click_button "Apply"
assert page.has_select?("sort", selected: first_option.text, wait: 5)
```

### Turbo navigation race in sign_in / sign_out

`form_with` without `local: true` submits via Turbo (async fetch). Calling
`current_path` immediately after `find("[type=submit]").click` races the redirect.

Fix: wait for the login form to disappear before returning from sign_in.
Fix: wait for the sign-out button to disappear before returning from sign_out.

See `application_system_test_case.rb` v1.3.

### <template> elements not findable via assert_selector

HTML `<template>` elements are not part of the live rendering tree. Even with
`visible: :all`, Capybara/Selenium cannot find them via CSS selectors.

**Correct — use evaluate_script:**
```ruby
template_present = evaluate_script(
  "document.querySelector(\"[data-connection-members-target='template']\") !== null"
)
assert template_present, "Form must render the template Stimulus target"
```

---

## !! SYSTEM TESTS — SIGN-OUT LINK MUST BE IN THE NAV (learned Session 60) !!

The `sign_out` helper in ApplicationSystemTestCase clicks a "Sign out" link.
The nav partial (`decor/app/views/common/_navigation.html.erb`) must include
this link inside the `<% if logged_in? %>` block:

```erb
<%= link_to "Sign out", session_path,
      data: { turbo_method: :delete },
      class: "font-medium text-stone-700 hover:text-stone-900" %>
```

Without this link, every system test that calls `sign_out` raises ElementNotFound.
The link was added in v2.3 of the navigation partial.

---

## !! DRY RULE — ALL passwords must use AuthenticationHelper constants !!

`TEST_PASSWORD_CHARLIE = "DecorTest2026!"` added to AuthenticationHelper v2.1.
**No literal password strings are permitted anywhere in the test suite.**
All test files must use:
  TEST_PASSWORD_ALICE   — owners(:one)
  TEST_PASSWORD_BOB     — owners(:two)
  TEST_PASSWORD_CHARLIE — owners(:three)
  TEST_PASSWORD_VALID   — dynamically created owners

---

## !! UI Renames — Rails auto-generates strings from model/column names (learned Session 58) !!

When renaming a concept in the UI, `<h1>` headings alone are not enough.
Also check and override explicitly:
  1. `f.submit`        — derives label from model class name
  2. `f.label :col`   — derives text from column name
  3. Index column headers, show labels, titles, breadcrumbs
  4. Flash notices that reference the field or model name
See RAILS_SPECIFICS.md v3.3 "UI Renames" section for full checklist with examples.

---

## !! FILE TRANSFER PROTOCOL — export/import scripts, @-encoded flat names !!

Session 71 replaced the old "Output Path Collision" rule (and the old
Download File Naming / Upload File Naming rules) with a single scheme: Claude
generates a shell script to export needed files into `decor/export/` (run from
inside that directory) and a placement script for delivered files staged in
`decor/import/`, both using @-encoded flat filenames (full path, `/`→`@`, all
dots except the true extension→`@`). `decor/export/` and `decor/import/` are
both gitignored. See COMMON_BEHAVIOR.md v3.0 "File Transfer Protocol —
Export/Import Scripts" for the full rule.

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
See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! before_validation vs before_save (learned Session 56) !!

If a model generates a field via callback AND validates it for presence, the
callback MUST be `before_validation` — NOT `before_save`.
See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! Mailer views directory — Check existing structure first (learned Session 56) !!

This project stores mailer views under `app/views/mailers/<mailer_name>/`.
Always grep for existing mailer views before creating a new directory.

---

## !! deliver_later vs deliver_now — Admin tools use deliver_now (learned Session 56) !!

`deliver_later` hands off to ActiveJob — letter_opener never intercepts it.
For admin-initiated sends, use `deliver_now`.

---

## !! Email HTML — Gmail strips data: URIs (learned Session 57) !!

See RAILS_SPECIFICS.md v3.3 "Email HTML" section for full rules.

---

## !! ActionMailer::TestHelper in integration tests — include explicitly (learned Session 58) !!

ActionDispatch::IntegrationTest does NOT include ActionMailer::TestHelper
automatically. Include it explicitly in any test file using assert_emails.

---

## !! Newsletter fixture html_body — Set explicitly (learned Session 58) !!

Rails fixture loading bypasses model callbacks. Always set html_body explicitly.

---

## !! Admin update tests — include admin: "true" when updating self (learned Session 58) !!

See SESSION_HANDOVER v64.0 for the full rule.

---

## Session 70 Summary — Owner Part Number feature: IMPLEMENTED, unmigrated/untested

**Code-complete, 11 of 12 planned files delivered. NOT run against a real
database, NOT tested, NOT lint/security-scanned.** Picks up directly from
Session 69's three open design questions — all three answered by Ulli this
session and implemented.

### Confirmed answers and how each was implemented

**1. Uniqueness scope — kept the existing model/type dimension**, per Ulli's
explicit instruction, over the alternative (plain per-owner scope) that was
also on the table. New combined uniqueness:
`(owner, computer_model, owner_part_number, serial_number)` on Computer,
`(owner, component_type, owner_part_number, serial_number)` on Component.
Implemented as a widened `uniqueness: { scope: [...] }` Rails validation on
each model's `serial_number`, backed by a new 4-column unique DB index on
each table (migration 20260716000200).

**2. Presence + defaulting, symmetric across both models/fields** — Ulli
confirmed both `Computer#serial_number` and `Component#serial_number` must
never be blank, both default to `"-"`, and Owner Part Number gets the same
treatment on both models. `Component#serial_number`'s previous
`allow_blank: true` is REMOVED (Component's original asymmetry vs Computer
is now gone). All four default-assignments use `before_validation` — NOT
`before_save` (RAILS_SPECIFICS.md "before_validation vs before_save": a
`before_save` default would run AFTER the presence validation and the blank
value would be rejected first).

**3. Spares collision — Ulli asked directly for a SQL script fixing this,
with placeholder format `"SPARE-#{component.id}"` confirmed.** Implemented
as a two-migration sequence (data-cleaning migration, then a separate
constraint-adding migration, per PROGRAMMING_GENERAL.md's 3-Step Safe
Process):
  - Migration 1 (`20260716000100`): adds both nullable columns, backfills
    blank `Component#serial_number` to `"-"`, detects every
    `(owner_id, component_type_id)` group with 2+ dash-serial components,
    assigns each member of a colliding group a distinct
    `"SPARE-#{component.id}"` (globally unique via `component.id`, no
    per-group counter needed), then blanket-backfills everything else
    (including all of `computers`, which has no collision risk since
    `Computer#serial_number` was already unique per owner+model) to `"-"`.
  - Migration 2 (`20260716000200`): full SQLite table-recreation for both
    `computers` and `components` (explicit column lists, no `SELECT *`) to
    add the `NOT NULL` constraints and swap in the new 4-column unique
    indexes — required because SQLite cannot `ALTER COLUMN` to add
    `NOT NULL` to an already-nullable column.

  **Raised and resolved a design gap in Ulli's proposed fix**: a one-time
  backfill alone doesn't address what happens with the NEXT unserialized
  spare added after the migration runs. Presented as Option A (model-level
  auto-assign of a fresh unique placeholder, mirroring the existing
  `owner_group_id`/`owner_member_id` auto-assign pattern) vs Option B (no
  auto-assign — the constraint simply blocks a second dash/dash spare of the
  same type/owner going forward, requiring the user to supply a real
  distinguishing value themselves). **Ulli confirmed Option B.** This is a
  real, user-visible behaviour change from today, not just an implementation
  detail — flagged clearly in both `component.rb` v1.6's header comment and
  here.

**4. CSV export/import** — Ulli's original request also named
`computer_model_export_service.rb`; this was flagged as a likely mismatch
(that service exports `ComputerModel` catalog/reference data — model names
only — with no relationship to per-instance `owner_part_number` values) and
Ulli confirmed it should be left untouched. `owner_export_service.rb` v1.11
and `owner_import_service.rb` v1.12 were updated instead.

### An import-side consequence surfaced during implementation, not asked, worth knowing

`OwnerImportService` previously never deduplicated blank-serial component
rows at all — the old guard `if serial_number && exists?(...)` skipped the
duplicate check entirely whenever `serial_number` was blank, so re-importing
a CSV with several unserialized spares of the same type created a brand new
row every single time. Now that both `serial_number` and `owner_part_number`
normalize to `"-"` on import (matching the model's own default), that guard
was removed and the duplicate check runs unconditionally — a second
identical `"-"/"-"` spare row of the same type in a re-import will now be
silently skipped as a duplicate, exactly like computers and serialized
components already behave. This is a direct, unavoidable consequence of the
Option B decision above, not a separate bug — but worth a one-time sanity
check against any CSV exported before this migration if Ulli re-imports
spare-heavy historical data.

### Files delivered this session (11 of 12 planned)

    decor/db/migrate/20260716000100_add_owner_part_number_to_computers_and_components.rb  NEW
    decor/db/migrate/20260716000200_enforce_owner_part_number_constraints.rb              NEW
    decor/app/models/computer.rb                                       v2.1 → v2.2
    decor/app/models/component.rb                                      v1.5 → v1.6
    decor/app/controllers/computers_controller.rb                      v1.22 → v1.23
    decor/app/controllers/components_controller.rb                     v2.0 → v2.1
    decor/app/views/computers/_form.html.erb                           v2.6 → v2.7
    decor/app/views/components/_form.html.erb                          v1.11 → v1.12
    decor/app/services/owner_export_service.rb                        v1.10 → v1.11
    decor/app/services/owner_import_service.rb                        v1.11 → v1.12
    decor/test/fixtures/computers.yml                                  v1.9 → v1.10
    decor/test/fixtures/components.yml                                 v1.4 → v1.5

**Not delivered — the 12th item:** `decor/db/schema.rb` regeneration. This
requires actually running `bin/rails db:migrate` against a real database,
which did NOT happen this session. The two-migration table-recreation logic
— especially the `"SPARE-#{id}"` collision backfill in migration 1 — has
never executed against real data. **This is the single highest-risk
untested part of the whole feature and should be the first thing verified
next session**, before anything else.

### Pre-Implementation Verification note — files gathered this session

Per Never-Guess / Pre-Implementation Verification, no model, controller, or
view file was written from memory or convention this session. Every file
touched was read directly first: `computer.rb`, `component.rb`,
`computers_controller.rb`, `components_controller.rb`, both `_form.html.erb`
files, `owner_export_service.rb`, `owner_import_service.rb`, both
`20260316*` migrations, `schema.rb`, `computers.yml`, `components.yml`.

### Upload-collision hit again this session — RESOLVED Session 71

`computers/_form.html.erb` and `components/_form.html.erb` both mangled to
the identical upload filename `_form_html.erb` (Rails' partial-naming
convention plus the browser's dot-to-underscore substitution on upload).
Uploading them in separate messages (the old "Upload File Naming" rule's
prescription) was NOT sufficient — the mangled name being identical meant
the second upload silently overwrote the first ON DISK mid-session regardless
of message separation, and the first file's content (already viewed) had to
be re-requested and re-uploaded from scratch. This was flagged here as a
stronger failure mode than the old rule anticipated, and formalized in
Session 71: COMMON_BEHAVIOR.md v3.0's new "File Transfer Protocol —
Export/Import Scripts" replaces one-file-per-message with @-encoded flat
filenames (full path, `/`→`@`, all dots except the true extension→`@`),
which structurally prevents this collision — the encoded name always
contains the full path, so two files can never encode to the same name.

### Scope notes — deliberately not touched this session

- The embedded Component sub-table inside `computers/_form.html.erb`
  (Type | Description | Order No. | Serial No. | Condition | Trade) — shows
  each Component's own fields via a separate association; not requested to
  gain an Owner Part No. column, so left as-is. Flagged inline in the file's
  own v2.7 header comment.
- No index/show display views were touched — not requested, not provided
  this session. Owner Part Number is currently only visible on the edit/new
  forms and in CSV export/import.

### NOT YET DONE — required before this feature can be committed

    [ ] bin/rails db:migrate                          — never run against a real DB this session
    [ ] decor/db/schema.rb                             — regenerate and review after migrating
    [ ] Tests — 6 test files needed as Pre-Implementation Verification inputs before
        writing test code (Never-Guess): computer_test.rb, component_test.rb,
        owner_export_service_test.rb, owner_import_service_test.rb,
        computers_controller_test.rb, components_controller_test.rb
    [ ] bin/rails test                                 — not run (blocked on migrate + tests above)
    [ ] bundle exec rubocop -A / bundle exec rubocop   — lint fix + verify
    [ ] bin/brakeman --no-pager                        — static code security scan
    [ ] bundle exec bundle-audit check --update        — dependency CVE scan
    [ ] Manual browser check: both new form fields, CSV export/import round-trip
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

    This now stacks on top of Sessions 67/68/69's own already-outstanding
    pre-commit checklists (see their respective summaries below/further down
    in this document) — FOUR sessions' worth of uncommitted local work.

---

## Session 69 Summary — UI Terminology Rename (implemented) + Owner Part Number (design only)

### Part 1 — UI Terminology Rename: IMPLEMENTED, 15 files

Renamed throughout the owner-facing and admin UI:
"Model" → "Computer Model", "Order Number" → "DEC Part Number",
"Serial Number" → "DEC Serial Number". Display text only — no attribute,
column, or route renamed. Full mapping (including the abbreviated-header
variants and what was deliberately left alone) now recorded in
DECOR_PROJECT.md "UI Terminology — Established Renames (Session 69)" —
**future sessions must use those labels for any new UI, not the legacy
terms.**

Scope was confirmed with the user mid-session: the Admin > Component
Suggestions screens and the two admin.html.erb Components-dropdown menu
links ARE in scope (not just the primary Computer/Component forms).

    decor/app/views/computers/_filters.html.erb                    v1.6 → v1.7
    decor/app/views/computers/index.html.erb                       v1.9 → v1.10
    decor/app/views/computers/_computer_component_form.html.erb    v1.3 → v1.4
    decor/app/views/computers/_computer.html.erb                   v1.10 → v1.11
    decor/app/views/components/_form.html.erb                      v1.10 → v1.11
    decor/app/views/components/show.html.erb                       v1.7 → v1.8
    decor/app/views/components/index.html.erb                      v1.6 → v1.7
    decor/app/views/computer_statistics/index.html.erb             v1.1 → v1.2
    decor/app/views/owners/computers.html.erb                      v1.4 → v1.5
    decor/app/views/owners/peripherals.html.erb                    v1.3 → v1.4
    decor/app/views/owners/components.html.erb                     v1.4 → v1.5
    decor/app/views/admin/component_suggestions/_form.html.erb     v1.0 → v1.1
    decor/app/views/admin/component_suggestions/_filters.html.erb  v1.0 → v1.1
    decor/app/views/admin/component_suggestions/index.html.erb     v1.3 → v1.4
    decor/app/views/layouts/admin.html.erb                         v2.7 → v2.8

Note: `decor/app/views/computers/_form.html.erb` and
`decor/app/views/computers/show.html.erb` needed NO changes — Ulli had
already renamed those two himself before this session started.

**Deliberately left unchanged** (flagged to the user, not yet decided):
- CSV column headers / literal `order_number`/`serial_number` references in
  `data_transfers/show.html.erb` and `admin/bulk_uploads/new.html.erb` —
  these are the actual import/export contract field names.
- The downloaded CSV filename `unvalidated_order_numbers_<date>.csv` in
  `admin/component_order_numbers_controller.rb` — still says the old term;
  not addressed since it's controller/service code, a step beyond "UI
  labels."
- Whether Owner Part Number-style CSV export/import fields should be
  touched — not applicable to this rename (no such field existed yet), but
  raised here since it came up again in Part 2 below.

**NOT YET DONE for this rename:**
    [ ] Grep test/ for hardcoded assertions on "Order Number" / "Serial Number" / "Model"
        text (RAILS_SPECIFICS.md "UI Renames" checklist flags this explicitly) — not yet run
    [ ] bin/rails test — not run this session (no logic changed, but unverified)
    [ ] Manual browser check of all 15 renamed views
    [ ] git workflow — on top of Session 67's already-outstanding checklist below

### Part 2 — Owner Part Number: DESIGN CONSULTATION ONLY, NOT IMPLEMENTED

No files created or modified for this part. Full detail in DECOR_PROJECT.md
"Owner Part Number Feature — Session 69" — summary here:

Requested: new `VARCHAR(20)` "Owner Part Number" field on `computers`
(covers peripherals) and `components`, defaulting to `"-"`; DEC Serial
Number also backfilled to `"-"` where blank; uniqueness changed from DEC
Serial Number alone to the (Owner Part Number, DEC Serial Number) pair,
scoped per owner.

Before writing anything, `decor/app/models/computer.rb` and
`decor/app/models/component.rb` were read directly (Pre-Implementation
Verification / Never-Guess). This surfaced three open questions, none yet
answered by the user:

1. **Uniqueness scope** — today's constraint is `(owner, computer_model)`
   for Computers / `(owner, component_type)` for Components, not plain
   "per owner" as described. Keep that extra dimension in the new
   constraint, or drop it?
2. **Asymmetric presence today** — `Computer.serial_number` already has
   `presence: true` (can't be blank now); `Component.serial_number` has
   `allow_blank: true` (genuinely can be blank). Confirm this asymmetry
   should persist.
3. **Spares collision risk (real design conflict)** — Components
   intentionally allow multiple unserialized spares of the same type per
   owner today. Defaulting both new fields to `"-"` under a plain
   multi-column uniqueness check would break that — every such spare would
   collide on `"-"`/`"-"`. Recommend exempting `"-"`/`"-"` combinations from
   the uniqueness check (dash-sentinel equivalent of today's `allow_blank`),
   but not yet confirmed.

**Files requested from the user, not yet received:**
    The migration(s) that added serial_number + its unique index (referenced
      in the model comments as 20260316120000 and 20260316110000)
    decor/db/schema.rb (or a fresh schema dump)
    decor/test/fixtures/computers.yml
    decor/test/fixtures/components.yml

**Status: WAITING — do not implement until the three questions above are
answered and the requested files are provided.**

---

## Session 67 Summary — Component Suggestions Phase 4: fully implemented

**All four confirmed requirements from Session 66 delivered.** 12 production
files (4 new, 8 updated) + 4 test files updated/added. `bin/rails test`:
900 tests, 0 failures, 0 errors, on the final run this session.

### Files delivered

    decor/db/migrate/20260707000100_add_manual_and_enlarge_description_to_component_suggestions.rb  NEW
    decor/app/models/component_suggestion.rb                                    v1.0 → v1.1
    decor/app/services/component_suggestion_import_service.rb                   v1.0 → v2.0
    decor/app/services/manual_component_suggestions_export_service.rb          v1.0 → v1.1 NEW
    decor/app/controllers/admin/component_suggestions_controller.rb            v1.0 → v1.2
    decor/config/routes.rb                                                      v3.5 → v3.6
    decor/app/views/layouts/admin.html.erb                                      v2.6 → v2.7
    decor/app/helpers/admin/component_suggestions_helper.rb                     NEW
    decor/app/views/admin/component_suggestions/_filters.html.erb              NEW
    decor/app/views/admin/component_suggestions/_component_suggestion.html.erb NEW
    decor/app/views/admin/component_suggestions/index.html.erb                 v1.0 → v1.1
    decor/app/views/admin/component_suggestions/index.turbo_stream.erb         NEW

    decor/test/models/component_suggestion_test.rb                            v1.0 → v1.1
    decor/test/services/manual_component_suggestions_export_service_test.rb   NEW
    decor/test/services/component_suggestion_import_service_test.rb           v1.0 → v2.0
    decor/test/controllers/admin/component_suggestions_controller_test.rb     v1.0 → v1.1

`component_suggestion_export_service_test.rb` needed no changes — the
underlying `ComponentSuggestionExportService` is untouched by Phase 4.

### What each piece does

**Migration:** nullable `manual` VARCHAR(1) column (`"a"` added / `"m"`
modified / `null` untouched bulk-import row, permanent once `"a"`); widened
`description` VARCHAR(100) → VARCHAR(510) for concatenated main+variant text.

**"Download Manual Changes":** new `ManualComponentSuggestionsExportService`
exports every `manual: "a"`/`"m"` row (both together, one CSV) — the
required backup step before a re-import, since the import deletes
everything unconditionally with no preservation. New collection route +
admin.html.erb link.

**Import rewrite (the core fix):** `ComponentSuggestionImportService` v1.0's
per-row `exists?` check (O(n) DB round-trip per row) was the confirmed root
cause of production timeouts at ~55,000 rows. v2.0: `delete_all` +
batched `insert_all(unique_by: :order_number)` inside one transaction — zero
per-row DB reads. Accepted tradeoff: bypasses Rails model validations
entirely (documented in RAILS_SPECIFICS.md); acceptable since the source
data is a trusted external DEC-database export.

**Paginated + filterable admin index:** root cause of the slow page load
confirmed by code review — v1.0 had no pagination and no filtering
whatsoever. Rewritten to match the project's established geared_pagination
"Load more" infinite-scroll pattern (same as software_items/computers/
components), with a new filter sidebar: order_number substring search
(confirmed as substring, not prefix — different use case from the
typeahead's `:matching` scope) + a manual-flag filter.

### create/update manual-flag logic

    create:  manual always set to "added" — permanent, never reverts on later edits.
    update:  manual promoted from nil → "modified" ONLY on a previously-untouched
             row. A row already "added" or "modified" keeps its value unchanged.
    Neither value is accepted as a raw form param — always set explicitly in
    the controller, never in component_suggestion_params.

### Two mistakes made and corrected mid-session — both now codified as rules

1. **Route-naming shape guessed wrong initially.**
   `admin_download_manual_component_suggestions_path` was assumed (matching
   the Session 65 `as:` shape), but the real helper — confirmed by running
   `bin/rails routes | grep download_manual` before shipping — is
   `download_manual_admin_component_suggestions_path`. A collection route
   nested in `resources` inside a namespace prepends the action to the
   already-prefixed resource name, a different shape than a custom `as:`
   route in the same namespace. Caught before shipping because the
   verification step was actually run. New RAILS_SPECIFICS.md v3.6 section.

2. **A file was inferred from convention and flagged rather than requested.**
   `index.turbo_stream.erb` was written from the standard Rails/Turbo
   "append + replace" idiom, explicitly labeled in its own header as
   unverified, and delivered alongside genuinely file-based deliverables.
   The user pointed out this was still a Never-Guess violation despite the
   disclosure. The real file was then requested and uploaded — the guess
   turned out to match exactly, but that was luck, not rule compliance.
   New COMMON_BEHAVIOR.md v2.8 section: "Flagging a Guess Does Not Satisfy
   Never-Guess."

Also one real bug caught by the test suite itself and fixed the same
session: `ManualComponentSuggestionsExportService` used
`read_attribute(:manual)` expecting the raw `"a"`/`"m"` value, but Rails
enum type-casting means `read_attribute` returns the mapped label
(`"added"`/`"modified"`) same as the plain accessor. Fixed with
`manual_before_type_cast`. New RAILS_SPECIFICS.md v3.6 section.

### Also fixed this session (unrelated to Phase 4 logic, but blocking CI)

`bundle-audit` flagged the `json` gem (CVE-2026-54696, transitive
dependency) — fixed with `bundle update json`; `bundle exec bundle-audit
check --update` came back clean afterward. Per RAILS_SPECIFICS.md "CI
Security Checks — Two Separate Tools" scope note, this should also be
reflected on `main` (merge this branch's PR, or merge Dependabot's
equivalent PR if it lands first) so the next branch doesn't inherit the
same failing baseline.

### File-placement friction, worth remembering for future sessions

Several rounds of "tests still failing" during this session turned out to
be the delivered files simply not yet copied into the actual project paths
(old versions of `component_suggestion.rb`, `component_suggestion_import_
service.rb` still in place; the new `manual_component_suggestions_export_
service.rb` not added at all) — not code bugs. Worth a habit for future
sessions: after a "still failing" report, check whether the failure
signatures match "old code still running" (uninitialized constant, wrong
validation limits, missing methods) before assuming a logic bug in the
newly-delivered code.

### NOT YET DONE — required before this can be committed

    [ ] bundle exec rubocop -A / bundle exec rubocop — lint fix + verify (not run this session)
    [ ] bin/brakeman --no-pager                      — static code security scan (not run this session)
    [ ] Manual browser check: filters, Load more, Download Manual Changes link, re-import behavior
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy
    [ ] Confirm main also gets the json gem bump (this PR, or Dependabot's PR, whichever merges first)

---

## Session 66 Summary — Order Number / Variant: design pivot, no implementation

**Design consultation only. No files were created, modified, or committed
this session.**

A full multi-column variant-split design (splitting `order_number` into
main + variant columns on `component_suggestions`, a three-state
`order_number_match_status` on `components`, two-file CSV import/export,
Stimulus typeahead rework, a match-status badge on the component form) was
worked out in complete detail across this session — schema, matching logic,
import/export rules, deletion guards, form behavior — but was set aside
**before implementation began**. Reason: recognized risk of "self-indulgent
featuritis" — added complexity on both the implementation/maintenance side
and the user-facing side, without confirmed need at the scale involved
(~13,000 components / ~46,000 suggestion combinations at the time).

That full design is saved for reference at
`decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md` — **NOT implemented, NOT
the current direction.** Copy this file into the project docs folder if it
isn't already there. Revisit only if the adopted simpler approach (below)
proves insufficient.

### Adopted approach instead (closer to original "Option A" from the design doc)

Main order number + variant are concatenated into **one** `order_number`
string at the DEC-database export stage (e.g. `"DELQA-00"`) — **no bare/
undashed part numbers**; every record has an explicit variant suffix,
`"-00"` for base models. Both descriptions (main + variant) are
concatenated into **one** `description` field using `" | "` as a delimiter
(tested — confirmed not to conflict with any existing data). **No schema
split of `order_number` or `description`** — this is the key simplification
versus the shelved design. Data scope: ~55,000 `component_suggestions`
records after filtering (expanded from ~46,000, tested up from ~85,000
before filtering).

### Confirmed requirements for next session

**1. Migration on `component_suggestions`:**
   a. New nullable `manual` field, two possible values:
      - `"a"` = record added manually (via admin form, not from bulk import)
      - `"m"` = record modified manually (originated from bulk import,
        later hand-edited via admin form)
      - `null` = untouched bulk-import record (the default/normal case)
      Once a row is flagged `"a"`, it **stays `"a"` permanently** — further
      edits never change it to `"m"` (confirmed). Likely implementation:
      `VARCHAR(1)` nullable column + Rails `enum` mapping raw values
      (e.g. `added: "a", modified: "m"`) — confirm exact column type and
      enum declaration syntax against this project's conventions (see
      `device_type`/`barter_status` hash-enum precedent in `computer.rb`)
      when writing the actual migration/model code.
   b. Enlarge `description` column from `VARCHAR(100)` to `VARCHAR(510)` —
      concatenated dual descriptions need more room than the original
      single-description field was sized for.

**2. Admin "Components" dropdown — new download option:**
   CSV export of all `component_suggestions` rows where `manual IS NOT
   NULL` (both `"a"` and `"m"` together, one download). This is the
   **required backup mechanism** for manual work: the import (below)
   deletes these rows unconditionally along with everything else, so an
   admin must download this list **before** running a re-import if they
   want to reapply manual changes afterward. Exact CSV columns and the
   menu label were not finalized this session — decide at implementation
   time (likely: `order_number, description, category, manual`, following
   the pattern of the existing "Download Unvalidated Order Numbers"
   feature from Session 65).

**3. Import service — full rewrite (root cause of production timeout):**
   Confirmed root cause: the current import checks every incoming row for
   a conflict against existing records — an O(n) lookup per row against a
   table that only grows, which is exactly why it times out in production
   and takes minutes locally even before scaling further.
   a. **Delete ALL existing `component_suggestions` records
      unconditionally** — including `"a"`/`"m"` manual rows. **No
      preservation logic of any kind** (confirmed — the download in
      item 2 is the intended backup step, to be run by the admin *before*
      triggering a re-import, not automated by the import itself).
   b. **Bulk-insert all new records.** The only constraint is
      `order_number` uniqueness, already enforced by SQLite's existing
      unique index — **no app-level duplicate pre-check is needed at all**.
      Replace whatever per-record `find_or_create_by`/conflict-check loop
      exists with a batched `insert_all` (or equivalent bulk-insert
      approach) to eliminate the O(n²) behavior entirely. This is the
      single highest-value fix from this session's findings.
   This is the right design **because the data's source of truth is the
   external DEC database** — Rails' `component_suggestions` table is a
   disposable, fully-regenerated mirror of it on every import, not a
   record that needs reconciliation against prior state.

**4. Admin suggestions index/listing page is slow to LOAD** (once loaded,
   performance is fine — this is a load-time issue only, not a rendering
   or interaction issue). Root cause **not yet diagnosed** — needs the
   actual controller and view files to investigate. Candidates to check
   first: missing pagination (geared_pagination gem is used elsewhere in
   this project — confirm it's actually applied here), a missing DB index
   backing a sort/filter/search column at ~55,000 rows, or an N+1
   association load in the index action.

### Files needed at start of next session (not yet reviewed this session)

```
decor/db/migrate/20260511000100_create_component_suggestions.rb
decor/app/models/component_suggestion.rb
decor/app/services/component_suggestion_import_service.rb
decor/app/services/component_suggestion_export_service.rb
decor/app/controllers/admin/component_suggestions_controller.rb
decor/app/views/admin/component_suggestions/index.html.erb
decor/app/views/layouts/admin.html.erb
decor/config/routes.rb
decor/test/fixtures/component_suggestions.yml
```

(As of Session 71, prefer the File Transfer Protocol — export/import scripts
with @-encoded flat filenames — over manually uploading these one at a time;
see COMMON_BEHAVIOR.md v3.0.)

---

## Session 65 Summary

**Focus: Component order_number bulk maintenance — two new items in the admin
Components dropdown.**

### Confirmed design decisions (from Ulli, before implementation)

    Re-validate applies immediately — no preview step (bulk data-integrity sync).
    Download list — one row per component, NOT deduplicated by order_number.
    Menu placement — existing Components dropdown, not a new dropdown.

### Files delivered this session (8 files)

    decor/config/routes.rb                                                v3.4 → v3.5
    decor/app/controllers/admin/component_order_numbers_controller.rb     v1.0  NEW
    decor/app/services/component_order_number_revalidation_service.rb     v1.0  NEW
    decor/app/services/unvalidated_order_numbers_export_service.rb        v1.0  NEW
    decor/app/views/layouts/admin.html.erb                                v2.4 → v2.6
    decor/test/services/component_order_number_revalidation_service_test.rb  v1.0 NEW
    decor/test/services/unvalidated_order_numbers_export_service_test.rb     v1.0 NEW
    decor/test/controllers/admin/component_order_numbers_controller_test.rb  v1.0 NEW

Also updated (rule documents, this session):
    decor/docs/claude/RAILS_SPECIFICS.md   v3.4 → v3.5
    decor/docs/claude/DECOR_PROJECT.md     v2.56 → v2.57

### Feature: "Re-validate Order Numbers" (POST /admin/component_order_numbers/revalidate)

Re-syncs `order_number_verified` for every `Component` against the current
`component_suggestions` table: `true` iff `order_number` is present AND
matches a `component_suggestions.order_number`; else `false`. Symmetric — can
flip a component in either direction (e.g. un-verifies a component if its
matching `ComponentSuggestion` was later deleted). Uses `update_column`
(skips validations — this is a data-integrity sync, not a form edit).
Redirects to `admin_component_suggestions_path` with a flash summarising
verified/unverified/unchanged counts.

### Feature: "Download Unvalidated Order Numbers" (GET /admin/component_order_numbers/unvalidated)

CSV export, one row per component (not deduplicated), ordered by component
id, limited to components with a non-blank `order_number` and
`order_number_verified: false`. Columns: `order_number, component_type,
owner, serial_number, description`.

### Bug found and fixed mid-session: NameError in admin.html.erb v2.5

Both new dropdown links used `revalidate_component_order_numbers_path` /
`unvalidated_component_order_numbers_path` — missing the `admin_` prefix that
Rails still applies to `as:` routes declared inside `namespace :admin do ... end`.
Fixed in v2.6. New MANDATORY rule added to RAILS_SPECIFICS.md v3.5: **"Named
Routes (as:) Inside namespace — Still Prefixed."** See that document for the
full rule, including the `bin/rails routes | grep <name>` verification tip.

### Test design notes

All three new test files create `Component` records fresh in-test, assigned
to `owners(:three)` (the project's neutral owner — see RAILS_SPECIFICS.md
"Fixture Ownership"), rather than adding new fixtures. Both new services scan
**every** `Component` row project-wide, so a hardcoded count assertion would
be fragile against the existing `components.yml` fixture set (all of which
have a blank `order_number`). Assertions target either the specific records
each test creates, or `Component.count` derived at call time.

### NOT YET DONE — required before this feature can be committed

    [ ] bin/rails test                              — tests were written but never run
    [ ] bundle exec rubocop -A / bundle exec rubocop — lint fix + verify
    [ ] bin/brakeman --no-pager                      — static code security scan
    [ ] bundle exec bundle-audit check --update      — dependency CVE scan (separate tool — see RAILS_SPECIFICS.md v3.5 "CI Security Checks")
    [ ] Manual browser check of both new Components dropdown links
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

---

## Session 61 Summary

**Focus: Computers Statistics page + Statistics dropdown in the top nav.**

Local testing passed. All existing tests continue to pass.

### Files delivered this session (7 files)

    decor/config/routes.rb                                                v3.1 → v3.2
    decor/app/controllers/computer_statistics_controller.rb               v1.0 → v1.1  NEW
    decor/app/helpers/computer_statistics_helper.rb                       v1.0         NEW
    decor/app/views/computer_statistics/_filters.html.erb                 v1.0         NEW
    decor/app/views/computer_statistics/index.html.erb                    v1.0 → v1.1  NEW
    decor/app/views/common/_navigation.html.erb                           v2.3 → v2.4
    decor/test/controllers/computer_statistics_controller_test.rb         v1.0 → v1.1  NEW

### Feature: Computers Statistics page (`/computer_statistics`)

**Route:** `GET /computer_statistics` → `ComputerStatisticsController#index`
Named helper: `computer_statistics_path`.

**Controller strategy (two queries, Ruby-side sort):**
- Query 1: `Computer.where(device_type: "computer").group(:computer_model_id).count`
  Returns a Hash `{ computer_model_id => Integer }` scoped to actual computers only.
  Peripheral Computer records that reference a computer ComputerModel are excluded.
  (Confirmed in fixtures: `dec_unibus_router` has `computer_model: pdp11_70`.)
- Query 2: `ComputerModel.where(device_type: "computer")` — all computer models.
- Map to `[{ model:, count: }]`, reject count == 0, then sort in Ruby.

**Sort options** (param: `sort`):
- `most_common` (default) — `sort_by { [-count, name] }`
- `least_common`           — `sort_by { [count, name] }`
- `model_asc`              — `sort_by { name }`
- `model_desc`             — `sort_by { name }.reverse`

**Zero-count exclusion:** models with no registered computers are rejected before
the sort step. They do not appear in the table.

**Filter partial** — Search (LIKE by model name) + Sort only. No condition/run-status/
barter filters (those are per-computer attributes, not per-model attributes).

**Table layout:** `w-auto` (not `min-w-full`) so the table shrinks to content width.
Count column is `text-left pl-10` — sits close to the model name column.
Model names link to `computers_path(model: stat[:model].id)` (pre-filters computers
index to that model).

### Feature: Statistics dropdown in the top nav

`_navigation.html.erb` v2.4 — new "Statistics ▾" dropdown appended after "Software"
in the left nav group. Uses the same `data-controller="dropdown"` pattern as "Info".
First (and currently only) entry: "Computers" → `computer_statistics_path`.
Future statistics pages can be added as additional `link_to` entries in this dropdown.

---

## Session 60 Summary

**Focus: System tests — fixed all 48 failures/errors from Session 59 test:system run.**

Final result: **49 tests, 0 failures, 0 errors, 0 skips.**

### Files delivered this session (8 files)

    decor/test/application_system_test_case.rb             v1.1 → v1.3
    decor/app/views/common/_navigation.html.erb            v2.2 → v2.3
    decor/test/system/authentication_test.rb               v1.0 → v1.1
    decor/test/system/computers_filters_test.rb            v1.0 → v1.2
    decor/test/system/software_items_filters_test.rb       v1.0 → v1.2
    decor/test/system/components_filters_test.rb           v1.0 → v1.2
    decor/test/system/connection_groups_test.rb            v1.0 → v1.3
    decor/docs/claude/RAILS_SPECIFICS.md                   v3.2 → v3.3

### Root causes fixed (6 categories)

1. **ArgumentError on Capybara assert_selector** — 17 occurrences across 5 test files.
   `assert_selector "css", "message"` → `assert page.has_css?("css"), "message"`.
   Same for refute_selector → `has_no_css?`, assert_text → `has_text?`.

2. **Turbo navigation race in sign_in** — form_with without local: true submits
   asynchronously. Added `has_no_field?("user_name", wait: 5)` after submit click
   in application_system_test_case.rb.

3. **sign_out had no target link** — the nav partial had no "Sign out" link.
   Added `link_to "Sign out", session_path, data: { turbo_method: :delete }` to
   `_navigation.html.erb` v2.3. Changed sign_out helper to `click_on "Sign out"`.

4. **Capybara select(value) matches by TEXT** — fixture IDs passed as value strings
   never matched. Fixed by using `first_option.select_option` throughout and
   asserting with `has_select?("name", selected: first_option.text, wait: 5)`.

5. **Filter forms in Turbo Frames — URL doesn't update** — replaced all
   `assert_includes current_url, "param="` assertions with `has_field?` /
   `has_select?` assertions that check form state rather than URL.

6. **<template> element not findable via Capybara** — replaced
   `assert_selector "...", visible: :all` with
   `evaluate_script("document.querySelector(...) !== null")`.

### Production change: navigation partial v2.3

Added "Sign out" link to `_navigation.html.erb`. This is visible to all
logged-in users in the top-right nav. Required for system tests but also
correct UX — users previously had no way to sign out from the nav.

---

## Session 59 Summary

**Focus: System tests — Track 1 (JS-dependent interactions) + DRY fix.**

### Files delivered (7 files)

    decor/test/application_system_test_case.rb             v1.0 → v1.1
    decor/test/support/authentication_helper.rb            v2.0 → v2.1
    decor/test/controllers/computers_controller_test.rb    v1.10 → v1.11
    decor/test/system/authentication_test.rb               v1.0  NEW
    decor/test/system/computers_filters_test.rb            v1.0  NEW
    decor/test/system/components_filters_test.rb           v1.0  NEW
    decor/test/system/software_items_filters_test.rb       v1.0  NEW
    decor/test/system/connection_groups_test.rb            v1.0  NEW

---

## Priority 1 — Future Sessions

1. **System tests Track 2** — Tom Select combobox, admin CRUD flows, full auth flow.
2. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.
6. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
   `production.rb` to the app's public hostname.

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
