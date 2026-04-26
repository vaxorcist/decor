# decor/docs/claude/SESSION_HANDOVER.md
# version 59.0
# Session 55: Image captions, home page stats, admin owners peripherals column.

**Date:** April 26, 2026
**Branch:** main (Sessions 49–54 committed, pushed, merged, deployed)
**Status:** Session 55 complete — ready to commit, push, merge, deploy.

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
pressure. Estimates were consistently too optimistic. The floor in COMMON_BEHAVIOR.md
has been raised from 40% to 50% for sessions with 5+ large documents.
Start Session 56 fresh.

---

## !! OUTPUT PATH COLLISION — NEVER write two files to the same output path (learned Session 55) !!

When two or more files in the same session share the same base filename
(e.g. multiple `index.html.erb` files), write each to a DISTINCT path in
`/mnt/user-data/outputs/` using a short prefix + underscore
(e.g. `home_index.html.erb`, `admin_owners_index.html.erb`).
The second write silently overwrites the first — no warning, file just gone.
Download display name still uses `#` separator per existing rule.
See COMMON_BEHAVIOR.md v2.7 for the full rule.

---

## !! OUTPUT FILE NAMING — NEVER substitute underscores for dots (learned Session 54) !!

When creating a file with create_file, use the exact filename including all dots
(e.g. application.html.erb, not application_html.erb). Browser upload substitution
is an upload-only constraint. Claude controls output filenames entirely.
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

## Session 55 Summary

**Focus: Image captions on home page, barter offers stat, admin owners peripherals column.**

### Files delivered this session (5 files)

    decor/app/views/home/index.html.erb                         v4.7
    decor/app/controllers/home_controller.rb                    v1.3
    decor/app/views/admin/owners/index.html.erb                 v1.3
    decor/docs/claude/COMMON_BEHAVIOR.md                        v2.7
    decor/docs/claude/SESSION_HANDOVER.md                       v59.0

### Changes

**Feature: Image captions on home page (v4.5 → v4.6 → v4.7)**
- Convention: place `N.txt` alongside `N.gif` in `decor/app/assets/images/`.
  The view reads the file at render time; if absent, no caption is shown.
- v4.5: caption rendered below the image inside the grey border box.
  `File.exist?` / `File.read(...).strip` in the ERB ruby block.
  Styled with `text-center text-stone-600`, font-size clamp.
- v4.6: caption width fix. Problem: a long caption expanded the grey border
  box wider than the image. Fix: `display: table` on the border box +
  `display: table-caption; caption-side: bottom` on the `<p>`. CSS table
  captions are constrained to the table's width — long text wraps at the
  image edge with no JavaScript or known-width required.
- v4.7: added `@stat_barter_offers` line to the statistics section (see below).

**Feature: Barter offers stat on home page**
- home_controller.rb v1.3: `@stat_barter_offers` counts
  `Computer.barter_status_offered.count + Component.barter_status_offered.count`.
  Covers hardware, peripherals (both in the computers table), and components.
  `wanted` status is intentionally excluded — "barter offers" = offered only
  (user clarification mid-session).
- home/index.html.erb v4.7: added `- Barter offers: <%= @stat_barter_offers %>`
  as a fourth data line in the Statistics section, below Computer models.

**Feature: Peripherals column in Admin Manage Owners**
- admin/owners/index.html.erb v1.3: added `<th>Peripherals</th>` and
  `<td><%= owner.computers.device_type_peripheral.count %></td>` immediately
  after the Computers column. Uses the `device_type_peripheral` enum scope —
  the exact mirror of `device_type_computer` already used for the Computers column.

**Rule: Output Path Collision (new — COMMON_BEHAVIOR.md v2.7)**
- Real example this session: home/index.html.erb (v4.6) was written to
  `outputs/index.html.erb`; later admin/owners/index.html.erb (v1.3) was
  written to the same path, silently destroying the home view. User had to
  re-upload for the follow-up barter offers edit.
- Fix: use prefixed output filenames when base names collide
  (e.g. `home_index.html.erb`, `admin_owners_index.html.erb`).

**Rule: Token estimation floor raised 40% → 50% (COMMON_BEHAVIOR.md v2.7)**
- User confirmed estimates were consistently too optimistic throughout Session 55.
  Floor raised from 40% to 50% for sessions with 5+ large documents loaded.

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
