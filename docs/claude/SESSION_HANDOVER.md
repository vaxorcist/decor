# decor/docs/claude/SESSION_HANDOVER.md
# version 15.0

**Date:** March 3, 2026
**Branch:** main (session 14 work not yet committed — see Git State below)
**Status:** Admin dropdown nav + DRY Computer/Appliance Models pages working;
            tests passing (333 tests, 0 failures); rule docs updated.

---

## !! RELIABILITY NOTICE — READ FIRST !!

Session 14 revealed two systematic failures that must not recur:

### 1. Rule documents were NOT fully read

The `view` tool silently truncates files above ~16,000 characters. DECOR_PROJECT.md
(636 lines) was truncated during the first read — lines 215–422 were lost silently.
This is unacceptable. The rules set exists to be read completely.

**MANDATORY at every session start:**
Read ALL rule documents using `bash cat` — never the `view` tool for file content.
After each document, log: `Read FILENAME — N lines, complete.`

```bash
cat /mnt/user-data/uploads/COMMON_BEHAVIOR.md
cat /mnt/user-data/uploads/RAILS_SPECIFICS.md
cat /mnt/user-data/uploads/PROGRAMMING_GENERAL.md
cat /mnt/user-data/uploads/DECOR_PROJECT.md
cat /mnt/user-data/uploads/SESSION_HANDOVER.md
```

### 2. Parallel test files were not read before writing tests

`computer_test.rb` v1.4 (Session 13) already demonstrated the correct enum
assertion pattern. Writing `computer_model_test.rb` without reading it first
caused three test failures across two fix rounds. The pattern was in the codebase.
The failure was entirely preventable.

**MANDATORY before writing any test:**
Read the most recent parallel test file in the codebase — not the handover summary.

---

## Session Summary

Session 14 delivered:
1. Admin dropdown navigation (Stimulus `dropdown_controller.js`)
2. DRY Computer/Appliance Models admin pages (one controller, one view set, two routes)
3. `device_type` enum on `computer_models` table (migration + model update)
4. Full test coverage: model tests + controller tests for both contexts
5. Rule document updates: COMMON_BEHAVIOR.md v2.0, RAILS_SPECIFICS.md v2.0,
   DECOR_PROJECT.md v2.11 (Directory Tree section added)

---

## Work Completed This Session

### 1. Admin Dropdown Navigation

    decor/app/javascript/controllers/dropdown_controller.js    (v1.0)  NEW
    decor/app/views/layouts/admin.html.erb                     (v1.3)

`dropdown_controller.js`: Stimulus controller. Toggle on click, close on outside
click. Bound listener stored in `connect()`, removed in `disconnect()` — no
Turbo navigation leaks.

`admin.html.erb` v1.3: Five dropdown menus replacing flat links:
- Owners → Manage Owners / Pending Invites
- Computers → Computer Models / Computer Conditions / Run Statuses
- Appliances → Appliance Models (activated in v1.3; was disabled placeholder in v1.2)
- Components → Component Types / Component Conditions
- Import/Export → Bulk Import Data
Exit Admin unchanged, far right.

### 2. DRY Computer/Appliance Models — Migration

    decor/db/migrate/20260303110000_add_device_type_to_computer_models.rb    (v1.0)  NEW

Adds `device_type` integer column to `computer_models`, null: false, default: 0,
with index. Mirrors the enum already on the `computers` table.
Enum values: `computer: 0`, `appliance: 1`.

### 3. DRY Computer/Appliance Models — Model

    decor/app/models/computer_model.rb    (v1.1)

Added `enum :device_type, { computer: 0, appliance: 1 }, prefix: true`.
Generates `device_type_computer?` / `device_type_appliance?` predicates and scopes.
`dependent: :restrict_with_error` retained (unchanged from v1.0).

### 4. DRY Computer/Appliance Models — Routes

    decor/config/routes.rb    (v1.3)

