# decor/docs/claude/SESSION_HANDOVER.md
# version 32.0

**Date:** March 18, 2026
**Branch:** main (Sessions 1–29 committed and deployed; Session 30 migration ready to branch/PR/deploy)
**Status:** Tests not re-run this session (migration-only change; no model/controller/test code
changed). Run `bin/rails test` locally before pushing the migration PR.

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

---

## !! TOKEN BUDGET WARNING !!

Sessions 28–30 hit ~50–65% context usage after rule document reads. The fixed
overhead (5 rule documents + system prompt + tool schemas + bash cat outputs)
consumes ~50–65% of the window before any work output is written.

**Practical consequence:** each session has room for roughly one focused task.
Do not plan multi-task sessions.

---

## !! FIXTURE DELIVERY RULE !!

Whenever a fixture file is modified in a session, upload it to verify the change
is actually present before closing the session. A summary entry is NOT confirmation
of delivery. (Established Session 27.)

---

## Session 30 Summary

**Focus: Housekeeping — CVE fix, Dependabot PRs, computer_models CHECK constraint**

No model or controller code changes. No test changes. Migration + Gemfile.lock only.

### Changes

1. **action_text-trix CVE fix (GHSA-qmpg-8xg6-ph5q)**
   `bundler-audit` caught `action_text-trix` v2.1.16 (stored XSS) blocking the
   `feature/add-peripherals-admin-export-import` PR CI check. Fixed with:
   `bundle update action_text-trix` → Gemfile.lock updated. PR merged, deployed.

2. **Dependabot PRs — all 8 merged**
   All had passing CI; merged in order oldest-first via:
   `gh pr merge --merge --delete-branch` for each.

   #20  Bump bootsnap 1.22.0 → 1.23.0
   #31  Bump selenium-webdriver 4.40.0 → 4.41.0
   #32  Bump web-console 4.2.1 → 4.3.0
   #33  Bump minitest 5.27.0 → 6.0.2  (major version — CI confirmed compatible with Rails 8.1.2)
   #34  Bump solid_queue 1.3.1 → 1.3.2
   #46  Bump actions/upload-artifact 6 → 7
   #47  Bump sqlite3 2.9.0 → 2.9.1
   #59  Bump thruster 0.1.18 → 0.1.19

3. **`20260318000000_add_device_type_check_to_computer_models.rb` v1.0** — new migration
   Adds CHECK(device_type IN (0,1,2)) to computer_models table using SQLite table
   recreation pattern (disable_ddl_transaction!, explicit column names, FK pragma).
   Companion to migration 20260316100000 which did the same for computers (Session 25).
   **Still needs: branch → test → PR → CI → merge → deploy** (see commit block below).

---

## Commit Session 30 migration

```bash
git switch main
git pull origin main
git switch -c feature/device-type-check-computer-models
# Place migration file at:
# decor/db/migrate/20260318000000_add_device_type_check_to_computer_models.rb
bin/rails db:migrate
bin/rails test
git add -A
git commit -m "Session 30: Add CHECK(device_type IN (0,1,2)) to computer_models table"
git push origin feature/device-type-check-computer-models
gh pr create --fill
gh pr checks feature/device-type-check-computer-models --watch
# Once green:
gh pr merge --merge --delete-branch feature/device-type-check-computer-models
git switch main
git pull origin main
kamal deploy
```

---

## Work Completed Session 30 — Complete File List

    decor/db/migrate/20260318000000_add_device_type_check_to_computer_models.rb      v1.0
    decor/docs/claude/DECOR_PROJECT.md                                               v2.24
    decor/docs/claude/SESSION_HANDOVER.md                                            v32.0

---

## Priority 1 — Next Session Candidates

All housekeeping items from the previous backlog are now cleared:
- ✅ Dependabot PRs — done Session 30
- ✅ CHECK(device_type IN (0,1,2)) on computer_models — done Session 30
- ✅ Surface 1 + Surface 2 export/import — done Sessions 28–29

Remaining candidates:

1. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
2. **System tests** — decor/test/system/ still empty.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.

---

## Priority 2 — Other Candidates (unchanged)

(Same as Priority 1 list above — all are un-started candidates.)

---

## Unique Constraint Design Reference (Session 28, unchanged)

### computers table
Index: `index_computers_on_owner_model_and_serial_number`
Columns: `(owner_id, computer_model_id, serial_number)`
Scope rationale: a VT220 "unknown" and a VT320 "unknown" for the same owner are
physically different devices — only owner + model + serial must be unique.
Migration: `20260316120000_add_unique_index_to_computers_serial_number.rb`
Model validation: `validates :serial_number, uniqueness: { scope: [:owner_id, :computer_model_id] }`

### components table
Index: `index_components_on_owner_type_and_serial_number`
Columns: `(owner_id, component_type_id, serial_number)`
Scope rationale: owners invent their own replacement numbering; cross-owner
collisions are expected and valid. allow_blank: true — multiple unserialised
spares of the same type are always permitted (SQLite NULL != NULL in unique index).
Migration: `20260316110000_add_unique_index_to_components_serial_number.rb`
Model validation: `validates :serial_number, uniqueness: { scope: [:owner_id, :component_type_id] }, allow_blank: true`

### Import service duplicate-check pattern (v1.3)
```ruby
# computers — model resolved FIRST so check can scope by model:
model = ComputerModel.find_by(name: model_name)
return if @owner.computers.exists?(computer_model: model, serial_number: serial_number)

# components — scoped by type:
return if @owner.components.exists?(component_type: component_type, serial_number: serial_number)
```

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
