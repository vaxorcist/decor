# decor/docs/claude/SESSION_HANDOVER.md
# version 58.0
# Session 54: Tom Select searchable combobox for long drop-down lists.

**Date:** April 17, 2026
**Branch:** main (Sessions 49–53 committed, pushed, merged, deployed)
**Status:** Session 54 complete — ready to commit, push, merge, deploy.

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

Session 54 ended at ~83% of the context window.
Start Session 55 fresh.

---

## !! OUTPUT FILE NAMING — NEVER substitute underscores for dots (learned Session 54) !!

When creating a file with create_file, use the exact filename including all dots
(e.g. application.html.erb, not application_html.erb). Browser upload substitution
is an upload-only constraint. Claude controls output filenames entirely.
See COMMON_BEHAVIOR.md v2.6 for the full rule.

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
`refute_body_includes` from ResponseHelpers instead. The default helpers dump
the full HTML on failure; the project helpers truncate to 300 chars.
See RAILS_SPECIFICS.md v2.8 for the full rule.

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements. Use serial numbers,
version strings, or other values that only appear in data rows.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

`data-turbo="false"` on any ancestor disables Turbo for ALL descendants.
A `data-turbo-method="delete"` link inside such a wrapper silently falls back
to a plain GET → routing error. Fix: keep the link outside any Turbo-disabled element.
See RAILS_SPECIFICS.md v2.8 for the full rule.

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

`grid-cols-3` (or any equal-fraction grid) on a navbar causes the left column
to overflow when it has many items; later grid cells render on top, making
overflowed links unclickable. Fix: `grid-cols-[auto_1fr_auto]` for
left/logo/right navbar layouts. See RAILS_SPECIFICS.md v2.8 for the full rule.

---

## Session 54 Summary

**Focus: Tom Select searchable combobox for long drop-down lists.**

### Files delivered this session (7 files)

    decor/app/javascript/controllers/tom_select_controller.js   v1.0  NEW
    decor/config/importmap.rb                                   v1.1
    decor/app/views/layouts/application.html.erb                v1.4
    decor/app/views/computers/_form.html.erb                    v2.6
    decor/app/views/components/_form.html.erb                   v1.8
    decor/app/views/software_items/_form.html.erb               v1.1
    decor/docs/claude/COMMON_BEHAVIOR.md                        v2.6

### Changes

**Feature: Searchable combobox on all long drop-down selects**
- Problem: Native `<select>` type-ahead only jumps to the first item starting with
  a typed letter. With 400+ peripheral models this is essentially unusable.
- Solution: Tom Select library — replaces native selects with a searchable combobox.
  User types any substring; matching options are filtered in real time.
- importmap.rb v1.1: pinned Tom Select ESM "complete" build from jsDelivr CDN.
  No gem, no npm — CDN pin is correct approach for importmap-rails projects.
  (bundle add tom-select-rails was tried by user and immediately removed — the gem
  is not needed and its auto-injected assets would conflict with the CDN approach.)
- tom_select_controller.js v1.0 (NEW): Stimulus controller. connect() inits Tom
  Select on any `<select data-controller="tom-select">`; disconnect() calls
  tomSelect.destroy() to restore the native element before Turbo caches the page.
  Guard: returns early if element.tomselect already set (prevents double-init on
  Turbo snapshot restore).
- application.html.erb v1.4: CDN CSS link + project-matching style overrides.
  Root cause of sizing bug (found via Firefox DevTools): Tom Select copies ALL
  classes from the `<select>` to .ts-wrapper. field_classes (h-10 p-3 border...)
  were being applied to the wrapper AND to .ts-control — two boxes competing.
  Fix: .ts-wrapper.single (specificity 0,2,0) resets visual properties off the
  wrapper; .ts-control is the sole styled element. Focus colour corrected to
  border-stone-500 (not indigo — field_classes uses stone-500 + outline:none).
- computers/_form.html.erb v2.6: Tom Select on computer_model_id (primary use
  case: 400+ models), computer_condition_id, run_status_id. barter_status (3
  options) left as native select.
