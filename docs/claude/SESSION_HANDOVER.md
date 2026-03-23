# decor/docs/claude/SESSION_HANDOVER.md
# version 40.0

**Date:** March 19, 2026
**Branch:** main (Sessions 1–36 committed and deployed)
**Status:** Part 4 fully committed and deployed. Connections feature complete.
Next: Priority 2 items (see below).

---

## !! RELIABILITY NOTICE — READ FIRST !!

The `decor-session-rules` skill (v1.2) is installed. Its description contains
the first mandatory action — read it from the available_skills context before
doing anything else.

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

**NOTE:** bash cat applies to skill files too — use cat, not view:
```bash
cat /mnt/skills/user/decor-session-rules/SKILL.md
```

---

## !! SEPARATOR / TOKEN ESTIMATE FORMAT !!

Every response must follow this format:

```
================================================================================
(blank line)
**Token Usage...**
```

The OPENING separator is also mandatory — not just the closing one.

---

## !! TOKEN BUDGET WARNING !!

Sessions 28–36 hit ~53–89% context usage. The fixed overhead (5 rule documents +
system prompt + tool schemas + bash cat outputs + uploaded source files) consumes
~60–90% of the window before any work output is written.

**Practical consequence:** each session has room for roughly one focused task.
Do not plan multi-task sessions.

---

## !! FIXTURE DELIVERY RULE !!

Whenever a fixture file is modified in a session, upload it to verify the change
is actually present before closing the session. A summary entry is NOT confirmation
of delivery. (Established Session 27.)

---

## Session 36 Summary

**Focus: Connections feature — Part 4 — Owner ConnectionGroup CRUD + post-deploy fixes + rule updates**

### Changes

**Updated files (post-deploy fixes, committed separately):**

    decor/app/views/computers/show.html.erb                                 v2.0
    decor/app/views/connection_groups/index.html.erb                        v1.1
    decor/app/views/connection_groups/_form.html.erb                        v1.1

**Main Part 4 files (committed and deployed):**

    decor/config/routes.rb                                                  v2.4
    decor/app/models/connection_group.rb                                    v1.1
    decor/app/views/common/_navigation.html.erb                             v1.8
    decor/app/controllers/connection_groups_controller.rb                   v1.0  new
    decor/app/views/connection_groups/index.html.erb                        v1.0  new
    decor/app/views/connection_groups/new.html.erb                          v1.0  new
    decor/app/views/connection_groups/edit.html.erb                         v1.0  new
    decor/app/views/connection_groups/_form.html.erb                        v1.0  new
    decor/app/javascript/controllers/connection_members_controller.js       v1.0  new
    decor/test/controllers/connection_groups_controller_test.rb             v1.0  new

**Rule documents updated (placed in decor/docs/claude/, no commit needed):**

    decor/docs/claude/COMMON_BEHAVIOR.md                                    v2.5
    decor/docs/claude/RAILS_SPECIFICS.md                                    v2.3

### What was done

**routes.rb v2.4:**
- Added `resources :connection_groups, only: %i[index new create edit update destroy]`
  nested under `resources :owners`. No :show action (index suffices).

**connection_group.rb v1.1:**
- Added `reject_if: :all_blank` to `accepts_nested_attributes_for`.
- Without it, blank dropdown rows fail `belongs_to :computer` presence before the
  group-level `minimum_two_members` validator runs, producing a confusing error.

**connection_groups_controller.rb v1.0:**
- Full CRUD. `require_login` + `set_owner` (redirects to root if owner != Current.owner).
- `set_connection_group` scoped to `@owner.connection_groups` — prevents cross-owner access.
- `load_form_data`: `@connection_types` by name; `@computers` scoped to owner, ordered
  via `Arel.sql("computer_models.name ASC, computers.serial_number ASC")`.
- `new` pre-builds 2 blank member rows; `edit` pre-builds 1.

**Views:**
- index: table with Type, Label, Members (clickable links via `safe_join`), Edit/Delete.
- _form: connection_type select, label field, nested member dropdowns with Stimulus
  `connection-members` controller for add/remove. `<template>` rendered server-side.
  Dropdown label: `Model - SN serial (device_type)`. Blank option: "select a computer/peripheral/appliance".

