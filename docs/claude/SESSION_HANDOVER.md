# decor/docs/claude/SESSION_HANDOVER.md
# version 53.0
# Session 49: Session G — owner-facing data_transfers files + export/import bug fixes
#   + service test rewrites. All Session G scope completed.

**Date:** April 8, 2026
**Branch:** main (Session 48 partial commit pending; Session 49 ready to commit)
**Status:** Session 49 complete. All Session G scope done.

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

Session 49 ended at ~90% of the context window. Start Session H fresh.

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

The `paginate` concern calls `set_page_and_extract_portion_from` which sets `@page`
as a side effect. The return value of `paginate` is the result of `respond_to` — nil.

**Wrong:** `@page = paginate(scope)`  **Correct:** `paginate scope`

---

## !! EXPORT/IMPORT — ALWAYS include a stable unique key (learned Session 49) !!

Every exported record type must carry a stable unique field (or unique combination
of fields) that the importer uses for duplicate detection. Never rely on derived
properties (member sets, content hashes) — they break as soon as data changes.
See PROGRAMMING_GENERAL.md v2.0 for the full rule with example.

---

## Session 49 Summary

**Focus: Session G — owner-facing export/import files + bug fixes + service tests.**

### Files delivered this session (8 files)

    decor/app/controllers/data_transfers_controller.rb           v1.6
    decor/app/views/data_transfers/show.html.erb                 v1.9
    decor/app/services/owner_export_service.rb                   v1.10
    decor/app/services/owner_import_service.rb                   v1.11
    decor/test/services/owner_export_service_test.rb             v2.0
    decor/test/services/owner_import_service_test.rb             v1.7
    decor/docs/claude/PROGRAMMING_GENERAL.md                     v2.0
    decor/app/views/data_transfers/show.html.erb (already above)

### Bug fixes (Session 49)

**1. Owner controller silent drops (data_transfers_controller.rb v1.5 → v1.6):**
   Root cause: v1.5 never read result[:row_errors] from OwnerImportService v1.8.
   result[:success] was true (partial success), so bad rows vanished silently.
   Fix: flash[:row_errors] and flash[:row_warnings] set in import action.
   Affected: unknown run status, unknown model, missing serial → all now surfaced.

**2. Component missing installed_on_model in export (owner_export_service.rb v1.9):**
   Serial numbers are not unique across models for a given owner.
   COMPONENT_SECTION_HEADERS gained installed_on_model (was serial-only).

**3. Component import used serial-only lookup (owner_import_service.rb v1.9):**
   process_component_row now uses model+serial when installed_on_model present,
   falls back to serial-only for legacy CSVs. Mirrors resolve_software_computer.

**4. Connection groups duplicated on re-import (owner_import_service.rb v1.10):**
   First attempt: member-set comparison. Broken: adding a port changes the set.
   Fix (v1.11): export owner_group_id (stable unique key) → direct exists? check.
   CONNECTION_SECTION_HEADERS gained owner_group_id; member rows export blank.

**5. Rule added to PROGRAMMING_GENERAL.md v2.0:**
   "Export/Import — Always Include a Stable Unique Key"

### Key design decisions (Session 49)

**data_transfers_controller.rb v1.6:**
- Added software_item_count (was missing, same gap as admin v1.2 fixed in v1.3).
- Extracted build_success_message private method (mirrors admin v1.3 pattern).
- Partial success phrasing: "Partially imported — saved X. N row(s) skipped."
- "Nothing to import — all records already exist." case preserved.

**show.html.erb v1.9 (owner-facing) — complete rewrite:**
- Import notes: removed atomicity bullet; added per-row independent save note.
- Added flash[:row_warnings] (amber) and flash[:row_errors] (red) display blocks.
- CSV Format section: complete rewrite for v1.7+ per-section format.
  Separate column tables for computers/peripherals, components, connections, software.
  Updated example CSV shows sentinel + section-header + data-row layout.
  Backward-compat notes for legacy format and "appliance" alias retained.

**owner_export_service_test.rb v2.0:**
- Complete rewrite. New sections_from helper parses per-section CSV into hash.
- Tests use new column names (model, serial_number, installed_on_serial, type, etc.).
- Tests added: section headers match service constants, barter_status, installed_on_model
  on components, owner_group_id on connection_group rows.

