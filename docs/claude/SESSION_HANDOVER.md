# decor/docs/claude/SESSION_HANDOVER.md
# version 44.0
# Session 40: Planning session only — no code written.
#   Merger plan: appliances (old) + peripherals (old) → peripherals (new).
#   Plan recorded in SESSION_HANDOVER.md and DECOR_PROJECT.md.
#   Token budget exhausted at 90% after document load + planning response.

**Date:** March 24, 2026
**Branch:** main (Sessions 38+39 merged and deployed)
**Status:** Session 40 complete (planning only). No code changes. All tests still green.

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

Sessions 28–40 hit ~40–90% context usage. Session 40 hit 90% after document
load + one planning response. Fixed overhead alone (~60–90%) leaves room for
roughly one focused task per session. Start sessions with the smallest possible
document load when planning sessions are not needed.

---

## !! FIXTURE DELIVERY RULE !!

Whenever a fixture file is modified, upload it to verify before closing the session.

---

## !! NEVER GUESS RULE (added Session 39) !!

Before writing any code or test that depends on a value, path, method name,
or behaviour in the codebase: READ THE FILE. Never infer from handover summaries
or memory. See decor-session-rules skill v1.3 for the full rule and real example.

---

## Session 40 Summary

**Focus: Planning only — Appliances → Peripherals merger plan.**

No code was written or committed this session. The merger plan was documented
in SESSION_HANDOVER.md and DECOR_PROJECT.md.

### Files changed this session

    decor/docs/claude/SESSION_HANDOVER.md     v44.0
    decor/docs/claude/DECOR_PROJECT.md        v2.35

---

## Priority 1 — Appliances → Peripherals Merger (Sessions 41–44)

### Background

`appliance` (device_type=1) and `peripheral` (device_type=2) are being merged.
Peripherals (new) absorbs all appliances (old). The DB data migration is handled
by the user manually BEFORE Session 41 starts:

```sql
UPDATE computers SET device_type = 2 WHERE device_type = 1;
```

Verify this has been run in production before starting Phase 1.

### Phase 1 — Enum + fixtures + model tests (Session 41)

**Goal:** Remove `appliance` from the enum; update all fixtures and model tests.
Leave test suite green and commit.

- Run grep sweep at session start — read the actual files, do not rely on this summary:
  ```bash
  grep -rn "appliance" decor/app/ decor/test/ decor/config/
  ```
- Update `decor/app/models/computer.rb`:
  Change enum to hash form `{ computer: 0, peripheral: 2 }` (non-contiguous is valid Rails)
- Update `decor/test/fixtures/computers.yml`:
  Convert all `device_type: appliance` entries to `device_type: peripheral`
  Known case: `dec_unibus_router` (charlie's fixture, Session 13)
- Update `decor/test/models/computer_test.rb`:
  Remove or replace all `device_type_appliance?` predicate tests
- Prerequisite: confirm DB UPDATE has been run before this session

### Phase 2 — Routes + controllers + controller tests (Session 42)

**Goal:** Remove the `appliances` route and action; update ComputersController
filter logic; update controller tests. Leave test suite green and commit.

- Update `decor/config/routes.rb`: remove `appliances` member route
- Update `decor/app/controllers/owners_controller.rb`:
  Remove `appliances` action; update `peripherals` action to cover all device_type_peripheral?
  (former appliances are already peripheral in the DB after the data migration)
- Update `decor/app/controllers/computers_controller.rb`:
  Remove appliance from sort/filter logic
- Update `decor/test/controllers/owners_controller_test.rb`:
  Remove appliance action tests
- Update `decor/test/controllers/computers_controller_test.rb` if appliance tests exist

### Phase 3 — Views + navigation (Session 43)

**Goal:** Remove all user-facing references to "Appliance". Leave test suite green and commit.

- Delete `decor/app/views/owners/appliances.html.erb`
- Update `decor/app/views/owners/peripherals.html.erb`:
  Verify no "Appliance" label remains; it now covers the unified device type
- Update `decor/app/views/owners/show.html.erb`:
  Remove the Appliances section from the owner summary
- Update `decor/app/views/computers/show.html.erb`:
  Change device_type label display: "Appliance" → "Peripheral"
- Update `decor/app/views/owners/computers.html.erb` if device_type labels appear
- Update `decor/app/views/common/_navigation.html.erb`:
  Remove the Appliances navigation entry
- Spot-check `decor/app/views/connection_groups/_form.html.erb` and connections views

### Phase 4 — Services + service tests + documentation cleanup (Session 44)

**Goal:** Update import/export services; add backward-compat import alias;
update docs. Leave test suite green, deploy.

- Update `decor/app/services/owner_export_service.rb`:
  Write `peripheral` (never `appliance`) for device_type=2
- Update `decor/app/services/owner_import_service.rb`:
  Add legacy alias: CSV value `appliance` → mapped to `peripheral` on import
  (supports CSVs exported before the merger)
- Update `decor/test/services/owner_export_service_test.rb`:
  Change device_type values from appliance to peripheral
- Update `decor/test/services/owner_import_service_test.rb`:
  Add backward-compat test: import a CSV containing `appliance` → verify stored as `peripheral`
- Update `RAILS_SPECIFICS.md`: fix enum assertion example (remove "appliance" references)
- Update DECOR_PROJECT.md and produce new SESSION_HANDOVER.md
- Deploy

### Important: Read Files Before Writing (Never Guess rule)

Before writing any file in any phase, read the actual file from the project.
Do NOT rely on the phase descriptions above as a substitute for reading the real code.
The descriptions are a planning guide, not a specification.

---

## Priority 2 — Future Sessions (post-merger)

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
  UNIQUE INDEX (connection_group_id, computer_id)      ← preserved from Session 31
  UNIQUE INDEX (connection_group_id, owner_member_id)  ← new Session 38
```

### Connections sub-page URL
`/owners/:id/connections` → `connections_owner_path(@owner)`
Route: `get :connections` in owners member block (routes.rb).
The old `/owners/:id/connection_groups` 301-redirects to the new URL.

### OwnersController — access model
All read-only sub-pages (computers, peripherals, components, connections)
have NO require_login and NO ownership guard. They are publicly accessible.
Only edit / update / destroy are guarded by require_owner.

### Auto-assign rules
- `owner_group_id`: assigned on create as `max(owner.connection_groups.owner_group_id) + 1`
- `owner_member_id`: assigned on create as `max(in-memory siblings, db rows) + 1`
- Guard: `return if field.to_i > 0` — NOT `field.present?` (0.present? is true)

---

**End of SESSION_HANDOVER.md**
