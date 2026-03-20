# decor/docs/claude/SESSION_HANDOVER.md
# version 39.0

**Date:** March 19, 2026
**Branch:** main (Sessions 1–35 committed and deployed)
**Status:** Part 4 files produced in Session 36. Pending: bin/rails test, rubocop, brakeman, commit, deploy.
Next: run tests, fix any failures, then commit Part 4.

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

## !! SKILL READ VIOLATION — Session 36 !!

At session start, the `decor-session-rules` skill was read using the `view` tool
instead of `bash cat`. The `view` tool is explicitly prohibited for rule documents
(silent truncation risk). The correct tool is always `bash cat` — for all files,
including skill files read at session start.

---

## Session 36 Summary

**Focus: Connections feature — Part 4 — Owner ConnectionGroup CRUD**

12 files produced. No migrations. No fixture changes.

### Changes

**2 updated files:**

    decor/config/routes.rb                                        v2.3 → v2.4
    decor/app/models/connection_group.rb                          v1.0 → v1.1
    decor/app/views/common/_navigation.html.erb                   v1.7 → v1.8

**9 new files:**

    decor/app/controllers/connection_groups_controller.rb         v1.0
    decor/app/views/connection_groups/index.html.erb              v1.0
    decor/app/views/connection_groups/new.html.erb                v1.0
    decor/app/views/connection_groups/edit.html.erb               v1.0
    decor/app/views/connection_groups/_form.html.erb              v1.0
    decor/app/javascript/controllers/connection_members_controller.js  v1.0
    decor/test/controllers/connection_groups_controller_test.rb   v1.0
    decor/docs/claude/DECOR_PROJECT.md                            v2.31
    decor/docs/claude/SESSION_HANDOVER.md                         v39.0

### What was done

**routes.rb v2.4:**
- Added `resources :connection_groups, only: %i[index new create edit update destroy]`
  nested inside `resources :owners`. No :show action (index suffices).
- Route helpers: `owner_connection_groups_path(@owner)`,
  `new_owner_connection_group_path(@owner)`,
  `edit_owner_connection_group_path(@owner, @cg)`,
  `owner_connection_group_path(@owner, @cg)`.

**connection_group.rb v1.1:**
- Added `reject_if: :all_blank` to `accepts_nested_attributes_for :connection_members`.
- Without this, blank dropdown rows (user adds a row but leaves it empty) attempt to
  build a ConnectionMember with no computer_id, failing belongs_to presence before
  the group-level minimum_two_members validator runs. reject_if: :all_blank silently
  discards empty rows — standard Rails idiom.

**connection_groups_controller.rb v1.0:**
- Full CRUD (index, new, create, edit, update, destroy).
- `before_action :require_login` — redirects to new_session_path if not authenticated.
- `before_action :set_owner` — finds Owner by params[:owner_id]; redirects to root_path
  with alert if owner != Current.owner. Prevents cross-owner access regardless of URL.
- `set_connection_group` scopes to `@owner.connection_groups` — prevents fetching
  another owner's group by id.
- `load_form_data`: `@connection_types` ordered by name; `@computers` scoped to owner,
  joined and eager-loaded, ordered by Arel.sql("computer_models.name ASC, serial_number ASC").
- `new` pre-builds 2 blank member rows; `edit` pre-builds 1 blank row.
- All redirects go to `owner_connection_groups_path(@owner)`.

**Views (index, new, edit, _form):**
- index: table of groups with Type, Label, Members columns; Edit/Delete actions;
  empty state. "New connection group" link at top right.
- new/edit: breadcrumb + heading, render shared _form partial.
- _form: connection_type select, label text field, nested member rows with
  Stimulus `connection-members` controller for add/remove.
  Dropdown label format: "Model name · SN serial (device_type)".
  <template> tag rendered server-side with all computer options populated.
  reject_if: :all_blank on model (v1.1) handles blank rows at save time.
  Submit label: "Create connection group" (new) or "Save connection group" (edit).
  Cancel: "Done" link — consistent with project button convention.

**connection_members_controller.js v1.0:**
- Stimulus controller with targets: membersList, template.
- `add(event)`: clones template innerHTML, replaces NEW_INDEX with Date.now(),
  appends to membersList.
- `remove(event)`: finds [data-member-row] ancestor.
  If [data-destroy-field] present (persisted row): sets value="1", hides row.
  If no destroy field (unsaved row): removes element from DOM.

**_navigation.html.erb v1.8:**
- Added "My Connections" link in owner dropdown, between "My Components" and
  the Profile divider. Links to owner_connection_groups_path(Current.owner).

**connection_groups_controller_test.rb v1.0:**
- 14 tests covering: authentication (3), authorisation (3), index (3),
  new (1), create valid + 2 invalid (3), edit (1), update valid + invalid (2),
  destroy (1), auth-destroy (already in authorisation block).

### Part 4 status
Files produced. Tests not yet run. Next session: bin/rails test → fix → rubocop → brakeman → commit → deploy.

---

## Complete File List (Sessions 31–36)

    decor/db/migrate/20260319000000_create_connection_types.rb              v1.0  ✓ merged
    decor/db/migrate/20260319010000_create_connection_groups.rb             v1.0  ✓ merged
    decor/db/migrate/20260319020000_create_connection_members.rb            v1.0  ✓ merged
    decor/app/models/connection_type.rb                                     v1.0  ✓ merged
    decor/app/models/connection_group.rb                                    v1.1  ← Session 36
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
    decor/config/routes.rb                                                  v2.4  ← Session 36
    decor/app/views/layouts/admin.html.erb                                  v1.9  ✓ merged
    decor/test/controllers/admin/connection_types_controller_test.rb        v1.0  ✓ merged
    decor/test/controllers/computers_controller_test.rb                     v1.7  ✓ merged (Session 35)
    decor/app/views/computers/show.html.erb                                 v1.9  ✓ merged (Session 35)
    decor/app/controllers/computers_controller.rb                           v1.17 ✓ merged (Session 34)
    decor/app/controllers/connection_groups_controller.rb                   v1.0  ← Session 36 new
    decor/app/views/connection_groups/index.html.erb                        v1.0  ← Session 36 new
    decor/app/views/connection_groups/new.html.erb                          v1.0  ← Session 36 new
    decor/app/views/connection_groups/edit.html.erb                         v1.0  ← Session 36 new
    decor/app/views/connection_groups/_form.html.erb                        v1.0  ← Session 36 new
    decor/app/javascript/controllers/connection_members_controller.js       v1.0  ← Session 36 new
    decor/app/views/common/_navigation.html.erb                             v1.8  ← Session 36
    decor/test/controllers/connection_groups_controller_test.rb             v1.0  ← Session 36 new

---

## Priority 1 — Next Session: Run Tests + Commit Part 4

Steps:
  1. Place all 12 Session 36 files (see file list above)
  2. bin/rails test — fix any failures
  3. bundle exec rubocop -A; bundle exec rubocop
  4. bin/brakeman --no-pager
  5. git add -A; git commit; git push; gh pr create; gh pr merge --merge; kamal deploy

Upload at next session start:
  - The standard 5 rule documents
  - Any test failure output (paste to context) if tests fail before session start

Known risk: the `view` tool was used to read the skill file at session start in Session 36
(instead of bash cat). This is noted above. No content was truncated (skill file is short),
but the violation is recorded.

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

**End of SESSION_HANDOVER.md**
