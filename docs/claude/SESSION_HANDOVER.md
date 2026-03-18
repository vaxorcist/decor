# decor/docs/claude/SESSION_HANDOVER.md
# version 34.0

**Date:** March 18, 2026
**Branch:** main (Sessions 1–30 committed and deployed; Sessions 31 Part 1 + 32 Part 1b ready to branch/PR/deploy)
**Status:** Tests written and delivered. Run `bin/rails db:migrate` then `bin/rails test` before committing.

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

All three model test files written and delivered. Fixtures from Session 31 provided
sufficient data for all tests with no fixture additions required.

### Changes

**3 new test files:**

    decor/test/models/connection_type_test.rb    v1.0
    decor/test/models/connection_group_test.rb   v1.0
    decor/test/models/connection_member_test.rb  v1.0

**2 updated docs:**

    decor/docs/claude/DECOR_PROJECT.md           v2.26
    decor/docs/claude/SESSION_HANDOVER.md        v34.0

### Test coverage

connection_type_test.rb (8 tests):
  - valid with name + label; valid with name only; invalid without name
  - invalid with duplicate name; valid with unique name
  - has_many :connection_groups responds
  - restrict_with_error: destroy blocked when groups exist (rs232)
  - destroy succeeds when no groups (ethernet)

connection_group_test.rb (11 tests):
  - minimum_two_members: valid at 2, invalid at 0 and 1 (boundary tests)
  - all_members_belong_to_owner: invalid when member from different owner
  - connection_type optional: valid without, valid with
  - belongs_to owner; belongs_to connection_type (with instance check)
  - has_many connection_members; has_many computers through members
  - cascade: destroy group → members deleted (delete_all)
  - cascade: computers NOT destroyed when group is destroyed

connection_member_test.rb (7 tests):
  - belongs_to connection_group; belongs_to computer
  - invalid: same computer in same group twice (uniqueness error on :computer_id)
  - valid: same computer in different group (scoped uniqueness)
  - after_destroy (2→1): group auto-destroys when count drops below 2
  - after_destroy (2→1 alt): same via alice's group
  - after_destroy (3→2): group survives when count stays at 2

### Key notes for test run

- `bin/rails db:migrate` must run first (Session 31 migrations not yet applied to test DB)
- ConnectionGroup.create! in connection_member_test uses
  `connection_members: [ConnectionMember.new(...)]` — accepted by accepts_nested_attributes_for
- All error key assertions use `:base` for group-level custom validations
  (minimum_two_members, all_members_belong_to_owner) — if models use a different
  key, tests will tell you immediately

---

## Commit Session 31 Part 1 + Session 32 Part 1b (together)

```bash
git switch main
git pull origin main
git switch -c feature/connections-part1
# Place all 16 files (see complete file list below)
bin/rails db:migrate
bin/rails test
bundle exec rubocop -A && bundle exec rubocop
bin/brakeman --no-pager
git add -A
git commit -m "Sessions 31-32: Add connections foundation + model tests (Part 1a + 1b)"
git push origin feature/connections-part1
gh pr create --fill
gh pr checks feature/connections-part1 --watch
# Once green:
gh pr merge --merge --delete-branch feature/connections-part1
git switch main
git pull origin main
kamal deploy
```

---

## Complete File List (Sessions 31 + 32)

    decor/db/migrate/20260319000000_create_connection_types.rb              v1.0
    decor/db/migrate/20260319010000_create_connection_groups.rb             v1.0
    decor/db/migrate/20260319020000_create_connection_members.rb            v1.0
    decor/app/models/connection_type.rb                                     v1.0
    decor/app/models/connection_group.rb                                    v1.0
    decor/app/models/connection_member.rb                                   v1.0
    decor/app/models/computer.rb                                            v1.9
    decor/app/models/owner.rb                                               v1.4
    decor/test/fixtures/connection_types.yml                                v1.0
    decor/test/fixtures/connection_groups.yml                               v1.0
    decor/test/fixtures/connection_members.yml                              v1.0
    decor/test/models/connection_type_test.rb                               v1.0
    decor/test/models/connection_group_test.rb                              v1.0
    decor/test/models/connection_member_test.rb                             v1.0
    decor/docs/claude/SESSION_HANDOVER.md                                   v34.0
    decor/docs/claude/DECOR_PROJECT.md                                      v2.26

---

## Priority 1 — Next Session: Part 2 — Admin ConnectionTypes CRUD

    decor/app/controllers/admin/connection_types_controller.rb  — new
    decor/app/views/admin/connection_types/                     — new (index, new, edit, _form)
    decor/config/routes.rb                                      — add resource
    decor/app/views/layouts/admin.html.erb                      — add to dropdown nav

Upload at session start (in addition to 5 rule docs):
    decor/config/routes.rb
    decor/app/views/layouts/admin.html.erb
    decor/app/controllers/admin/base_controller.rb
    decor/app/controllers/admin/component_types_controller.rb  (pattern reference)
    decor/app/views/admin/component_types/index.html.erb       (pattern reference)

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