- components/_form.html.erb v1.8: Tom Select on component_type_id and
  component_condition_id. computer_id intentionally excluded: it has
  data-controller="computer-select" with focus/blur actions (openDropdown /
  closeDropdown) that Tom Select would silence by hiding the native element.
- software_items/_form.html.erb v1.1: Tom Select on software_name_id,
  software_condition_id, computer_id. No conflicting controller on computer_id
  here (unlike components form), so it is safe to apply.

**Rule: Output file naming — never substitute underscores for dots**
- COMMON_BEHAVIOR.md v2.6: new rule added. create_file output filenames must
  use exact dots (application.html.erb not application_html.erb). Browser upload
  substitution is upload-only; Claude controls output filenames entirely.
- Real example: application.html.erb was delivered as application_html.erb.

---

## Session 53 Summary

**Focus: Bug fixes + Download Text feature.**

### Files delivered this session (8 files)

    decor/app/views/admin/owners/index.html.erb                        v1.2
    decor/config/routes.rb                                             v3.0
    decor/app/controllers/admin/site_texts_controller.rb               v1.2
    decor/app/views/admin/site_texts/download_confirm.html.erb         v1.0  NEW
    decor/app/views/admin/site_texts/delete_confirm.html.erb           v1.1
    decor/app/views/layouts/admin.html.erb                             v2.2
    decor/app/views/common/_navigation.html.erb                        v2.2
    decor/test/controllers/admin/site_texts_controller_test.rb         v1.1

### Changes

**Bug: Admin Manage Owners showed wrong computers count (included peripherals)**
- admin/owners/index.html.erb v1.2: `owner.computers.count` →
  `owner.computers.device_type_computer.count`. Same scope already used in the
  owner-facing `_owner.html.erb` (v3.5, Session 41) but missed in the admin view.

**Feature: Download Text added to admin Texts menu**
- routes.rb v3.0: added `get :download_confirm` (collection) and `get :download`
  (member) inside `resources :site_texts`.
- site_texts_controller.rb v1.2: `download_confirm` action (selector page) and
  `download` action (`send_data` with `disposition: "attachment"`; redirects with
  alert if text not yet uploaded).
- download_confirm.html.erb v1.0 (NEW): selector + Download link; each `<option>`
  carries its URL in `data-download-url`; inline JS reads that attribute on change.
- admin.html.erb v2.2: "Download Text" added between Upload and Delete in Texts dropdown.

**Bug: Delete Text routing error (No route matches [GET] "/admin/site_texts/:key")**
- delete_confirm.html.erb v1.1: removed the dead `form_with` wrapper that had
  `data: { turbo: false }`, which disabled Turbo on the `data-turbo-method="delete"`
  link inside it, causing the browser to issue a plain GET instead of DELETE.
- Root cause: `data-turbo="false"` propagates to all descendants; Turbo-method
  links inside a Turbo-disabled ancestor are silently downgraded to GET.
- Why no test caught it: controller tests call routes directly, bypassing the
  view layer and JS behaviour entirely. Only catchable by system tests.

**Bug: Software nav button unclickable / only clickable at bottom edge**
- _navigation.html.erb v2.2: `grid-cols-3` → `grid-cols-[auto_1fr_auto]`.
  Added `relative z-10` to left div as safety net.
- Root cause: `grid-cols-3` creates three equal `1fr` columns. The left flex
  (6 nav links) exceeded `1fr`, overflowing into centre and right cells. CSS
  grid does not clip overflow but stacks later cells on top in source order,
  making the overflowed Software link partially or fully unclickable.
  Admins (Admin link + username dropdown in right column) were worst affected.

**Test: site_texts_controller_test.rb updated**
- v1.1: added `download_confirm` (renders page) and `download` (happy path:
  content type + disposition + body; missing key: redirect with alert) tests.
  Added comment documenting why the delete_confirm Turbo bug was invisible to
  controller tests.

---

## Priority 1 — Future Sessions

1. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
2. **System tests** — decor/test/system/ still empty.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.

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