**owner_import_service_test.rb v1.7:**
- build_csv/build_csv_with_connections/build_csv_with_software rewritten for new format.
- comp()/cmp() short-form row builders added.
- Partial success tests: good rows save when bad row present; row_errors verified.
- Atomicity test removed (old behavior); replaced by partial-success test.
- Row-level failure tests updated: now assert success: true + row_errors (not refute success).
- New tests: barter_status, component_category, installed_on_model lookup, owner_group_id
  duplicate detection, legacy format backward compat.

---

## Priority 1 — Future Sessions

1. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
2. **System tests** — decor/test/system/ still empty.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.

---

## Software Feature — Status

    Session A  Migrations, models, fixtures, model tests              DONE ✓
    Session B  Admin CRUD: SoftwareNames + SoftwareConditions         DONE ✓
    Session C  Owner-facing: Software index + show (read-only)        DONE ✓
    Session D  Owner-facing: Software create + edit + destroy         DONE ✓
    Session E  Computer/peripheral show page integration              DONE ✓
    Session F  Public /software index + nav + export/import           DONE ✓ (Session 48)
    Session G  Owner export/import fixes + service tests              DONE ✓ (Session 49)

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

### OwnersController — access model
All read-only sub-pages (computers, peripherals, components, connections, software)
have NO require_login and NO ownership guard. Publicly accessible.
Only edit / update / destroy are guarded by require_owner.

### Auto-assign rules
- `owner_group_id`: assigned on create as `max(owner.connection_groups.owner_group_id) + 1`
- `owner_member_id`: assigned on create as `max(in-memory siblings, db rows) + 1`
- Guard: `return if field.to_i > 0` — NOT `field.present?` (0.present? is true)

---

**End of SESSION_HANDOVER.md**
# Session 48: Software feature Session F (partial) + Export/Import overhaul.
#   Public /software index page, nav links, export/import redesign (per-section
#   format, partial success). Two files deferred to Session G (see below).

**Date:** April 5, 2026
**Branch:** main (Session 47 merged and deployed; Session 48 ready to commit — partial)
**Status:** Session 48 mostly complete. Two files pending (see Session G scope below).

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

Session 48 ended at ~90% of the context window. Start Session G fresh.

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

The `paginate` concern calls `set_page_and_extract_portion_from` which sets `@page`
as a side effect. The return value of `paginate` is the result of `respond_to` — nil.

**Wrong — overwrites @page with nil:**
```ruby
@page = paginate(scope)
```

**Correct:**
```ruby
paginate scope
```

See computers_controller.rb for the established pattern.

---

## Session 48 Summary

**Focus: Software feature Session F + Export/Import overhaul.**

### Files delivered this session (10 files)

    decor/app/controllers/software_items_controller.rb            v1.2
    decor/app/views/software_items/index.html.erb                 v1.0  NEW
    decor/app/views/software_items/index.turbo_stream.erb         v1.0  NEW
    decor/app/views/software_items/_software_item.html.erb        v1.0  NEW
    decor/app/views/common/_navigation.html.erb                   v2.1
    decor/test/controllers/software_items_controller_test.rb      v1.2
    decor/app/services/owner_export_service.rb                    v1.8
    decor/app/services/owner_import_service.rb                    v1.8
    decor/app/controllers/admin/data_transfers_controller.rb      v1.3
    decor/app/views/admin/data_transfers/show.html.erb            v1.3

### Key design decisions (Session 48)

**Public software index:**
- `paginate scope` — no assignment; @page set as side effect by the concern.
  The `@page = paginate(scope)` bug was caught and fixed in the same session.
- Ordered by `software_names.name ASC, owners.user_name ASC` — multi-table,
  requires `Arel.sql()` and `eager_load` (not `includes`).
- Nav: "Software" link added to public bar; "My Software" added to owner dropdown.

**Export format (v1.8) — per-section column headers:**
- Global CSV_HEADERS row removed entirely.
- Each section starts with `! --- section-name ---` sentinel followed by a
  column-declaration row specific to that section. Variable column counts.
- New sentinels for computers and peripherals (were implicit before).
- Previously missing columns added: `barter_status` on computers/peripherals;
  `barter_status` + `category` (component_category) on components.

**Import (v1.8) — partial success:**
- Removed the single `ActiveRecord::Base.transaction` wrapper.
- Each row saves independently. Failed rows → `@row_errors` (row skipped).
  Non-fatal issues (computer not found → software saved as unattached) →
  `@row_warnings` (row saved with caveat).
