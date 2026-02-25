# SESSION_HANDOVER.md
# version 7.0

**Date:** February 24, 2026
**Session Duration:** ~4 hours
**Branch:** main (all session 6 work committed and deployed)
**Status:** ✅ Production up to date — next session starts with component changes

---

## Session Summary

No application features added. Entire session was infrastructure, safety, and
documentation work: enabled SQLite FK enforcement, updated vulnerable gems,
created docs/claude/ directory, overhauled git workflow rules, and fully planned
the component changes + database type cleanup for next session.

---

## Work Completed This Session

### 1. SQLite FK Enforcement Enabled

**Problem:** SQLite defines FK constraints in schema but silently ignores them
at runtime without explicit configuration. All existing FK constraints were
decorative only.

**Fix:** Added `foreign_keys: true` to `decor/config/database.yml` default
section. Enables `PRAGMA foreign_keys = ON` per connection.

**Pre-enable verification:** All 8 FK relationships checked — 0 orphaned records
in development. Production verified clean AFTER deploy (process gap — should be
BEFORE deploy; documented in RAILS_SPECIFICS.md).

**Also fixed:** `decor/app/models/condition.rb` was missing
`has_many :components, dependent: :restrict_with_error`. Without it, deleting
a condition referenced by a component would produce a 500 error instead of a
friendly validation message. This line is TEMPORARY — will be removed when the
upcoming migration drops `condition_id` from components.

**Files modified:**

    decor/config/database.yml (v1.1)
    decor/app/models/condition.rb (v1.1)

### 2. Gem Security Updates

`bundler-audit` CI check caught two vulnerable gems:
- nokogiri 1.19.0 → 1.19.1 (GHSA-wx95-c6cv-8532, Medium)
- rack 3.2.4 → 3.2.5 (CVE-2026-22860 High directory traversal; CVE-2026-25500 Medium XSS)

**Files modified:**

    decor/Gemfile.lock

### 3. docs/claude/ Directory Created

    decor/docs/claude/COMMON_BEHAVIOR.md (v1.4)
    decor/docs/claude/PROGRAMMING_GENERAL.md (v1.5)
    decor/docs/claude/RAILS_SPECIFICS.md (v1.4)
    decor/docs/claude/DECOR_PROJECT.md (v2.4)
    decor/docs/claude/SESSION_HANDOVER.md (v7.0)

### 4. Rule Set Updates This Session

**COMMON_BEHAVIOR.md v1.3 → v1.4:**
- Mandatory file download rule: every new/updated file MUST be presented via
  present_files tool — never just a code block
- Key insight pattern: use "Key insight:" label when an underlying principle
  makes a mechanic clearer or more memorable

**PROGRAMMING_GENERAL.md v1.4 → v1.5:**
- Complete git workflow overhaul with explicit step-by-step table
- Start from clean main (git switch main + git pull origin main) — was omitted
- Local checks BEFORE commit: bin/rails test, rubocop, bin/brakeman --no-pager
- git add -A preferred over specific files
- gh pr create --fill uses commit message automatically
- gh pr checks BEFORE merge (not after — too late to act on failures)
- gh pr merge --merge flag REQUIRED — omitting triggers interactive prompt
- Explicit local branch cleanup: git branch -d <branch>
- Production verification BEFORE kamal deploy (FK enforcement lesson)

**RAILS_SPECIFICS.md v1.3 → v1.4:**
- Full SQLite FK enforcement section: why off by default, how to enable,
  pre-enable verification script, production check before deploy
- .yml files DO render in context window — corrected from v1.2 which listed
  them as requiring the view tool

---

## Git State

**Branch:** main
**All PRs merged:** Yes
**Last deployed:** Session 6 complete (FK enforcement + gem updates)
**docs/claude/ PRs:** All merged

---

## Next Session — START HERE

### Mandatory: provide these files immediately at session start

    decor/app/models/computer.rb
    decor/app/models/component.rb
    decor/app/models/owner.rb
    decor/app/controllers/components_controller.rb
    decor/test/fixtures/computers.yml
    decor/test/fixtures/components.yml
    decor/test/fixtures/owners.yml
    decor/test/fixtures/conditions.yml
    decor/test/fixtures/component_types.yml
    decor/test/fixtures/computer_models.yml
    decor/test/fixtures/run_statuses.yml

### Work to implement (single migration branch)

**New table: component_conditions**
- Field: `condition` VARCHAR(40) UNIQUE NOT NULL
- No UI yet (admin UI planned later)
- Seed values: unknown, working, probably working, defective,
  probably defective, incomplete

**Changes to components table:**
- DROP `condition_id` FK → `conditions` (replaces old association)
- ADD `component_condition_id` FK → `component_conditions` (optional, plain FK)
- ADD `serial_number` VARCHAR(20) with CHECK constraint
- ADD `order_number` VARCHAR(20) with CHECK constraint

**Database type cleanup (bundle with above):**

    computers.order_number      TEXT        → VARCHAR(20) + CHECK
    computers.serial_number     VARCHAR     → VARCHAR(20) + CHECK
    component_types.name        VARCHAR     → VARCHAR(40) + CHECK
    computer_models.name        VARCHAR     → VARCHAR(40) + CHECK
    conditions.name             VARCHAR     → VARCHAR(40) + CHECK
    owners.country_visibility   VARCHAR     → VARCHAR(20) + CHECK
    owners.email_visibility     VARCHAR     → VARCHAR(20) + CHECK
    owners.real_name            VARCHAR     → VARCHAR(40) + CHECK
    owners.real_name_visibility VARCHAR     → VARCHAR(20) + CHECK
    owners.user_name            VARCHAR     → VARCHAR(15) + CHECK  ← matches model validation
    run_statuses.name           VARCHAR     → VARCHAR(40) + CHECK

**After migration: model and view updates**
- `component.rb` — swap association, add serial_number/order_number validations
- `condition.rb` — remove temporary `has_many :components`
- `components_controller.rb` — add new fields to strong params
- Component form views — add serial_number, order_number, condition fields
- Embedded component sub-form on computer edit page — same additions

### Key decisions already made
- SQLite CHECK constraints required for actual length enforcement (VARCHAR alone is cosmetic)
- Plain FK only (no ON UPDATE CASCADE) — matches existing project pattern
- `component_conditions.condition` column name (not `name`) — intentional
- `owners.user_name` → VARCHAR(15) (not 20) — matches existing model validation
- `computers.serial_number` → VARCHAR(20) — same length as components
- Rename `conditions` → `computer_conditions` deferred to a later session

---

## Technical Notes From This Session

### SQLite FK Enforcement (new)
See RAILS_SPECIFICS.md — full section added. Key lesson: always verify
production data clean BEFORE deploying, not after.

### gh pr merge --merge flag
Omitting `--merge` triggers an interactive prompt asking which merge strategy
to use. Always include the flag explicitly.

### git switch -c carries uncommitted changes
When a file is already modified before running `git switch -c <branch>`, the
modified file is automatically on the new branch. No need to stash first.

### .yml files render in context window
Unlike .erb and .rb files, .yml/.yaml files appear as readable text when
uploaded to the chat. No view tool needed.

---

## Documents Updated This Session

    decor/docs/claude/COMMON_BEHAVIOR.md       v1.4
    decor/docs/claude/PROGRAMMING_GENERAL.md   v1.5
    decor/docs/claude/RAILS_SPECIFICS.md       v1.4
    decor/docs/claude/DECOR_PROJECT.md         v2.4
    decor/docs/claude/SESSION_HANDOVER.md      v7.0

---

**End of SESSION_HANDOVER.md**
