# decor/docs/claude/SESSION_HANDOVER.md
# version 66.0
# Session 61: Computers Statistics page + Statistics nav dropdown.

**Date:** May 10, 2026
**Branch:** main (Sessions 49–60 committed, pushed, merged, deployed)
**Status:** Session 61 complete — Computers Statistics page live, all tests pass.

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