- `@errors` reserved for file-level failures that abort the whole import.
- Result: `{ success:, counts..., row_errors: [], row_warnings: [] }`.
- `success: false` only for file-level failures.
- Both old (global header, 12–18 cols) and new (per-section) formats supported
  via `new_format?` detection and two separate parse paths.
- `col(row, *keys)` helper: tries new-format column name first, falls back to
  legacy name — lets all process_* methods handle both formats without branching.

**Admin controller / view:**
- `connection_group_count` and `software_item_count` now included in success message
  (were silently omitted in v1.2).
- `flash[:row_errors]` and `flash[:row_warnings]` set when partial success.
- Admin show view displays these in amber (warnings) and red (errors) blocks.
- "Atomically" bullet removed from import notes.

---

## Session G — Scope (2 pending files from Session 48)

### Files needed before starting Session G:

    decor/app/controllers/data_transfers_controller.rb     (v1.5 — owner-facing)
    decor/app/views/data_transfers/show.html.erb           (v1.8 — owner-facing)

### What needs to change:

1. **`data_transfers_controller.rb` (owner-facing)** — update `import` action to:
   - Set `flash[:row_errors] = result[:row_errors]` when present.
   - Set `flash[:row_warnings] = result[:row_warnings]` when present.
   - Update `build_success_message` (or equivalent) to cover:
     - connection_group_count, software_item_count (likely missing as in admin v1.2)
     - Partial success phrasing (same logic as admin v1.3)
     - "Nothing to import — all records already exist." case
   - Remove any "atomically" language.

2. **`data_transfers/show.html.erb` (owner-facing)** — complete rewrite of:
   - Import notes: remove atomicity bullet; add per-row independent save note.
   - Add `flash[:row_warnings]` display block (amber).
   - Add `flash[:row_errors]` display block (red).
   - CSV Format section: rewrite entirely for v1.7+ per-section format.
     Replace the old fixed 12-column table with per-section column tables:
       computers / peripherals: record_type, model, order_number, serial_number,
         condition, run_status, history, barter_status
       components: record_type, installed_on_serial, type, category, order_number,
         serial_number, condition, description, barter_status
       connections: record_type, connection_type_or_model, label, serial_number
       software: record_type, installed_on_model, installed_on_serial, name,
         version, condition, description, history, barter_status
     Update example CSV to show the sentinel + section-header + data-row format.
     Keep the "appliance" backward-compat note (importer still accepts it).

### Also pending from Session 48:

3. **Export/import service tests** — both test files need updates:
   - `owner_export_service_test.rb` — update for new per-section format (no global
     header row; assert sentinels and section-specific headers).
   - `owner_import_service_test.rb` — add tests for:
     - New format parsing (sentinel-based sections)
     - Partial success (some rows fail, others save)
     - row_errors / row_warnings returned correctly
     - barter_status imported correctly for computers, peripherals, components
     - component_category imported correctly

---

## Priority 1 — Future Sessions

1. **Session G** — 2 pending files + 2 test files (see above).
2. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
3. **System tests** — decor/test/system/ still empty.
4. **Account deletion + data export** (GDPR).
5. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
6. **BulkUploadService stale model references** — low priority.

---

## Software Feature — Status

    Session A  Migrations, models, fixtures, model tests              DONE ✓
    Session B  Admin CRUD: SoftwareNames + SoftwareConditions         DONE ✓
    Session C  Owner-facing: Software index + show (read-only)        DONE ✓
    Session D  Owner-facing: Software create + edit + destroy         DONE ✓
    Session E  Computer/peripheral show page integration              DONE ✓
    Session F  Public /software index + nav + export/import           DONE ✓ (Session 48)
               (2 owner-facing files + service tests deferred to G)

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

### OwnersController — access model
All read-only sub-pages (computers, peripherals, components, connections, software)
have NO require_login and NO ownership guard. Publicly accessible.
Only edit / update / destroy are guarded by require_owner.

### Auto-assign rules
- `owner_group_id`: assigned on create as `max(owner.connection_groups.owner_group_id) + 1`
- `owner_member_id`: assigned on create as `max(in-memory siblings, db rows) + 1`
- Guard: `return if field.to_i > 0` — NOT `field.present?` (0.present? is true)

---

**End of SESSION_HANDOVER.md**