**connection_members_controller.js v1.0:**
- Stimulus: `add` clones template (NEW_INDEX -> Date.now()); `remove` sets `_destroy: "1"`
  for persisted rows, removes DOM node for new rows.

**_navigation.html.erb v1.8:**
- Added "My Connections" -> `owner_connection_groups_path(Current.owner)` in owner dropdown.

**Post-deploy fixes:**
- `show.html.erb` v2.0: Connections Type column uses `connection_type.name` only —
  previously incorrectly used `label.presence || name`.
- `index.html.erb` v1.1: member names are clickable links; separator changed from `·` to `–`.
- `_form.html.erb` v1.1: separator `·` -> `–`; blank option updated to
  "select a computer/peripheral/appliance".

**Rule document updates:**
- COMMON_BEHAVIOR.md v2.5: bash cat rule extended to skill files; Session 36 real example added.
- RAILS_SPECIFICS.md v2.3: new section "Nested Attributes — Always Use reject_if: :all_blank".

### Part 4 status
All tests pass. Rubocop clean. Brakeman clean. Committed and deployed.
Connections feature complete (all 4 parts done).

---

## Complete File List (Sessions 31–36)

    decor/db/migrate/20260319000000_create_connection_types.rb              v1.0  ✓ merged
    decor/db/migrate/20260319010000_create_connection_groups.rb             v1.0  ✓ merged
    decor/db/migrate/20260319020000_create_connection_members.rb            v1.0  ✓ merged
    decor/app/models/connection_type.rb                                     v1.0  ✓ merged
    decor/app/models/connection_group.rb                                    v1.1  ✓ merged (Session 36)
    decor/app/models/connection_member.rb                                   v1.0  ✓ merged
    decor/app/models/computer.rb                                            v1.9  ✓ merged
    decor/app/models/owner.rb                                               v1.4  ✓ merged
    decor/test/fixtures/connection_types.yml                                v1.0  ✓ merged
    decor/test/fixtures/connection_groups.yml                               v1.0  ✓ merged
    decor/test/fixtures/connection_members.yml                              v1.0  ✓ merged
    decor/test/models/connection_type_test.rb                               v1.0  ✓ merged
    decor/test/models/connection_group_test.rb                              v1.1  ✓ merged
    decor/test/models/connection_member_test.rb                             v1.0  ✓ merged
    decor/app/controllers/admin/connection_types_controller.rb              v1.0  ✓ merged
    decor/app/views/admin/connection_types/index.html.erb                   v1.0  ✓ merged
    decor/app/views/admin/connection_types/_form.html.erb                   v1.0  ✓ merged
    decor/app/views/admin/connection_types/new.html.erb                     v1.0  ✓ merged
    decor/app/views/admin/connection_types/edit.html.erb                    v1.0  ✓ merged
    decor/config/routes.rb                                                  v2.4  ✓ merged (Session 36)
    decor/app/views/layouts/admin.html.erb                                  v1.9  ✓ merged
    decor/test/controllers/admin/connection_types_controller_test.rb        v1.0  ✓ merged
    decor/test/controllers/computers_controller_test.rb                     v1.7  ✓ merged (Session 35)
    decor/app/views/computers/show.html.erb                                 v2.0  ✓ merged (Session 36)
    decor/app/controllers/computers_controller.rb                           v1.17 ✓ merged (Session 34)
    decor/app/controllers/connection_groups_controller.rb                   v1.0  ✓ merged (Session 36)
    decor/app/views/connection_groups/index.html.erb                        v1.1  ✓ merged (Session 36)
    decor/app/views/connection_groups/new.html.erb                          v1.0  ✓ merged (Session 36)
    decor/app/views/connection_groups/edit.html.erb                         v1.0  ✓ merged (Session 36)
    decor/app/views/connection_groups/_form.html.erb                        v1.1  ✓ merged (Session 36)
    decor/app/javascript/controllers/connection_members_controller.js       v1.0  ✓ merged (Session 36)
    decor/app/views/common/_navigation.html.erb                             v1.8  ✓ merged (Session 36)
    decor/test/controllers/connection_groups_controller_test.rb             v1.0  ✓ merged (Session 36)

