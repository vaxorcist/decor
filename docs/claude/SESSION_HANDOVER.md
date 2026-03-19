# decor/docs/claude/SESSION_HANDOVER.md
# version 37.0

**Date:** March 19, 2026
**Branch:** main (Sessions 1–33 committed and deployed)
**Status:** Part 3 (Owner device show pages — read-only connections display) complete.
Next: commit/deploy Part 3, then Part 4 — Owner ConnectionGroup CRUD.

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

---

## !! SEPARATOR / TOKEN ESTIMATE FORMAT !!

Every response must follow this format:

```
================================================================================
(blank line)
**Token Usage...**
```

The OPENING separator is also mandatory — not just the closing one.
Real violation: Session 31 — the file-placement response had the closing separator
but was missing the opening one. Both are required on every response.

---

## !! TOKEN BUDGET WARNING !!

Sessions 28–34 hit ~53–120% context usage. The fixed overhead (5 rule documents +
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

## Session 34 Summary

**Focus: Connections feature — Part 3: Owner device show pages (read-only connections display)**

Two files changed. No migrations, no new routes. Tests deferred to next session.

### Changes

**2 updated files:**

    decor/app/controllers/computers_controller.rb    v1.16 → v1.17
    decor/app/views/computers/show.html.erb          v1.7  → v1.8

### What was done

**computers_controller.rb v1.17:**
- `show` action now loads `@connection_groups` in addition to `@components`.
- Eager-loads `:connection_type` and `computers: :computer_model` to avoid N+1.
- Ordered by `:id` for stable display.

**show.html.erb v1.8:**
- Added "Connections (N)" section between Components and the Back button.
- Table with three columns: Type | Label | Connected to.
- Type: `connection_type.label` → `.name` → "—" if no type set.
- Label: `group.label` → "—".
- Connected to: peer computers (all except current device) as links to their
  show pages, using the preloaded computers cache via `reject` (no N+1).
- Empty state: "No connections recorded for this computer/appliance/peripheral."
- Read-only only — no Edit/Delete buttons (those belong to Part 4, by design).

### Tests deferred

`ComputersController#show` connections rendering is not yet tested. Needs:
    decor/test/controllers/computers_controller_test.rb   (upload at session start)

Tests to write at that session:
  - Computer with connections → groups and peer names appear in response body
  - Computer without connections → "No connections recorded" empty state

---

## Complete File List (Sessions 31–34)

    decor/db/migrate/20260319000000_create_connection_types.rb              v1.0  ✓ merged
    decor/db/migrate/20260319010000_create_connection_groups.rb             v1.0  ✓ merged
    decor/db/migrate/20260319020000_create_connection_members.rb            v1.0  ✓ merged
    decor/app/models/connection_type.rb                                     v1.0  ✓ merged
    decor/app/models/connection_group.rb                                    v1.0  ✓ merged
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
    decor/config/routes.rb                                                  v2.3  ✓ merged
    decor/app/views/layouts/admin.html.erb                                  v1.9  ✓ merged
    decor/test/controllers/admin/connection_types_controller_test.rb        v1.0  ✓ merged
    decor/app/controllers/computers_controller.rb                           v1.17 ← Session 34 (not yet committed)
    decor/app/views/computers/show.html.erb                                 v1.8  ← Session 34 (not yet committed)

---

## Priority 1 — Next Session: Commit Part 3 + Part 3 tests + start Part 4

### Step A — tests first (before committing Part 3)
Upload at session start:
    decor/test/controllers/computers_controller_test.rb

Write tests:
  - show: computer with connections → groups in response body
  - show: computer without connections → "No connections recorded" empty state

### Step B — commit Part 3
Once tests pass: branch, commit, deploy as usual.

### Step C — Part 4: Owner ConnectionGroup CRUD
Full CRUD for owners to create/edit/delete their own connection groups.
Design questions to settle at session start:
  - Route: nested under owners? or top-level /connection_groups?
  - Form: nested attributes for members (add/remove computers in one form)?
  - Member selection: how does the owner pick which computers to connect?

Upload at session start (for Part 4):
    decor/config/routes.rb
    decor/app/views/layouts/application.html.erb  (or nav partial — for any nav changes)
    decor/test/fixtures/owners.yml
    decor/test/fixtures/computers.yml             (already known; re-upload for freshness)

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
accepts_nested_attributes_for :connection_members, allow_destroy: true
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

### Planned parts
- Part 1a: Migrations + models + fixtures         ← DONE (Session 31)
- Part 1b: Model tests                            ← DONE (Session 32)
- Part 2:  Admin ConnectionTypes CRUD             ← DONE (Session 33)
- Part 3:  Owner device show pages — read-only connections display  ← DONE (Session 34)
- Part 4:  Owner ConnectionGroup CRUD             ← NEXT

---

## Priority 2 — After Connections Feature Complete

1. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
2. **System tests** — decor/test/system/ still empty.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.

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

### Routes (routes.rb v2.3)
```ruby
resources :peripherals, controller: "computers", only: [:index],
                        defaults: { device_context: "peripheral" }
resources :owners do
  member do
    get :peripherals
  end
end
namespace :admin do
  resources :peripheral_models, only: %i[index new create edit update destroy],
                                controller: "computer_models",
                                defaults: { device_context: "peripheral" }
end
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