Added `resources :appliance_models, controller: "computer_models",
defaults: { device_context: "appliance" }`.
`computer_models` now also carries `defaults: { device_context: "computer" }`.
The `device_context` param is the sole mechanism by which the shared controller
knows which type it is serving.

### 5. DRY Computer/Appliance Models — Controller

    decor/app/controllers/admin/computer_models_controller.rb    (v1.2)

`before_action :set_device_context` sets all context variables from `device_context`:
  @model_label, @model_label_plural, @device_type_key, @device_type_value,
  @index_path, @new_path, @create_path, @update_path_for, @edit_path_for, @delete_path_for.

Critical lesson: `form_with model: [:admin, record]` always derives its URL from
the model class name, ignoring route context. Must pass explicit `url:` to form_with.
This required `@create_path` (for new records) and `@update_path_for` (bound method,
for existing records) to be set in `set_device_context` and used in `_form.html.erb`.

### 6. DRY Computer/Appliance Models — Views

    decor/app/views/admin/computer_models/index.html.erb    (v1.1)
    decor/app/views/admin/computer_models/new.html.erb      (v1.1)
    decor/app/views/admin/computer_models/edit.html.erb     (v1.1)
    decor/app/views/admin/computer_models/_form.html.erb    (v1.2)

All hardcoded "Computer" strings replaced with `@model_label` / `@model_label_plural`.
No `decor/app/views/admin/appliance_models/` directory created — Rails uses the
`computer_models/` views for both routes because the controller is the same.

`_form.html.erb` v1.2: explicit `url:` on `form_with`:
```erb
<% form_url = computer_model.new_record? ? @create_path : @update_path_for.call(computer_model) %>
<%= form_with model: [:admin, computer_model], url: form_url, ... %>
```

### 7. Tests

    decor/test/fixtures/computer_models.yml                      (v1.1)
    decor/test/models/computer_model_test.rb                     (v1.2)
    decor/test/controllers/admin/computer_models_controller_test.rb    (v1.1)

`computer_models.yml` v1.1: explicit `device_type` on all fixtures; added `hsc50`
(device_type: 1) as the appliance fixture for tests.

`computer_model_test.rb` v1.2: enum default, predicates, scope disjointness.

`computer_models_controller_test.rb` v1.1: both contexts (computer + appliance);
index scoping, create stamps correct device_type and redirects correctly, edit
headings, update, destroy (with and without dependent computers), authorization.

**Test failures encountered and root causes:**
- `read_attribute(:device_type)` and `model[:device_type]` both return the enum
  string label, not the raw integer. Correct form: `assert_equal "computer", model.device_type`
  or predicate `assert model.device_type_computer?`.
  Rule added to RAILS_SPECIFICS.md v2.0.

### 8. Rule Document Updates

    decor/docs/claude/COMMON_BEHAVIOR.md    (v2.0)
    decor/docs/claude/RAILS_SPECIFICS.md    (v2.0)
    decor/docs/claude/DECOR_PROJECT.md      (v2.11)

COMMON_BEHAVIOR.md v2.0:
- "Reading Rule Documents" section: ALWAYS bash cat, NEVER view tool for file content
- "AI Forgetfulness" section: honest explanation of why attention is non-uniform,
  why rules decay in influence over a long session, and what mitigations work
- Complete path specification rule added to File Delivery section
- Token estimate floor: 5+ large documents → minimum 40% estimate at session start

RAILS_SPECIFICS.md v2.0:
- Enum assertion rule: `.device_type`, `read_attribute`, and `model[:]` all return
  the string label. Use string comparison or predicates, not integers.
- Directory Tree Maintenance rule (added earlier this session)

DECOR_PROJECT.md v2.11:
- "## File Structure" section replaced with "## Directory Tree" containing the
  live tree from `decor_tree.txt` (March 3, 2026) and a Key file versions table.
- Tree command documented for regeneration at session start.

---

## Lessons Learned This Session

