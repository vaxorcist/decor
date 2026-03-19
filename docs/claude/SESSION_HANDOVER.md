# decor/docs/claude/SESSION_HANDOVER.md
# version 35.0

**Date:** March 18, 2026
**Branch:** main (Sessions 1–32 committed and deployed)
**Status:** Part 1 (foundation) + Part 1b (model tests) complete. Next: Part 2 — Admin ConnectionTypes CRUD.

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

Sessions 28–32 hit ~88–90% context usage. The fixed overhead (5 rule documents +
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

## Session 32 Summary

**Focus: Connections feature — Part 1b: Model tests**

All three model test files written, patched, and committed. 532 tests, 0 failures.

### Changes

**3 new / 1 patched test files:**

    decor/test/models/connection_type_test.rb    v1.0  — new
    decor/test/models/connection_group_test.rb   v1.1  — new, then patched same session
    decor/test/models/connection_member_test.rb  v1.0  — new

**2 updated docs:**

    decor/docs/claude/DECOR_PROJECT.md           v2.27
    decor/docs/claude/SESSION_HANDOVER.md        v35.0

### Patch note — connection_group_test.rb v1.0 → v1.1

The `minimum_two_members` validation adds its error on `:connection_members`
(not `:base` as initially assumed). Two assertion lines updated:
  errors[:base].any? → errors[:connection_members].any?
`all_members_belong_to_owner` correctly uses `:base` — that assertion unchanged.

---

## Complete File List (Sessions 31 + 32)

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

---

## Priority 1 — Next Session: Part 2 — Admin ConnectionTypes CRUD

    decor/app/controllers/admin/connection_types_controller.rb  — new
    decor/app/views/admin/connection_types/                     — new (index, new, edit, _form)
    decor/config/routes.rb                                      — add :connection_types resource
    decor/app/views/layouts/admin.html.erb                      — add to admin dropdown nav
    decor/test/controllers/admin/connection_types_controller_test.rb — new

Upload at session start (in addition to 5 rule docs):
    decor/config/routes.rb
    decor/app/views/layouts/admin.html.erb
    decor/app/controllers/admin/base_controller.rb
    decor/app/controllers/admin/component_types_controller.rb  (pattern reference)
    decor/app/views/admin/component_types/index.html.erb       (pattern reference)
    decor/test/controllers/admin/component_types_controller_test.rb  (test pattern reference)

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
- Part 2:  Admin ConnectionTypes CRUD             ← NEXT SESSION
- Part 3:  Owner device show pages — read-only connections display
- Part 4:  Owner ConnectionGroup CRUD

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

### Routes (routes.rb v2.2)
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