---

## Priority 1 — Next Session

Connections feature is complete. Pick from Priority 2:

1. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
2. **System tests** — decor/test/system/ still empty.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.

---

## Connections Feature — Design Reference (Session 31, unchanged)

### Tables

```
connection_types
  id                  integer  PK
  name                VARCHAR(40) NOT NULL, UNIQUE
  label               VARCHAR(100) nullable
  created_at / updated_at

connection_groups
  id                  integer  PK
  owner_id            integer  FK → owners.id, NOT NULL
  connection_type_id  integer  FK → connection_types.id, nullable
  label               VARCHAR(100) nullable
  created_at / updated_at

connection_members
  id                   integer  PK
  connection_group_id  integer  FK → connection_groups.id, NOT NULL
                                on_delete: :cascade (DB level)
  computer_id          integer  FK → computers.id, NOT NULL
                                no on_delete (Ruby callbacks must fire)
  created_at / updated_at
  UNIQUE INDEX (connection_group_id, computer_id)
```

### Cascade chain on Computer deletion
```
owner.destroy
  → computers.destroy_each          (has_many :computers, dependent: :destroy)
      → computer.destroy
          → connection_members.destroy_each  (has_many :connection_members, dependent: :destroy)
              → member.after_destroy: group.destroy if group.connection_members.count < 2
                  → connection_members.delete_all  (has_many :connection_members, dependent: :delete_all)
  → connection_groups.destroy_each  (cleans up any groups not already destroyed above)
```

### Model associations
```ruby
# ConnectionType
has_many :connection_groups, dependent: :restrict_with_error

# ConnectionGroup
belongs_to :owner
belongs_to :connection_type, optional: true
has_many :connection_members, dependent: :delete_all
has_many :computers, through: :connection_members
accepts_nested_attributes_for :connection_members, allow_destroy: true, reject_if: :all_blank
validate :minimum_two_members
validate :all_members_belong_to_owner

# ConnectionMember
belongs_to :connection_group
belongs_to :computer
validates :computer_id, uniqueness: { scope: :connection_group_id }
after_destroy :cleanup_undersized_group

# Computer (v1.9)
has_many :connection_members, dependent: :destroy
has_many :connection_groups, through: :connection_members

# Owner (v1.4) — order of has_many declarations matters
has_many :computers, dependent: :destroy      # FIRST
has_many :components, dependent: :destroy
has_many :connection_groups, dependent: :destroy  # AFTER computers
```

---

## Unique Constraint Design Reference (Session 28, unchanged)

### computers table
Index: `index_computers_on_owner_model_and_serial_number`
Columns: `(owner_id, computer_model_id, serial_number)`
Migration: `20260316120000_add_unique_index_to_computers_serial_number.rb`
Model validation: `validates :serial_number, uniqueness: { scope: [:owner_id, :computer_model_id] }`

### components table
Index: `index_components_on_owner_type_and_serial_number`
Columns: `(owner_id, component_type_id, serial_number)`
Migration: `20260316110000_add_unique_index_to_components_serial_number.rb`
Model validation: `validates :serial_number, uniqueness: { scope: [:owner_id, :component_type_id] }, allow_blank: true`

---

## Peripherals Feature — Design Reference (Session 25, unchanged)

### device_type enum (both Computer and ComputerModel)
```ruby
enum :device_type, { computer: 0, appliance: 1, peripheral: 2 }, prefix: true
```

---

## Barter Feature — Design Reference (Sessions 21–22, unchanged)

### Enum definition
```ruby
enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true
```

### Colour coding
- offered   -> <span class="text-green-700">Offered</span>
- wanted    -> <span class="text-amber-600">Wanted</span>
- no_barter -> <span class="text-stone-400">--</span>

---

**End of SESSION_HANDOVER.md**