### view tool truncates silently — always use bash cat for rules documents
The `view` tool's truncation notice appears only in Claude's internal output.
The user cannot see it. The only safe tool for reading rule documents is `bash cat`.

### Read parallel test files directly, not just handover summaries
Handover summaries describe patterns; they do not show them. The actual file shows
them. Reading `computer_test.rb` before writing `computer_model_test.rb` would have
prevented three test failures immediately.

### form_with derives URL from model class, ignoring route context
`form_with model: [:admin, record]` always generates the URL from the class name
(`ComputerModel` → `/admin/computer_models`). When two routes share a controller,
you MUST pass an explicit `url:` — the route context is not propagated.

### Rails enum accessors never return raw integers
`model.attr`, `read_attribute(:attr)`, and `model[:attr]` all return the mapped
string for enum columns. Use `assert_equal "string", model.attr` or predicates.
Use `read_attribute_before_type_cast(:attr)` only when the raw integer is genuinely needed.

### AI attention is not uniform — rules decay in influence over long sessions
By turn 20, rule documents read at turn 1 compete with everything that followed.
Rules are not self-enforcing. They require complete reads (bash cat), explicit
checklists at task time, and user intervention when violations occur.

---

## Pending — Start of Next Session

### 1. Commit session 14 work
All files below are ready to commit. Suggested message:
```
Admin dropdown nav; DRY Computer/Appliance Models pages; reliability rule updates
```

### 2. Naming — "appliance" placeholder still unresolved
The final UI label for `device_type: 1` (currently "Appliance") has not been
confirmed by the English partner. Once confirmed:
- Update enum key in `computer_model.rb` and `computer.rb` (and migration comments)
- Update fixture labels
- Update all UI-facing strings

### 3. UI changes — computers index and form (device_type) — carried over
The computers index page and form do not yet reflect `device_type`. Needed:
- Index: visual distinction or separate sections for computers vs appliances
- Form: `device_type` selector

### 4. UI changes — components form and show (component_category) — carried over
`component_category` (integral/peripheral) not yet exposed in the UI.

### 5. Database-level ON DELETE CASCADE for computer → components — carried over
Rails-layer `dependent: :destroy` in place. DB migration still needed.

### 6. BulkUploadService stale model references — low priority, carried over

---

## Git State

**Branch:** main
**Session 14 work is NOT yet committed.**
**First action next session:** commit all session 14 files, then continue.

Files to commit:

    decor/app/javascript/controllers/dropdown_controller.js
    decor/app/views/layouts/admin.html.erb
    decor/db/migrate/20260303110000_add_device_type_to_computer_models.rb
    decor/app/models/computer_model.rb
    decor/config/routes.rb
    decor/app/controllers/admin/computer_models_controller.rb
    decor/app/views/admin/computer_models/index.html.erb
    decor/app/views/admin/computer_models/new.html.erb
    decor/app/views/admin/computer_models/edit.html.erb
    decor/app/views/admin/computer_models/_form.html.erb
    decor/test/fixtures/computer_models.yml
    decor/test/models/computer_model_test.rb
    decor/test/controllers/admin/computer_models_controller_test.rb
    decor/docs/claude/COMMON_BEHAVIOR.md
    decor/docs/claude/RAILS_SPECIFICS.md
    decor/docs/claude/DECOR_PROJECT.md
    decor/docs/claude/SESSION_HANDOVER.md

---

## Other Candidates

1. Dependabot PRs — dedicated session
2. Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
3. System tests: decor/test/system/ still empty
4. Account deletion + data export (GDPR)
5. Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
6. BulkUploadService stale model references (low priority)

---

## Documents Updated This Session

    decor/docs/claude/COMMON_BEHAVIOR.md    v2.0
    decor/docs/claude/RAILS_SPECIFICS.md    v2.0
    decor/docs/claude/DECOR_PROJECT.md      v2.11
    decor/docs/claude/SESSION_HANDOVER.md   v15.0

---

**End of SESSION_HANDOVER.md**
