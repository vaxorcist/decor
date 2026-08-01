# decor/docs/claude/SESSION_HANDOVER.md
# version 82.0
# Session 81: Storage Locations Session C — FK on Computer/Component/
#   SoftwareItem + forms + show/index pages + the delete_confirm counts
#   upgrade. PARTIALLY IMPLEMENTED (20 of an eventual ~24 files), NOT
#   tested/committed/deployed. Two gaps found mid-session, not in the
#   original Session Plan file list: components/_component.html.erb was
#   never requested (components/index Storage Location column NOT YET
#   done); computers_controller.rb / components_controller.rb /
#   software_items_controller.rb strong params also never requested
#   (:storage_location_id not yet permitted anywhere — the three new form
#   dropdowns will silently no-op until this is fixed). A migration
#   timestamp bug was hit and fixed: the first draft used an invented
#   future date (20260803000100), which
#   ActiveRecord::InvalidMigrationTimestampError rejected — Rails checks
#   migration timestamps against real wall-clock time, not this project's
#   fictional session dates. Corrected to 20260730120000. New MANDATORY
#   RAILS_SPECIFICS.md v3.15 section added. Session ended on a
#   token-budget warning before the full wrap-up could be done safely;
#   rule-doc updates were delivered as manually-mergeable deltas and
#   merged into the real files at the start of Session 82. See "Session 81
#   Summary" below.
# Session 80: Storage Locations Session B — owner-facing CRUD (dedicated
#   page) — full Pre-Implementation Verification (18-file export/import
#   script request, all files read before writing code), implemented,
#   tested, lint/security-scanned, committed, merged, and DEPLOYED, all in
#   this same session. One genuine design mismatch surfaced and flagged to
#   Ulli mid-session (delete_confirm's counts-warning requirement vs. the
#   counting associations not existing until Session C) — resolved per
#   Ulli's explicit "do what you think is appropriate" instruction. See
#   "Session 80 Summary" below.
# Session 79: Storage Locations feature — full design consultation (7
#   open questions raised, all answered by Ulli), a 6-session implementation
#   plan (A–F) agreed, then Session A (migration + model + fixtures + model
#   tests) implemented, tested, lint/security-scanned, committed, merged,
#   and DEPLOYED — all in this one session. owner.rb bumped v1.6 → v1.7
#   (has_many :storage_locations, dependent: :destroy — added when it became
#   clear it was needed, not originally itemised). StorageLocation model
#   deliberately has no has_many :computers/:components/:software_items yet
#   — deferred to Session C once those tables have the FK column. Full
#   design (confirmed answers, file lists for all 6 sessions, dependency
#   graph) lives in DECOR_PROJECT.md "Storage Locations Feature — Session
#   Plan." See "Session 79 Summary" below for full detail.
# Session 78: Picked up the Session 77 open item (admin dropdowns not
#   closing siblings) — diagnosed via the two requested files
#   (dropdown_controller.js, admin.html.erb) and fixed with a shared
#   "dropdown:open" CustomEvent broadcast/listen pattern, no admin.html.erb
#   change needed. Also fixed two newly-reported bugs, each via full
#   Pre-Implementation Verification (actual files requested and read before
#   any code was written): (1) connection_groups/_form.html.erb's Device
#   dropdown was missing Owner Part Number from its option label, in BOTH
#   places that label is built (persisted-row fields_for loop + the
#   server-rendered <template> for new rows); (2) a REAL bug, not the
#   reported one — "New connection group page content is not centered" was
#   actually common/_navigation.html.erb's logo not being truly centered on
#   the viewport (grid-cols-[auto_1fr_auto] center column only centers on
#   leftover space between unequal-width left/right groups), not a bug in
#   the reported page at all. Fixed by absolutely-positioning the logo
#   against a `relative` <nav>. New MANDATORY RAILS_SPECIFICS.md v3.14
#   section added. All three fixes code-complete, NOT YET placed/tested/
#   committed. See "Session 78 Summary" below for full detail.
# Session 77: Six independent small bug fixes (all code-complete, NOT YET
#   placed/tested/committed): dynamic "Select a computer/peripheral model"
#   prompt; owners/peripherals.html.erb column header fix; computers/
#   show.html.erb Components sub-table gained the missing Owner Part No.
#   column; components/_filters.html.erb Search help text clarified, then
#   DEC Part Number added to both the search scope (component.rb) and the
#   text, with new test coverage; components/_form.html.erb's Computer/
#   Peripheral dropdown given a Ruby-side alphabetical sort (a different
#   root cause from Session 76's Tom Select bug). Also a REAL bug fixed:
#   common/_navigation.html.erb's Info dropdown had its first item obscured
#   on every filter-sidebar page — a z-index tie with each page's sticky
#   <h1>, broken by DOM order — fixed by raising the nav wrapper's z-index;
#   codified as a new MANDATORY RAILS_SPECIFICS.md v3.13 section. One NEW
#   bug reported but NOT diagnosed: admin interface dropdowns don't close
#   each other when a new one opens — files requested, session ended before
#   upload. See "Session 77 Summary" below for full detail.
# Session 76: Ulli confirmed Sessions 73 and 75 are both now checked and
#   deployed — see "Category Help Pages Feature — Session 73" (marked
#   RESOLVED below) and the updated Current Status. This session's own
#   work: computers/new.html.erb v1.6 redelivered (Session 75's file had
#   never actually been placed into the real project); four successive
#   fixes to components/_form.html.erb's Row 1 Computer/Peripheral dropdown
#   (v1.13 → v1.17: label rename, Owner Part Number added to the option
#   label, wording-order correction, column widened 50%, two "Auto-filled"
#   helper texts shortened to "device"); (3) a real, project-wide bug fix
#   in tom_select_controller.js (v1.0 → v1.1) — sortField: false silently
#   sorted every Tom Select dropdown by database id instead of name; (4) a
#   CI-caught StaleElementReferenceError fixed in
#   software_items_filters_test.rb (v1.1 → v1.2), unrelated to this
#   session's other work. Two new MANDATORY RAILS_SPECIFICS.md sections
#   added (v3.10 → v3.12) from real bugs this session — see that file's own
#   changelog. See "Session 76 Summary" below for full detail.
# Session 75: Three UI bug fixes, all code-complete, tested in browser by
#   Ulli, NOT YET lint/security-scanned or committed:
#   computers/new.html.erb v1.6 (stale required-fields notice text),
#   components/_form.html.erb v1.13 (Row 2 field alignment),
#   computers/show.html.erb v2.3 (missing Owner Part Number field + wrong
#   "Computer Model" label — both from the show page never being updated
#   alongside Sessions 70/71/74's _form.html.erb fixes). One bug introduced
#   and self-caught during this session's own delivery: an ERB comment
#   containing a literal <%= %> tag closed early and leaked text onto the
#   rendered page — fixed, and codified as a new RAILS_SPECIFICS.md rule.
#   Two rule-doc corrections made mid-session at the user's explicit request
#   (not a self-initiated wrap-up): COMMON_BEHAVIOR.md v3.2 gained two new
#   rules (don't update rule docs unprompted mid-session; don't @-encode
#   rule docs delivered alone) after Claude did exactly the two things those
#   rules now prohibit. RAILS_SPECIFICS.md gained the Tailwind-rebuild
#   reminder rule (v3.9) and, at this actual wrap-up, the ERB-comment rule
#   (v3.10). See "Session 75 Summary" below for full detail.
# Session 74: Adopted the Session 73 documentation-compression draft as the
#   working SESSION_HANDOVER.md, after reviewing it against the full v73.0
#   file rather than assuming the draft was complete. Three corrections made
#   before adoption: (1) version bumped 73.0 → 74.0 — the draft was still
#   stamped 73.0, identical to the file it replaces; (2) stale internal
#   version pointers corrected (RAILS_SPECIFICS.md v3.6/v3.3 references now
#   read v3.7; COMMON_BEHAVIOR.md v2.8 reference now reads v3.0) — the
#   sections still exist at those locations, only the version stamps had
#   drifted since the draft was written; (3) restored two pieces of
#   information the draft's Session 67 compression had dropped with no
#   surviving home elsewhere (not duplicated in DECOR_PROJECT.md): the
#   create/update `manual`-flag semantics (create always "added"; update
#   promotes nil→"modified" only on a previously-untouched row, never
#   reverts) and the "file-placement friction" lesson (a "still failing"
#   report can mean old files were never copied into the project, not a
#   logic bug in new code) — both folded back into the Session 67 summary
#   below as compact bullets rather than restored to full length.
#   RAILS_SPECIFICS.md's and DECOR_PROJECT.md's own compression passes are
#   still pending — not done this session.
# Session 73: Category Help Pages feature — 5 new owner-facing help pages
#   (Computers/Peripherals/Components/Connections/Software), admin-manageable
#   via the existing generic SiteText subsystem. Code-complete (7 files: 5
#   production, 2 test), NOT YET tested/lint/security-scanned/committed. Two
#   pre-existing bugs found and fixed via Never-Guess file review (a stale
#   title_for_key in the owner-facing controller; a hardcoded per-key case
#   statement in the admin controller's url_for_key, generalized). Also
#   closed a documentation gap: SiteText had never appeared in DECOR_PROJECT.md's
#   Data Model Overview despite existing since Session 18 — added this
#   session. See "Session 73 Summary" below for full detail.
# Session 72: CI Security (Ruby) failure on the feature/owner_part_number PR
#   diagnosed as bundle-audit (not Brakeman, per the existing rule) via the
#   actual CI log; four gems bumped (loofah, rails-html-sanitizer, sqlite3,
#   websocket-driver) to clear a batch of CVEs; confirmed clean locally;
#   merged and deployed. Separately, Ulli confirmed Sessions 67-70 (previously
#   described throughout this document as "sitting locally, uncommitted")
#   have ALL already been committed, pushed, merged, and deployed to main.
#   All "NOT YET committed/pushed/deployed" language for those sessions is
#   now resolved — see "Session 72 Summary" below and the update notes added
#   to the Date/Branch/Status block and each affected session summary.
# Session 71: Owner Part Number display fix (9 files — the 8 URLs missing the
#   column/field, per Session 70's own gap flag) delivered. Separately: agreed
#   and implemented a new File Transfer Protocol with the user — COMMON_BEHAVIOR.md
#   bumped to v3.0, replacing the old Download File Naming / Output Path Collision /
#   Upload File Naming rules with export/import shell scripts using @-encoded flat
#   filenames (decor/export/ and decor/import/, both gitignored). Updated the three
#   stale references to the old rules found in this file and in DECOR_PROJECT.md
#   (the "!! OUTPUT PATH COLLISION !!" banner below, the "Upload-collision hit
#   again this session" note, and the Session 63 file-list upload instruction).
# Session 70: Owner Part Number feature — IMPLEMENTED (11 of 12 files;
#   schema.rb regeneration pending an actual db:migrate run). All three open
#   design questions from Session 69 answered and implemented: uniqueness
#   scope keeps model/type dimension; both serial_number and the new
#   owner_part_number default to "-" via before_validation on both models;
#   spares collisions resolved via a one-time "SPARE-#{id}" backfill
#   migration with NO auto-assign going forward (Option B). CSV export/
#   import updated (owner_export_service.rb / owner_import_service.rb only —
#   computer_model_export_service.rb confirmed out of scope). See "Session 70
#   Summary" below for full detail, the resulting CSV re-import behaviour
#   change, and the complete NOT YET DONE checklist.
# Session 69: UI Terminology Rename — IMPLEMENTED (15 files). Owner Part
#   Number feature — design consultation only, NOT implemented, three open
#   questions. Also: this session found no "Session 68 Summary" exists in
#   this file despite Session 68 code changes clearly present in the actual
#   source (component_suggestions views carry "Session 68 (cont'd)" comments).
#   See "!! GAP NOTICE !!" and "Session 69 Summary" below.
# Session 67: Component Suggestions Phase 4 — IMPLEMENTED (migration, manual
#   flag, Download Manual Changes, import rewrite, paginated/filterable admin
#   index). bin/rails test passing locally (900 tests, 0 failures/errors).
#   NOT YET committed/pushed/deployed. See "Session 67 Summary" below.
# Session 66: Order number / variant — design pivot, no implementation. Full
#   multi-column variant-split design worked out in detail, then set aside
#   before implementation began (risk of "self-indulgent featuritis"). Saved
#   for reference at decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md. Adopted
#   a simpler concatenated-field approach instead. See "Session 66 Summary"
#   below for confirmed requirements going into next session.
# Session 65: Component order_number bulk maintenance (admin Components dropdown).

**Date:** July 30, 2026 (Session 81 — Storage Locations Session C:
  FK/forms/show/index pages PARTIALLY implemented, NOT tested, NOT
  committed, NOT deployed; rule-doc updates merged at start of Session 82)
**Branch:** main (Sessions 1–76 all committed, pushed, merged, and
  deployed, per Ulli's confirmation at the start of Session 76). Sessions
  77 and 78's own work (11 files — see "Session 77 Summary" and "Session 78
  Summary" below) status is UNCHANGED — no session since has confirmed
  placement/testing/commit for that work, which is a separate, unrelated
  bug-fix batch. Storage Locations Session A (Session 79) and Session B
  (Session 80) are BOTH committed, pushed, merged, and deployed — confirmed
  by Ulli. Storage Locations Session C (Session 81) is NOT on any branch
  yet — 20 of an eventual ~24 files are code-complete but not yet placed
  into the real project, not migrated, not tested, not committed.
**Status:** Sessions 1–76 fully closed out and deployed. Sessions 77 and
  78's combined checklist (see both summaries below) remains the open item
  it was at the end of Session 78 — not addressed since. Storage Locations
  Session A and Session B are BOTH fully closed out and deployed. Storage
  Locations Session C is IN PROGRESS (Session 81) — see "Session 81
  Summary" below for the full file list, the two flagged gaps
  (components/_component.html.erb never requested; strong params for
  computers_controller.rb/components_controller.rb/
  software_items_controller.rb never requested, so :storage_location_id
  currently silently no-ops on save), and the migration-timestamp bug that
  was hit and fixed (RAILS_SPECIFICS.md v3.15). **Session D (Privacy
  Audit) has NOT started and explicitly depends on Session C's completion**
  — see DECOR_PROJECT.md "Storage Locations Feature — Session Plan." The
  GAP NOTICE below (Session 68's missing formal summary) remains open and
  unaffected by any of this.

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

## !! GAP NOTICE — Session 68 has no formal summary in this document (found Session 69) !!

While reading files for the Session 69 UI rename task, several source files
delivered as part of the project (e.g.
`decor/app/views/admin/component_suggestions/index.html.erb`, which carried
a "Session 68 (cont'd)" changelog comment about dropdown-width/full-bleed
layout fixes) showed clear evidence of Session 68 work having happened and
been delivered. **But this SESSION_HANDOVER.md (as uploaded to the project)
has no "Session 68 Summary" section, and DECOR_PROJECT.md's own header
changelog jumps straight from Session 67 to Session 69 with no Session 68
entry either.**

This was not reconstructed or guessed at — per the Never-Guess rule, no
"Session 68 Summary" has been fabricated from the partial evidence in the
source files. **This is flagged for Ulli to reconcile:** either a newer
version of these two documents (containing the real Session 68 Summary)
exists outside this project and simply wasn't the version uploaded here, or
Session 68's rule-doc updates were never actually produced/delivered despite
the code changes shipping. Worth checking before treating this document as
a complete history.

**Update (Session 72):** Ulli confirmed the underlying code for Sessions
67–70 has all been committed, pushed, merged, and deployed to `main` — the
"uncommitted, stacked locally" situation described above and throughout this
document is now resolved on the git/deploy side. This documentation gap
(no formal Session 68 Summary ever written here) is a separate, still-open
issue — it does not block or affect the code, which is live — but is left
flagged in case Ulli wants to reconstruct it later from source history.

---

## !! GEARED PAGINATION — paginate() SETS @page AND RENDERS ITSELF (learned Session 67) !!

`paginate(scope)` is not a data-fetch step — it assigns `@page` (never a
model-named ivar) and internally calls `respond_to { format.turbo_stream;
format.html }`, i.e. it renders the response. Every ivar the view needs
(`@page_title`, `@turbo_tbody_id`, `@load_more_id`, `@index_path`) MUST be
set BEFORE calling it — it must be the last line of the action.
See RAILS_SPECIFICS.md v3.7 for the full rule and the actual concern source.

---

## !! RAILS ENUM — read_attribute DOES NOT BYPASS TYPE-CASTING (learned Session 67) !!

To get the raw stored value of an enum column ("a"/"m"), use
`<attribute>_before_type_cast` — NOT `read_attribute(:<attribute>)`, which
still returns the mapped label ("added"/"modified"). See RAILS_SPECIFICS.md
v3.7 for the full rule.

---

## !! COLLECTION ROUTES IN A NAMESPACED resources BLOCK — A SECOND PREFIX SHAPE (learned Session 67) !!

A `collection do get :foo end` route nested inside `resources` already
inside `namespace :admin` prepends the action name to the already-prefixed
resource name (`download_manual_admin_component_suggestions_path`) —
DIFFERENT from a custom `as:` route declared directly in the namespace
(Session 65's `admin_foo_path` shape). Always verify with
`bin/rails routes | grep <name>` — never assume either shape.
See RAILS_SPECIFICS.md v3.7 for the full rule.

---

## !! FLAGGING A GUESS DOES NOT SATISFY NEVER-GUESS (learned Session 67) !!

Writing a file from general convention and labeling it "inferred, please
verify" is still a Never-Guess violation — it shifts verification burden
onto the user instead of Claude asking for the real file. See
COMMON_BEHAVIOR.md v3.0 for the full rule and the real example.

---

## !! SYSTEM TESTS — BROWSER-LAYER LOGIN (learned Session 59) !!

`login_as` (AuthenticationHelper) posts to the Rails Rack adapter. It sets a
session cookie on the Rack test adapter — NOT on the Selenium browser process.
System tests run a real Chrome instance; its cookie jar is completely separate.

**Rule:** Never call `login_as` from a system test file.
Use `sign_in` (defined in ApplicationSystemTestCase v1.3) instead.
`sign_in` drives the real login form through the browser.

See `decor/test/application_system_test_case.rb` v1.3 for implementation.

---

## !! SYSTEM TESTS — CAPYBARA ASSERTION PATTERNS (learned Session 60) !!

Five gotchas (assert_selector + message string raises ArgumentError;
Capybara select() matches by TEXT not value=; filter forms in Turbo Frames
don't update the URL; Turbo navigation races in sign_in/sign_out;
`<template>` elements need evaluate_script) — full rules, wrong/correct code
examples: **RAILS_SPECIFICS.md v3.7, "System Tests — Capybara Assertion
Patterns."**

---

## !! SYSTEM TESTS — SIGN-OUT LINK MUST BE IN THE NAV (learned Session 60) !!

The `sign_out` helper in ApplicationSystemTestCase clicks a "Sign out" link.
The nav partial (`decor/app/views/common/_navigation.html.erb`) must include
this link inside the `<% if logged_in? %>` block:

```erb
<%= link_to "Sign out", session_path,
      data: { turbo_method: :delete },
      class: "font-medium text-stone-700 hover:text-stone-900" %>
```

Without this link, every system test that calls `sign_out` raises ElementNotFound.
The link was added in v2.3 of the navigation partial.

---

## !! DRY RULE — ALL passwords must use AuthenticationHelper constants !!

`TEST_PASSWORD_CHARLIE = "DecorTest2026!"` added to AuthenticationHelper v2.1.
**No literal password strings are permitted anywhere in the test suite.**
All test files must use:
  TEST_PASSWORD_ALICE   — owners(:one)
  TEST_PASSWORD_BOB     — owners(:two)
  TEST_PASSWORD_CHARLIE — owners(:three)
  TEST_PASSWORD_VALID   — dynamically created owners

---

## !! UI Renames — Rails auto-generates strings from model/column names (learned Session 58) !!

When renaming a concept in the UI, `<h1>` headings alone are not enough.
Also check and override explicitly:
  1. `f.submit`        — derives label from model class name
  2. `f.label :col`   — derives text from column name
  3. Index column headers, show labels, titles, breadcrumbs
  4. Flash notices that reference the field or model name
See RAILS_SPECIFICS.md v3.7 "UI Renames" section for full checklist with examples.

---

## !! FILE TRANSFER PROTOCOL — export/import scripts, @-encoded flat names !!

Session 71 replaced the old "Output Path Collision" rule (and the old
Download File Naming / Upload File Naming rules) with a single scheme: Claude
generates a shell script to export needed files into `decor/export/` (run from
inside that directory) and a placement script for delivered files staged in
`decor/import/`, both using @-encoded flat filenames (full path, `/`→`@`, all
dots except the true extension→`@`). `decor/export/` and `decor/import/` are
both gitignored. See COMMON_BEHAVIOR.md v3.0 "File Transfer Protocol —
Export/Import Scripts" for the full rule.

---

## !! TAILWIND CSS — REBUILD AFTER CLASS CHANGES (learned Session 75) !!

Any new or changed Tailwind utility class (especially an arbitrary-value
class like `min-h-[2.5rem]` never used elsewhere in the project) needs a
rebuild before it takes effect in the browser — placing the updated file on
disk is not enough. Claude must proactively remind the user of this,
**every time**, with the exact command:

```bash
bin/rails tailwindcss:build
```

(or restart the watcher, if one is running) — then hard-refresh the browser
(Ctrl+Shift+R / Cmd+Shift+R). Same shape as the `db:migrate` reminder: no
error message if skipped, the change just silently doesn't appear. See
RAILS_SPECIFICS.md v3.9 for the full rule and the real example.

---

## !! OUTPUT FILE NAMING — NEVER substitute underscores for dots !!

See COMMON_BEHAVIOR.md v2.7 for the full rule.

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

**Applied correctly Session 80:** `storage_locations_controller.rb`'s
`set_storage_location` and ownership-guard before_actions are both scoped
`only: %i[edit update destroy delete_confirm]`, excluding `new`/`create`/
`index` (which have no `:id`).

---

## !! paginate — NEVER assign the return value (learned Session 48) !!

`paginate scope` — no assignment. `@page = paginate(scope)` overwrites @page with nil.

---

## !! EXPORT/IMPORT — ALWAYS include a stable unique key (learned Session 49) !!

Every exported record type must carry a stable unique field for duplicate detection.
See PROGRAMMING_GENERAL.md v2.0 for the full rule.

---

## !! RESPONSE BODY ASSERTIONS — Use assert_body_includes (learned Session 50) !!

In integration tests, NEVER use `assert_match(text, response.body)` or
`refute_match(text, response.body)`. Use `assert_body_includes` /
`refute_body_includes` from ResponseHelpers instead.
See RAILS_SPECIFICS.md v3.7 for the full rule.

**Applied correctly Session 80:** the new
`storage_locations_controller_test.rb`'s "index shows only the current
owner's own storage locations" test uses `assert_body_includes` /
`refute_body_includes`, not `assert_match`/`refute_match`.

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

See RAILS_SPECIFICS.md v3.7 for the full rule.

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

See RAILS_SPECIFICS.md v3.7 for the full rule.

---

## !! before_validation vs before_save (learned Session 56) !!

If a model generates a field via callback AND validates it for presence, the
callback MUST be `before_validation` — NOT `before_save`.
See RAILS_SPECIFICS.md v3.7 for the full rule.

---

## !! Mailer views directory — Check existing structure first (learned Session 56) !!

This project stores mailer views under `app/views/mailers/<mailer_name>/`.
Always grep for existing mailer views before creating a new directory.

---

## !! deliver_later vs deliver_now — Admin tools use deliver_now (learned Session 56) !!

`deliver_later` hands off to ActiveJob — letter_opener never intercepts it.
For admin-initiated sends, use `deliver_now`.

---

## !! Email HTML — Gmail strips data: URIs (learned Session 57) !!

See RAILS_SPECIFICS.md v3.7 "Email HTML" section for full rules.

---

## !! ActionMailer::TestHelper in integration tests — include explicitly (learned Session 58) !!

ActionDispatch::IntegrationTest does NOT include ActionMailer::TestHelper
automatically. Include it explicitly in any test file using assert_emails.

---

## !! Newsletter fixture html_body — Set explicitly (learned Session 58) !!

Rails fixture loading bypasses model callbacks. Always set html_body explicitly.

---

## !! Admin update tests — include admin: "true" when updating self (learned Session 58) !!

See SESSION_HANDOVER v64.0 for the full rule.

---

## !! NAV LOGO CENTERING — a 1fr middle column centers on leftover space, not the viewport (learned Session 78) !!

If a nav bar has no max-width wrapper and centers its logo via a middle
`1fr` grid/flex column flanked by two unequal-width groups, the logo
centers on the LEFTOVER space between those groups, not the true viewport
center. Symptom: a page's own correctly-`mx-auto`-centered content gets
reported as "not centered" — the actual bug is the nav's logo position,
not the page. Fix: take the logo out of the flow, `absolute left-1/2
-translate-x-1/2` against a `relative` nav. See RAILS_SPECIFICS.md v3.14
for the full rule and code examples.

---

## !! STICKY HEADERS vs NAV DROPDOWNS — equal z-index ties broken by DOM order (learned Session 77) !!

A page-level sticky element (header, thead, filter sidebar) sharing the
same z-index as the nav's positioned wrapper will win ties against it,
since equal z-index is broken by DOM order and the page content comes
later in the document. Symptom: only the FIRST item of an open dropdown
looks obscured, not the whole menu. Fixed by raising the nav wrapper's
z-index clearly above any page-level z-10 sticky element. See
RAILS_SPECIFICS.md v3.13 for the full mechanism and code examples.

---

## !! TOM SELECT sortField — must be explicit, never a boolean (learned Session 76) !!

`sortField: false` is not a valid Tom Select option — it silently falls back
to enumerating options by internal object key, which for numeric-id option
values (e.g. `collection_select`) means ascending id order, not the
alphabetical order the Rails query actually produced. Always use an
explicit sort spec: `sortField: { field: "text", direction: "asc" }`.
See RAILS_SPECIFICS.md v3.12 for the full rule.

---

## !! CAPYBARA — capture expected text BEFORE Turbo navigation, not after (learned Session 76) !!

Reading `.text` (or any property) off a Capybara element AFTER a
`click_button`/`click_link` that navigates via Turbo risks
StaleElementReferenceError — Turbo replaces the DOM on navigation. Capture
the value into a plain string BEFORE the click, use that string in the
post-navigation assertion. See RAILS_SPECIFICS.md v3.12 for the full rule.

---

## !! CI SECURITY CHECKS — bundle-audit reports in batches, confirm clean locally (learned Session 64, reinforced Session 72) !!

General rule (`CI/Security (Ruby)` = bundle-audit, not Brakeman; pull the
actual CI log rather than assume): see RAILS_SPECIFICS.md v3.7 "CI Security
Checks — Two Separate Tools."

**Session 72 incident:** `feature/owner_part_number` failed on four gems in
one batch: `loofah` (→ >= 2.25.2), `rails-html-sanitizer` (→ >= 1.7.1),
`sqlite3` (→ >= 2.9.5), `websocket-driver` (→ >= 0.8.2). Fixed with
`bundle update <the four>`, confirmed clean with `bundle-audit check
--update` before re-pushing. Full incident: "Session 72 Summary" below.

---

## Session 77 Summary — Six small UI/search bug fixes + a real nav-dropdown z-index fix; one bug carried over undiagnosed

Six independent, unrelated small bugs reported and fixed, one at a time,
each following full Pre-Implementation Verification (actual files
requested and read before any fix was written — no guessing). A seventh,
different bug was reported at the very end of the session and remains
undiagnosed.

### Item 1 — computers/_form.html.erb: hardcoded "Select a computer model" prompt

Reported from `/computers/new?device_type=peripheral`: the Model
`collection_select`'s `prompt:` still read "Select a computer model" even
for a peripheral. Not present in `new.html.erb` itself (its device_type
label is already dynamic) — traced to `_form.html.erb` line ~77. Fixed:
`prompt: "Select a #{computer.device_type} model"`, matching the label
directly above it.

    decor/app/views/computers/_form.html.erb    v3.0 → v3.1

### Item 2 — owners/peripherals.html.erb: hardcoded "Computer Model" header

Reported from `/owners/1/peripherals`: the model column `<th>` read
"Computer Model" on a page that only ever lists `device_type: peripheral`
records. Row cells were already correct; only the header text was stale.
Fixed to "Peripheral Model".

    decor/app/views/owners/peripherals.html.erb    v1.5 → v1.6

### Item 3 — computers/show.html.erb: Components sub-table missing Owner Part Number

Reported from `/computers/89`: the embedded Components table (separate
from the Computer-level fields section already fixed in v2.3) had no Owner
Part No. column at all. Same "show page never updated alongside the form"
shape as the Session 73/75 examples already documented in
RAILS_SPECIFICS.md's "Single Source of Truth Refactors" section. Added
between "Order No." and "Serial No.", matching the column order already
established in `computers/_form.html.erb`'s own Components sub-table
(added there in Session 71).

    decor/app/views/computers/show.html.erb    v2.3 → v2.4

### Item 4 & 5 — components/_filters.html.erb + component.rb: Search field clarity, then DEC Part Number added

Reported from `/components`: unclear which fields the Search box actually
queries. Confirmed via `component.rb`'s `search` scope (v1.7): component
type name, owner username, computer/peripheral model name, description —
NOT order_number, serial_number, or owner_part_number. Added a
plain-language field list to the help text (v1.3).

**Follow-up, explicitly requested:** DEC Part Number (order_number) should
also be searchable. Added to the `search` scope's `LIKE` clause (5th
field) and to the help text (v1.4) to match.

This scope had **no test coverage at all** before this session.
`component_test.rb` gained 3 new tests: match by order_number (with a
distinctive value that appears nowhere else in the test record, proving
the order_number branch specifically), a query matching nothing returns
empty, and a blank query returns all records (the scope's own documented
short-circuit) — the last one derived from `Component.count` at call time
rather than hardcoded, per PROGRAMMING_GENERAL.md's "Derive Test
Assertions from Data" rule.

**Caught before delivery, not by the user:** a first-draft test used a
21-character `serial_number` literal — one over the column's 20-char max
length validation. Would have failed the new test for an unrelated reason
(length, not the search logic actually being tested). Fixed to 18
characters and all four new literals re-verified against the limit before
delivery.

    decor/app/views/components/_filters.html.erb    v1.2 → v1.3 → v1.4
    decor/app/models/component.rb                   v1.7 → v1.8
    decor/test/models/component_test.rb             v1.7 → v1.8

### Item 6 — components/_form.html.erb: Computer/Peripheral dropdown not sorted alphabetically

Reported from `/components/new`: the Computer/Peripheral dropdown wasn't
ordered alphabetically. **Root cause was NOT Session 76's Tom Select
`sortField` bug** — this select is a hand-built `f.select` (not
`collection_select`), deliberately excluded from Tom Select in Session 54
so its `computer-select` Stimulus controller (collapse-to-model-name on
selection) keeps working. The actual cause: `owner_computers =
Current.owner.computers.includes(:computer_model).to_a` had NO ordering
applied at all — options rendered in whatever order the DB happened to
return rows.

Fixed with a Ruby-side `sort_by` on the already-in-memory array — `[model
name (case-insensitive), order_number, serial_number]`, ascending, the
latter two as deterministic tie-breakers when two devices share a model.
Chosen over a DB-side `ORDER BY` on the joined `computer_models` table
(which would need `Arel.sql` + `.references`, more complexity for a small,
unpaginated, per-owner collection) — same "small collection, Ruby-side
sort" pattern already established in `computer_statistics_controller.rb`.

    decor/app/views/components/_form.html.erb    v1.17 → v1.18

### Item 7 — common/_navigation.html.erb: Info dropdown's first item obscured (REAL bug, root cause genuinely non-obvious)

Reported from `/owners` (screenshot provided): the Info dropdown's first
item ("Read Me") was obscured; every item further down the same dropdown
rendered fine. Diagnosis required requesting and reading FOUR files in
sequence before the cause was found — `common/_navigation.html.erb`, the
page's `_filters.html.erb`, the shared `layouts/application.html.erb`, and
finally the actual page template `owners/index.html.erb` — none of the
first three showed any conflict in isolation.

**Root cause:** `_navigation.html.erb`'s left-nav-group wrapper (`relative
z-10`) ties in z-index with `owners/index.html.erb`'s `<h1 class="sticky
top-0 z-10 ...">`. Equal z-index is broken by DOM order — the `<h1>`
(inside `<main>`, later in the document than `<nav>`) wins the tie and
paints over the dropdown wherever they visually overlap, which is exactly
where a dropdown's first item lands (right at the top of the page content).
Items further down aren't covered simply because the `<h1>` is short.

Fixed by raising the nav wrapper from `z-10` to `z-20` — clearly above any
page-level `z-10` sticky element (headers, `<thead>`s, sticky filter
sidebars), so the whole nav subtree (including every dropdown menu's own
`z-50`, which is only ever compared locally within this wrapper) wins
unambiguously instead of relying on a DOM-order tiebreak. This is
presumed to fix the identical bug on Computers/Peripherals/Components/
Software too, since `owners/index.html.erb`'s own comment states it was
"Fixed to exactly match computers page layout" — all five index pages are
expected to share the same sticky-header pattern. Also incidentally
protects the "Statistics" dropdown (same wrapper) from the identical
latent issue, which wasn't reported as visibly broken, likely only because
its items sit further right and don't currently overlap any page's short
`<h1>`.

Codified as a new MANDATORY RAILS_SPECIFICS.md v3.13 section — full
mechanism, code examples, and the diagnostic symptom to watch for next
time ("only the first item is obscured" → suspect this exact tie).

    decor/app/views/common/_navigation.html.erb    v2.5 → v2.6

### Open item — NOT diagnosed, carried to next session

**Admin interface: opening one dropdown menu doesn't close previously-open
ones.** Reported from `/admin/owners` with a screenshot showing all nine
admin nav dropdowns open simultaneously (Owners, Computers, Peripherals,
Components, Connections, Software, Newsletters, Imports/Exports, Texts) —
later-opened menus visually cover earlier ones since nothing closes prior
open menus. This is a different mechanism from Item 7 above (a JS/Stimulus
behavior gap, not a CSS stacking issue): each `data-controller="dropdown"`
block in `admin.html.erb` is an independent Stimulus controller instance
with no shared awareness of sibling dropdown state, so opening one doesn't
tell the others to close. Two files were requested to confirm the actual
controller structure before proposing a fix
(`decor/app/javascript/controllers/dropdown_controller.js` and
`decor/app/views/layouts/admin.html.erb`) — Ulli ended the session before
uploading them. **Next session: pick up here first.** Likely fix shape (not
yet confirmed against the real controller code): dispatch a shared
"close-others" signal on open (e.g. a custom event on `window`, or a
Stimulus outlet/target registry) that every dropdown instance listens for
and responds to by closing itself unless it's the one that just opened.

### Rule/skill document updates this session (session wrap-up, per Ulli's explicit "wrap up now")

    decor/docs/claude/RAILS_SPECIFICS.md     v3.12 → v3.13 (new MANDATORY section:
                                                             sticky-header/nav-dropdown
                                                             z-index tie-break)
    decor/docs/claude/SESSION_HANDOVER.md    v77.0 → v78.0 (this summary + status update +
                                                             one new banner entry)
    decor/docs/claude/DECOR_PROJECT.md       v2.67 → v2.68 (this session's changelog +
                                                             new Session 77 section +
                                                             Key file versions entries)

No COMMON_BEHAVIOR.md or PROGRAMMING_GENERAL.md changes this session — no
new workflow/behavioral lessons, only Rails/CSS-technical ones (and one
still-open JS/Stimulus question for next session).

### NOT YET DONE — required before Session 77's work is fully closed out

    [ ] Run the two export scripts' delivered files through placement
        (all 7 files: computers/_form.html.erb, owners/peripherals.html.erb,
        computers/show.html.erb, components/_filters.html.erb, component.rb,
        component_test.rb, components/_form.html.erb — NOTE: computers/_form.html.erb
        and components/_form.html.erb are DIFFERENT files, both touched this session)
    [ ] common/_navigation.html.erb placement (8th file, delivered separately)
    [ ] bin/rails test (including the 3 new component_test.rb search-scope tests)
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check — in particular, confirm the Info dropdown
        fix (z-10 → z-20) actually resolves the obscured-first-item bug on
        ALL FIVE affected pages (Owners, Computers, Peripherals, Components,
        Software), not just Owners where it was directly observed
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy
    [ ] Next session: diagnose and fix the admin-dropdowns-don't-close-each-other
        bug (files requested, not yet uploaded — see "Open item" above)

---

## Session 81 Summary — Storage Locations Session C: partially implemented, two gaps flagged, migration timestamp bug fixed

### Pre-Implementation Verification — one miss

An 18(→20 after a follow-up)-file export script was used per the File
Transfer Protocol. Two files needed for this session's own scope were
missed in the request, not caught until actually writing code:
`decor/app/views/components/_component.html.erb` (the row partial
`components/index.html.erb` renders — analogous to `_computer.html.erb`
and `_software_item.html.erb`, but never itemised in DECOR_PROJECT.md's
own Session C file list) and `decor/app/controllers/computers_controller.rb`
/ `components_controller.rb` / `software_items_controller.rb` (strong
params must permit the new `:storage_location_id` field submitted by the
three form dropdowns delivered this session, or the field silently no-ops
on save). Both gaps were flagged rather than guessed through — an
`export_session_c_followup_files.sh` was generated requesting all four
files (the three controllers + the partial) plus
`test/models/storage_location_test.rb` as a non-blocking nice-to-have —
but Ulli had not yet uploaded them when the session ended.

### Files delivered and placed this session (20, pending placement confirmation)

    decor/db/migrate/20260730120000_add_storage_location_to_computers_components_software_items.rb  NEW (v1.1 —
      see "Migration timestamp bug" below; original v1.0 delivery used an
      invalid future timestamp, 20260803000100, and must NOT also exist in
      db/migrate/ — delete that file if present)
    decor/app/models/storage_location.rb          v1.0 -> v1.1 (added the
      has_many :computers/:components/:software_items, dependent: :nullify
      trio deliberately deferred from Session A)
    decor/app/models/computer.rb                  v2.3 -> v2.4
    decor/app/models/component.rb                 v1.8 -> v1.9
    decor/app/models/software_item.rb              v1.0 -> v1.1
      (all three: belongs_to :storage_location, optional: true)
    decor/app/controllers/storage_locations_controller.rb   v1.0 -> v1.1
      (delete_confirm now computes real @computers_count /
      @components_count / @software_items_count, replacing Session B's
      interim count-less confirmation)
    decor/app/views/storage_locations/delete_confirm.html.erb  v1.0 -> v1.1
      (shows the real counts warning)
    decor/app/views/computers/_form.html.erb       v3.1 -> v3.2
    decor/app/views/components/_form.html.erb      v1.18 -> v1.19
    decor/app/views/software_items/_form.html.erb  v1.1 -> v1.2
      (all three: Storage Location dropdown added, scoped to
      Current.owner.storage_locations.order(:name), include_blank "No
      location assigned")
    decor/app/views/computers/show.html.erb        v2.4 -> v2.5
    decor/app/views/components/show.html.erb       v1.8 -> v1.9
    decor/app/views/software_items/show.html.erb   v1.1 -> v1.2
      (all three: Storage Location display field added, gated by
      "Current.owner == record.owner || admin?" — stricter than the
      logged_in? guard Trade Status uses, since these show pages are
      public and Storage Location is private data)
    decor/app/views/computers/index.html.erb       v1.11 -> v1.12
    decor/app/views/computers/_computer.html.erb   v1.12 -> v1.13
    decor/app/views/software_items/index.html.erb  v1.1 -> v1.2
    decor/app/views/software_items/_software_item.html.erb  v1.0 -> v1.1
      (all four: Storage Location column added, "own-view only" — header
      guarded by logged_in? like Barter, but the cell only reveals the
      real value when Current.owner == the row's owner; every other row
      shows a plain em-dash. components/index.html.erb + a new
      _component.html.erb are the SAME change, NOT done — see gap above.)
    decor/test/models/computer_test.rb             v1.7 -> v1.8
    decor/test/models/component_test.rb            v1.8 -> v1.9
    decor/test/models/software_item_test.rb        v1.0 -> v1.1
      (all three: "storage_location is optional", "can be assigned...",
      "storage_location_id is nullified when the storage_location is
      destroyed" — narrow, forward-direction tests only. The
      reverse-direction test, from StorageLocation's own has_many
      :nullify side, belongs in test/models/storage_location_test.rb,
      which was not available to read this session — flagged as a
      follow-up, not fabricated.)

### Migration timestamp bug (real, hit and fixed this session)

First delivery of the migration used timestamp `20260803000100`.
`bin/rails db:migrate` raised `ActiveRecord::InvalidMigrationTimestampError`:
Rails validates migration timestamps against the actual real-world
wall-clock time the command runs at — NOT against this project's
in-session fictional "current date" convention. Corrected to
`20260730120000` (after the last real migration, 20260727000100 from
Session A; before actual current time). New MANDATORY RAILS_SPECIFICS.md
v3.15 section added from this — see that file's own changelog.

### Test Coverage Check (per PROGRAMMING_GENERAL.md)

    New server-side logic this session (not yet tested end-to-end):
      Computer/Component/SoftwareItem#storage_location association — yes,
        tested: optional assignment, nullify-on-destroy (3 model test files
        updated, 9 new tests total)
      StorageLocationsController#delete_confirm real-counts upgrade — NOT
        yet tested; storage_locations_controller_test.rb was not part of
        this session's file requests and needs a follow-up update to cover
        the new @computers_count/@components_count/@software_items_count
        assertions (flagged, not fabricated this session)
      Three controllers' strong-params changes — NOT YET MADE, so nothing
        to test yet; this is the second flagged gap above

### NOT YET DONE

    [ ] Upload the 4 followup files (export_session_c_followup_files.sh)
    [ ] components/index.html.erb + NEW components/_component.html.erb
        Storage Location column (own-view-only, matching the computers/
        software_items pattern already delivered)
    [ ] :storage_location_id added to computers_controller.rb /
        components_controller.rb / software_items_controller.rb strong params
    [ ] Delete the bad-timestamp migration file if it was ever placed;
        place the corrected 20260730120000 one instead
    [ ] bin/rails db:migrate
    [ ] bin/rails test (including the 9 new model tests, plus a
        storage_locations_controller_test.rb update for the delete_confirm
        real-counts upgrade — not yet written)
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check: all three forms save storage_location_id
        correctly; all three show pages display it only for the owner/
        admin; all four (soon five) index pages show it own-row-only
    [ ] git workflow: branch -> commit -> push -> PR -> CI -> merge -> deploy
    [ ] Session D (Privacy Audit) still NOT STARTED — depends on this
        session's completion

### Rule/skill document updates — delivered as deltas this session, merged at start of Session 82

Session 81 ended on a token-budget warning before a safe full-file
regeneration could be done. Per the session-end handover protocol, updates
were delivered as three manually-mergeable delta files
(`RAILS_SPECIFICS_delta_session81.md`, `SESSION_HANDOVER_delta_session81.md`,
`DECOR_PROJECT_delta_session81.md`) rather than full regenerated documents.
These were merged into the real files at the start of Session 82:

    decor/docs/claude/RAILS_SPECIFICS.md     v3.14 -> v3.15 (new MANDATORY
                                                             section: migration
                                                             timestamps)
    decor/docs/claude/SESSION_HANDOVER.md    v81.0 -> v82.0 (this summary +
                                                             status update)
    decor/docs/claude/DECOR_PROJECT.md       v2.71 -> v2.72 (Session C marked
                                                             IN PROGRESS in the
                                                             Storage Locations
                                                             Session Plan +
                                                             Key file versions
                                                             entries)

No COMMON_BEHAVIOR.md or PROGRAMMING_GENERAL.md changes — no new
workflow/behavioral lesson this session, only a Rails-technical one (the
migration timestamp rule) and two plain misses of the existing
Pre-Implementation Verification rule (the two flagged gaps above), which
don't need new rules — just closing out via the followup export.

---

## Session 80 Summary — Storage Locations Session B: owner-facing CRUD implemented, tested, and deployed

### Pre-Implementation Verification

Before writing any code, an 18-file export script was generated per
COMMON_BEHAVIOR.md's File Transfer Protocol (correctly used the script for
this multi-file request — no repeat of a plain-prose ask). Files requested
and read: `config/routes.rb`, `app/models/storage_location.rb`,
`app/models/owner.rb`, `app/controllers/software_items_controller.rb`
(closest precedent for owner-scoped resourceful CRUD),
`app/helpers/software_items_helper.rb`, all 5 `software_items` views,
`app/views/admin/site_texts/delete_confirm.html.erb` (the named precedent
for a nullify-warning delete confirmation), `app/views/common/
_navigation.html.erb`, `test/controllers/software_items_controller_test.rb`,
`test/fixtures/storage_locations.yml` / `software_items.yml` / `owners.yml`,
`test/support/authentication_helper.rb`, and `test/test_helper.rb`.

### Real finding from reading the actual files — a design mismatch, flagged rather than guessed through

`storage_location.rb` v1.0's own header comment (written in Session 79)
states the owner-facing delete confirmation "must warn with counts before
the destroy happens (see Session B)." Reading `admin/site_texts/
delete_confirm.html.erb` (the named precedent) confirmed it's built around
a "pick which record from a list" selector pattern, not a "confirm deleting
THIS one record with a warning about what else it affects" pattern —
neither of which resolves the deeper issue: `StorageLocation` has no
`has_many :computers` / `:components` / `:software_items` association at
all yet (deliberately deferred to Session C in Session A). There is
genuinely nothing to count in Session B.

This was flagged explicitly to Ulli before implementing delete_confirm,
rather than either (a) fabricating count logic against associations that
don't exist, or (b) silently building a different design than the plan
called for without saying so. **Ulli's instruction: "Do what you think is
appropriate."** Decision made: `delete_confirm.html.erb` shows a plain,
honest "are you sure" confirmation with no counts. Both the controller
(`storage_locations_controller.rb`'s class-level comment) and the view
carry explicit comments stating this is interim and that Session C must
replace it with a real counts warning once the associations exist.

### Access model — stricter than the SoftwareItem precedent it otherwise follows

`SoftwareItemsController` has a public index/show with owner-scoped
mutations only. `StorageLocationsController` requires login on EVERY
action, including `index` — matching the Session 79 design consultation's
confirmed answer ("Private from other owners AND visitors"). No `:show`
action (routes.rb `except: [:show]`) — a `StorageLocation` carries only a
`name`, so the index list is the only display surface needed. No
pagination — an owner's own list is expected to stay small, unlike the
sitewide public Computer/Component/SoftwareItem indexes that need
`geared_pagination`.

### Files delivered (10)

    decor/config/routes.rb                                            v3.7 → v3.8
    decor/app/controllers/storage_locations_controller.rb            NEW (v1.0)
    decor/app/views/storage_locations/index.html.erb                  NEW (v1.0)
    decor/app/views/storage_locations/_storage_location.html.erb     NEW (v1.0)
    decor/app/views/storage_locations/new.html.erb                    NEW (v1.0)
    decor/app/views/storage_locations/edit.html.erb                   NEW (v1.0)
    decor/app/views/storage_locations/_form.html.erb                  NEW (v1.0)
    decor/app/views/storage_locations/delete_confirm.html.erb         NEW (v1.0)
    decor/app/views/common/_navigation.html.erb                       v2.7 → v2.8
    decor/test/controllers/storage_locations_controller_test.rb      NEW (v1.0)

Delivered via the File Transfer Protocol's export/import script pattern —
a placement script (`place_session_b_files.sh`) was generated alongside the
10 @-encoded files, correctly following COMMON_BEHAVIOR.md's multi-file
delivery rule (no repeat of the Session 78/79 process misses where a
plain-prose file request/delivery was used instead of the script).

### Nav placement

"My Storage Locations" added to the existing right-side username dropdown
(`common/_navigation.html.erb`), after "My Software" and before the
Profile divider — the placement confirmed in the Session 79 design
consultation ("Right of the logo, in the existing right-side flex group
... safe to do without re-triggering the old grid-overflow bug, since
Session 78 already took the logo out of the grid/flex flow entirely").
Uses a plain `storage_locations_path` (no argument), unlike the other
"My X" links (`computers_owner_path(Current.owner)` etc.) — this resource
is not nested under `owners/:id`; the controller scopes to `Current.owner`
internally instead.

### Test Coverage Check (per PROGRAMMING_GENERAL.md)

    New server-side logic this session:
      StorageLocationsController (7 actions)   — yes, tested: login guard on
                                                  every action, ownership guard
                                                  on edit/update/destroy/
                                                  delete_confirm, success path
                                                  on every action; create/update
                                                  also cover blank-name
                                                  rejection and the per-owner-
                                                  scoped uniqueness validation
                                                  (duplicate name for the SAME
                                                  owner rejected; duplicate name
                                                  for a DIFFERENT owner allowed)
      _navigation.html.erb link addition        — view-only, no test needed
      routes.rb                                  — covered implicitly (any
                                                  routing mistake fails every
                                                  controller test)

No model-level changes this session — `storage_location.rb` is untouched
from Session A; its validations already have model-test coverage.

### Pre-commit checklist and deployment — all confirmed complete by Ulli

    [x] Placement (place_session_b_files.sh)
    [x] bin/rails test
    [x] bundle exec rubocop -A / bundle exec rubocop
    [x] bin/brakeman --no-pager
    [x] bundle exec bundle-audit check --update
    [x] Manual browser check
    [x] git workflow: branch → commit → push → PR → CI → merge
    [x] Deployed

### Rule/skill document updates this session (session wrap-up, per Ulli's explicit "wrap up when all for session B is done")

    decor/docs/claude/DECOR_PROJECT.md       v2.70 → v2.71 (this session's changelog +
                                                             Session B marked DONE in the
                                                             Storage Locations Session Plan +
                                                             Key file versions entries +
                                                             Data Model Overview update)
    decor/docs/claude/SESSION_HANDOVER.md    v80.0 → v81.0 (this summary + status update +
                                                             two banner application notes)

No COMMON_BEHAVIOR.md, RAILS_SPECIFICS.md, or PROGRAMMING_GENERAL.md
changes this session — the delete_confirm decision is feature-specific
(tracked in DECOR_PROJECT.md's Storage Locations Session Plan, not as a
project-wide MANDATORY rule), and every technical pattern applied
(before_action only: scoping, assert_body_includes, File Transfer Protocol
script usage, data-turbo="false" avoidance) followed rules that already
exist rather than surfacing a new one.

### NOT YET DONE — Sessions C–F

Storage Locations Session C (FK + forms + show pages, plus upgrading
Session B's delete_confirm to show real counts), D (privacy audit), E
(filters), F (export/import) are fully designed (see DECOR_PROJECT.md) but
not started. Pick up with Session C next.

---

## Session 79 Summary — Storage Locations feature: design consultation + Session A implemented and deployed

### Design consultation

Ulli proposed a new feature: owners define private physical storage
locations for their collection items. Seven open questions were raised
before any code was written (FK vs. free text, column length/description,
flat vs. hierarchical, dedicated CRUD vs. inline creation, delete
behaviour, admin visibility, filter-sidebar scope) — all answered by Ulli
over the course of the discussion, plus two follow-ups (import auto-create
behaviour for an unrecognised name; nav placement, resolved cleanly by
Session 78's earlier logo-decoupling fix meaning the new link could go in
the right-side flex group without reopening the old grid-overflow bug).

Implementation was split into 6 independent, individually-committable
sessions (A–F) — same reasoning as the Software feature (Sessions 43–48)
and Component Suggestions (Phases 1–4): each session ships something
deployable on its own, with an explicit dependency graph so future
sessions know what must precede what. Full confirmed design and all 6
sessions' file lists: **DECOR_PROJECT.md, "Storage Locations Feature —
Session Plan."**

### Session A — implemented, tested, and deployed this same session

    decor/db/migrate/20260727000100_create_storage_locations.rb   NEW (v1.0)
    decor/app/models/storage_location.rb                          NEW (v1.0)
    decor/app/models/owner.rb                                     v1.6 → v1.7
    decor/test/fixtures/storage_locations.yml                     NEW (v1.0)
    decor/test/models/storage_location_test.rb                    NEW (v1.0)

Pre-Implementation Verification was done before writing any of these:
`owner.rb`, `connection_group.rb` (closest existing precedent for an
owner-scoped model with per-owner uniqueness), the actual
`create_component_suggestions` migration (to match this project's real
`create_table` conventions rather than generic Rails ones), `owners.yml`,
`connection_groups.yml`, `connection_group_test.rb`, and `test_helper.rb`
were all requested and read first, via the File Transfer Protocol export
script (multi-file request — correctly used the script this time, no
repeat of the Session 78 process miss).

**One real finding from reading the actual migration:** the
`component_suggestions` migration does NOT add a CHECK constraint
alongside its `VARCHAR`/`limit:` column — length is enforced at the Rails
model-validation level only. This is followed for `storage_locations.name`
too, in preference to the more general SQLite CHECK-constraint guidance
elsewhere in RAILS_SPECIFICS.md — the actual precedent in the codebase
takes priority over the general rule, per Never-Guess.

**`owner.rb` bump not originally itemised:** the Session A file list (as
first proposed) was migration + model + fixtures + test only. Adding
`has_many :storage_locations, dependent: :destroy` to `owner.rb` was
recognised as necessary once actually writing the model — `owner.
storage_locations` wouldn't otherwise exist — and added to the delivery
rather than left as a gap.

**`StorageLocation` deliberately incomplete for now:** no
`has_many :computers/:components/:software_items` yet — those FK columns
don't exist on the referencing tables until Session C's migration runs.
Adding the associations early would generate SQL against nonexistent
columns. Documented in the model's own header comment so this isn't
mistaken for an oversight in a future session.

### Process note this session

A file-delivery-protocol miss, caught by Ulli rather than self-caught: the
File Transfer Protocol's export script for the Pre-Implementation
Verification files was correctly generated, but the very first
multi-file *delivery* of this session (the export script itself) was
initially just shown in a code block instead of being created as an actual
file and presented via `present_files`, violating the existing "Always
Present Files for Download" rule. Corrected immediately once flagged — no
new rule needed, this was a plain miss of an existing rule.

### Test Coverage Check (per PROGRAMMING_GENERAL.md)

    New server-side logic this session:
      StorageLocation model (validations)   — yes, tested: presence, length
                                               boundary (50/51), per-owner
                                               uniqueness, belongs_to owner
      Owner#storage_locations association   — covered implicitly by the
                                               belongs_to test
      Migration                              — no logic to unit test;
                                               verified by running it

### Pre-commit checklist and deployment — all confirmed complete by Ulli

    [x] bin/rails db:migrate
    [x] bin/rails test (full suite)
    [x] bundle exec rubocop -A / bundle exec rubocop
    [x] bin/brakeman --no-pager
    [x] bundle exec bundle-audit check --update
    [x] git workflow: branch → commit → push → PR → CI → merge
    [x] Deployed

### Rule/skill document updates this session (session wrap-up, per Ulli's explicit "wrap up")

    decor/docs/claude/DECOR_PROJECT.md       v2.69 → v2.70 (this session's changelog +
                                                             new "Storage Locations Feature
                                                             — Session Plan" section +
                                                             StorageLocation added to Data
                                                             Model Overview + Key file
                                                             versions entries)
    decor/docs/claude/SESSION_HANDOVER.md    v79.0 → v80.0 (this summary + status update +
                                                             one new banner entry)

No COMMON_BEHAVIOR.md, RAILS_SPECIFICS.md, or PROGRAMMING_GENERAL.md
changes this session — the file-presentation miss above was a violation of
an existing rule, not a gap needing a new one, and every technical decision
made (CHECK-constraint precedent, association deferral, delete/nullify
design) followed patterns already documented rather than surfacing a new
one.

### NOT YET DONE — Sessions B–F

Storage Locations Sessions B (owner CRUD), C (FK + forms), D (privacy
audit), E (filters), F (export/import) are fully designed (see
DECOR_PROJECT.md) but not started. Pick up with Session B next.

---

## Session 78 Summary — Admin dropdown siblings fix, Owner Part Number on Connection form, real nav-centering fix

Three independent items, each following full Pre-Implementation
Verification (actual files requested and read before any fix was written).

### Item 1 — dropdown_controller.js: admin dropdowns don't close each other (Session 77's carried-over open item)

Diagnosed by reading `decor/app/javascript/controllers/dropdown_controller.js`
v1.0 and `decor/app/views/layouts/admin.html.erb` v2.8 (both requested at
the end of Session 77). Confirmed: every admin nav dropdown is an
independent `data-controller="dropdown"` Stimulus instance with no shared
state — opening one had zero effect on any other already-open one.

Fixed entirely within `dropdown_controller.js` — **no `admin.html.erb`
change needed**, since every dropdown there already shares the identical
structure this fix relies on. When a dropdown is about to open, it
dispatches a `dropdown:open` CustomEvent on `document` carrying its own
root element as `detail.source`; every instance listens for that event and
closes itself unless it is the source.

    decor/app/javascript/controllers/dropdown_controller.js    v1.0 → v1.1

No automated test — pure Stimulus/JS behavior, no server-side logic (per
PROGRAMMING_GENERAL.md's Test Coverage Check). A system test could cover
this but would mean opening the currently-deferred System Tests Track 2;
not started this session.

### Item 2 — connection_groups/_form.html.erb: Device dropdown missing Owner Part Number

Reported from `/owners/1/connection_groups/new`. Confirmed via
`connection_groups/_form.html.erb` v1.2 that the Device `<select>`'s option
label (`"#{model} – SN #{serial} (#{device_type})"`) never included
`owner_part_number` — same class of gap as the Session 76
`components/_form.html.erb` fix, just never applied here. Added between
DEC Serial Number and the device_type parenthetical, matching this file's
own dash-separated label style (not the slash-separated style used in
`components/_form.html.erb` — different file, different established
convention, not imported wholesale).

**Fixed in BOTH places this label is built** — the persisted-row
`f.fields_for` loop's `mf.select`, AND the server-rendered `<template>`
block used by `connection_members_controller.js`'s `add` action for new
rows. Confirmed via reading `connection_members_controller.js` v1.1 that it
has no device-label logic of its own (it only clones the template), so no
JS change was needed — but the two ERB copies of the label had to be kept
in sync by hand, as documented in the file's own new changelog comment.

    decor/app/views/connection_groups/_form.html.erb    v1.2 → v1.3

No automated test — view-only option-label text change, no server logic.

### Item 3 — common/_navigation.html.erb: real bug behind a misdiagnosed report

Reported: "the New connection group page content is not centered."
`connection_groups/new.html.erb` was read FIRST (per Never-Guess) and
confirmed already correct (`max-w-2xl mx-auto`, and
`layouts/application.html.erb`'s `<main>` has no competing width
constraint that would prevent that from centering). The actual bug was in
`common/_navigation.html.erb`: the edge-to-edge `<nav>` (no max-width
wrapper at all) centered its logo inside a `grid-cols-[auto_1fr_auto]`
middle column — which only centers within the space left over between the
two flanking groups, and those groups are NOT equal width (7 left-side
links vs. 2-3 right-side items). The logo sat visibly right of true
viewport-center, making every genuinely-centered page (including the one
actually reported) look wrong by comparison.

Fixed by taking the logo out of the grid/flex flow: `<nav>` is now
`relative`, logo wrapper is `absolute left-1/2 -translate-x-1/2` — centers
on `<nav>`'s own full width (the whole viewport) regardless of left/right
group widths. Left/right groups changed from the 3-column grid to a plain
`flex justify-between` container, since the grid's middle column is no
longer needed. New MANDATORY RAILS_SPECIFICS.md v3.14 section added: "Nav
Logo Centering — A 1fr Grid/Flex Middle Column Centers on Leftover Space,
Not the Viewport."

    decor/app/views/common/_navigation.html.erb    v2.6 → v2.7

No Tailwind rebuild needed — `relative`, `absolute`, `left-1/2`,
`-translate-x-1/2`, `justify-between` are all already-used-elsewhere or
standard utility classes, not new arbitrary values.

### Process note this session

A file-transfer-protocol miss, caught by Ulli rather than self-caught: a
2-file request (`connection_groups/_form.html.erb` +
`connection_members_controller.js`) was initially made as a plain "please
upload these two files" ask instead of generating the mandatory export
script COMMON_BEHAVIOR.md already requires for multi-file transfers.
Corrected immediately once flagged — no new rule needed, this was a plain
miss of an existing rule, not a gap in the rule itself.

### Rule/skill document updates this session (session wrap-up, per Ulli's explicit "wrap up now, we're at 90% of our token limit")

    decor/docs/claude/RAILS_SPECIFICS.md     v3.13 → v3.14 (new MANDATORY section:
                                                             nav logo centering)
    decor/docs/claude/SESSION_HANDOVER.md    v78.0 → v79.0 (this summary + status
                                                             update + one new banner)
    decor/docs/claude/DECOR_PROJECT.md       v2.68 → v2.69 (this session's changelog +
                                                             new Session 78 section +
                                                             Key file versions entries)

No COMMON_BEHAVIOR.md or PROGRAMMING_GENERAL.md rule changes this session
— the file-transfer-protocol miss above was a violation of an existing
rule, not a gap needing a new one.

### NOT YET DONE — required before Session 78's work is fully closed out

    [ ] Place all 3 files: dropdown_controller.js, connection_groups/_form.html.erb,
        common/_navigation.html.erb
    [ ] bin/rails test
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check: (a) admin dropdowns close their siblings when a
        new one opens, across several pairs; (b) Connection form Device
        dropdown shows Owner Part Number for both existing and newly-added
        (+ Add port) rows; (c) nav logo now sits at true page-center on
        every page, and left/right nav groups still render correctly at
        normal and narrow widths
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy
    [ ] This session's items should be committed together with Session 77's
        still-open 8 files (see "Session 77 Summary" below) if not already
        done separately

---

## Session 76 Summary — Component/Peripheral dropdown fixes, Tom Select sort bug, CI stale-element test fix

**Session opened with Ulli confirming Sessions 73 and 75 are both now
checked and deployed** — see the updated Date/Branch/Status block above.
That resolves both previously-open NOT YET DONE checklists; neither is
restated here.

### Item 0 — computers/new.html.erb v1.6 redelivered (placement confusion from Session 75)

Ulli reported the Session 75 required-fields text fix "looks like it
wasn't done." Investigation showed the file was still v1.5 on disk — v1.6
had been delivered at the end of Session 75 but never actually placed into
the real project. Redelivered unchanged as v1.6; no code difference from
what Session 75 already specified.

    decor/app/views/computers/new.html.erb    (redelivered, still v1.6)

### Item 1 — components/_form.html.erb: Computer/Peripheral dropdown, four rounds of fixes (v1.13 → v1.17)

Reported: (a) the Row 1 dropdown label said "Computer Model" even though a
Component can belong to either a Computer or a Peripheral; (b) the
dropdown's option text didn't show Owner Part Number, which can be the
only field distinguishing two otherwise-identical devices.

    v1.14 — Label renamed "Computer Model" → "Computer/Peripheral". Owner
            Part Number added to the combined option label, positioned
            between DEC Part Number and DEC Serial Number to match this
            same file's established Row 2 field order for Components.
    v1.15 — Two more instances of the old "computer"-only wording (the
            select's include_blank text, and the helper <p> text below the
            field) updated for consistency — per an initial instruction
            that used "peripheral/computer" word order.
    v1.16 — Two follow-up fixes: (1) word order corrected back to
            "Computer/Peripheral" (Ulli caught the reversal from v1.15);
            (2) the option label's closing ")" no longer fit in the
            column now that it has four segments — Row 1's grid changed
            from `grid-cols-3` to the arbitrary `grid-cols-[3fr_2fr_2fr]`
            (a 3:2:2 ratio — first column 1.5x/50% wider than the other
            two, which don't need the space). Required a Tailwind rebuild;
            flagged proactively per RAILS_SPECIFICS.md's existing rule.
    v1.17 — Two "Auto-filled from the selected computer." helper texts
            (under the read-only Computer DEC Part/Serial Number fields)
            shortened to "Auto-filled from the selected device." — Ulli's
            own choice of wording, shorter than repeating
            "computer/peripheral" and no column-width constraint here.

No controller/helper/model files needed changes — the dropdown's option
list is built entirely inline in `_form.html.erb`; `computer.rb`,
`components_controller.rb`, and `components_helper.rb` were read to confirm
this (`owner_part_number` accessor, strong params, no helper involvement)
but none required edits.

### Item 2 — tom_select_controller.js v1.0 → v1.1: dropdown sort order bug (project-wide)

Reported: the Computer Model dropdown on `/computers/new` wasn't sorted
alphabetically, before or after typing. Root cause was NOT the Rails query
(`ComputerModel.where(...).order(:name)` in `computers/_form.html.erb` was
already correct) — it was `tom_select_controller.js`'s `sortField: false`,
present since the controller's creation in Session 54. `false` isn't a
valid Tom Select option value; Tom Select fell back to enumerating options
by internal object key, and since `collection_select` option values are
numeric ids, JavaScript always enumerates integer-like keys in ascending
numeric order — so every Tom Select dropdown was silently sorted by
database id, not name. Fixed with an explicit
`sortField: { field: "text", direction: "asc" }`. Fixes all three selects
using this shared controller (Computer Model, Condition, Run Status) — the
smaller two lists likely looked correct by coincidence. Codified as a new
MANDATORY RAILS_SPECIFICS.md v3.12 section.

    decor/app/javascript/controllers/tom_select_controller.js   v1.0 → v1.1

### Item 3 — software_items_filters_test.rb v1.1 → v1.2: CI-caught StaleElementReferenceError

`gh pr checks feature/bug_fixing_3` showed `CI/Tests (System)` failing
(Lint, Security (JS), Security (Ruby), and Unit all green). The actual
failure log (`gh run view <run-id> --log-failed`) showed
`Selenium::WebDriver::Error::StaleElementReferenceError` in
`SoftwareItemsFiltersTest#test_selecting_an_owner_id_adds_it_to_the_URL`.
Confirmed via the actual owner_id `_filters.html.erb` markup that this
selector is a plain `form.select` — no Tom Select involvement, so this was
unrelated to Item 2. Root cause: the test read `first_option.text` in the
same statement as the post-navigation assertion, after `click_button
"Apply"` had already navigated the page via Turbo (which replaces the
DOM) — a stale element reference. Two sibling tests in the same file
(`software_name_id`, `barter_status`) shared the identical pattern and
identical latent risk, confirming this is timing-dependent rather than
specific to the `owner_id` field. Fixed all three by capturing
`expected_text = first_option.text` as a plain string BEFORE the click, and
asserting against that string. Codified as a new MANDATORY
RAILS_SPECIFICS.md v3.12 addendum under the existing Capybara Assertion
Patterns section.

    decor/test/system/software_items_filters_test.rb   v1.1 → v1.2

**Not yet confirmed committed at time of writing** — commands for the
commit/push/re-check/merge cycle were given; Ulli had not yet confirmed
completion when this session closed.

### Rule/skill document updates this session (session wrap-up)

    decor/docs/claude/RAILS_SPECIFICS.md     v3.10 → v3.12 (Tom Select sortField rule;
                                                             Capybara stale-element addendum)
    decor/docs/claude/SESSION_HANDOVER.md    v76.0 → v77.0 (this summary + status update +
                                                             two new banner entries)
    decor/docs/claude/DECOR_PROJECT.md       v2.66 → v2.67 (this session's changelog +
                                                             Key file versions entries)

No COMMON_BEHAVIOR.md or PROGRAMMING_GENERAL.md changes this session — no
new workflow/behavioral lessons, only Rails/JS-technical ones.

### NOT YET DONE — required before Session 76's work is fully closed out

    [ ] Confirm software_items_filters_test.rb v1.2 placed, committed, and pushed
        to feature/bug_fixing_3
    [ ] Confirm gh pr checks feature/bug_fixing_3 shows all green on the new commit
        (not a stale re-display of the prior failing run)
    [ ] gh pr merge --merge feature/bug_fixing_3
    [ ] git switch main && git pull origin main && git branch -d feature/bug_fixing_3
    [ ] Deploy (kamal deploy or equivalent), per this project's established
        post-merge step

---

## Session 75 Summary — Three UI bug fixes: RESOLVED Session 76 (confirmed checked and deployed)

> **Resolved Session 76:** Ulli confirmed at the start of Session 76 that
> this session's three bug fixes (computers/new.html.erb v1.6,
> components/_form.html.erb v1.13, computers/show.html.erb v2.3) are now
> fully tested, lint/security-scanned, committed, and deployed. The full
> original summary below is preserved as historical record; its NOT YET
> DONE checklist no longer applies.

Three independent, unrelated small bugs reported and fixed. No migrations,
no new server-side logic — all view/markup/CSS fixes, confirmed via
PROGRAMMING_GENERAL.md's Test Coverage Check to need no new automated tests
(view layout / static text changes only).

### Bug 1 — computers/new.html.erb: stale required-fields notice text

The notice still read "Required fields: [Model] and DEC Serial Number" —
stale since Session 70's Owner Part Number feature made both
`serial_number` and `owner_part_number` default to `"-"` via
`before_validation` rather than being hard-required individually. Updated
to "...and at least one of DEC Serial Number and Owner Part Number,"
reflecting the actual constraint that matters (the combined uniqueness
scope). The two sentences were already plain flowing text with no
`white-space: nowrap`, so the second sentence already wraps onto its own
line naturally whenever both don't fit on one — no markup change needed
for that part, only the text itself.

    decor/app/views/computers/new.html.erb    v1.5 → v1.6

### Bug 2 — components/_form.html.erb: Row 2 field misalignment

At `grid-cols-5` width, three of the five Row 2 labels ("Component DEC Part
Number", "Component Owner Part Number", "Component DEC Serial Number")
wrapped onto two lines while the other two ("Component Type", "Run Status")
stayed on one line — pushing only those three inputs down and leaving the
row visually staggered. (Diagnosed correctly only after a screenshot; an
initial hypothesis — Tom Select's JS widget not matching `field_classes`
height — turned out not to be needed once the actual screenshot showed the
real cause was label wrapping, not Tom Select.) Fixed by giving every Row 2
label `flex items-end min-h-[2.5rem]` — a fixed two-line-tall box with the
label text bottom-anchored inside it, so every input starts at the same y
regardless of how many lines its own label wrapped to.

**This fix required a Tailwind rebuild to take effect** (`min-h-[2.5rem]`
and `items-end` were new classes for this project) — the user placed the
file but didn't rebuild initially, causing a "still looks broken" report
that cost a full round-trip before the missing rebuild step was identified.
This prompted RAILS_SPECIFICS.md v3.9's new mandatory Tailwind-rebuild
reminder rule (see below).

    decor/app/views/components/_form.html.erb    v1.12 → v1.13

### Bug 3 — computers/show.html.erb: missing Owner Part Number + wrong Model label

Same root cause as several prior sessions' single-source-of-truth gaps:
this show page was never updated alongside Sessions 70/71/74's
`_form.html.erb` fixes (v2.7 → v2.9). Two consequences, both fixed:
1. Line 1 was still `grid-cols-3` (Model | DEC Part Number | DEC Serial
   Number) with no Owner Part Number field at all. Widened to
   `grid-cols-4`, matching `_form.html.erb` v2.9's field ORDER exactly
   (Owner Part Number placed *after* DEC Serial Number — confirmed by
   reading the actual form file rather than assuming the
   `components/_form.html.erb` ordering, which places it *between* DEC
   Part/Serial Number, carried over).
2. The Model `<dt>` label was hardcoded "Computer Model" even for
   peripherals. Fixed to `@computer.device_type.capitalize` + " Model",
   matching the pattern `_form.html.erb` v2.9 and `new.html.erb` v1.5
   already use.

**A self-introduced bug during this fix's own delivery, caught and
corrected the same turn (not by the user):** the changelog comment
describing bug 3's second fix embedded a literal `<%= @computer.device_type
.capitalize %>` snippet inside a `<%# %>` ERB comment. ERB comments close
at the *first* `%>` encountered, with no awareness of nested tags — the
comment terminated early and the trailing text (`Model", matching the exact
%>`) rendered as literal, visible page text directly below the nav bar in
production. The user reported this after placing the file. Fixed by
rewriting the comment in plain prose with no embedded ERB delimiters, and
verified via `grep -n '<%#.*<%='` that no other instance of this pattern
existed anywhere else in the file. Codified as RAILS_SPECIFICS.md v3.10's
new mandatory rule, including the exact grep command to check before
delivering any `.erb` file with a changelog comment describing code.

    decor/app/views/computers/show.html.erb    v2.2 → v2.3

### Two file-delivery-convention mistakes, corrected at the user's explicit instruction (not self-caught)

1. **Rule/skill documents updated mid-session, unprompted.** After fixing
   the Tailwind-rebuild gap, RAILS_SPECIFICS.md and SESSION_HANDOVER.md
   were both updated and delivered immediately — an unprompted "wrap up
   now" while the actual project work (placing/testing the already-fixed
   view files) was still open and hadn't been asked about. The user pointed
   this out directly. Fixed going forward: COMMON_BEHAVIOR.md v3.2's new
   "Rule/Skill Document Updates — Timing" rule (see that file for detail).
2. **Rule/skill documents @-encoded when delivered alone.** The same two
   files were delivered with @-encoded flat filenames
   (`docs@claude@RAILS_SPECIFICS@md`, etc.) even though they were delivered
   without any other project files — no collision risk existed, and the
   user had to rename them back before use. This same mistake recurred
   later in the session with `computers/show.html.erb` (delivered as
   `app@views@computers@show@html.erb` for a single-file delivery) before
   being corrected. Fixed going forward: COMMON_BEHAVIOR.md v3.2's new File
   Transfer Protocol exception for rule/skill documents delivered alone —
   plain filename, no script. (The `show.html.erb` recurrence was a
   pre-existing single-file-delivery rule Claude already had and simply
   didn't follow correctly that turn — not a gap needing a new rule.)

### Rule/skill document updates this session (all at the user's explicit
### request, or — for the ERB comment rule below — at actual session
### wrap-up, per the new timing rule this session itself introduced)

    decor/docs/claude/COMMON_BEHAVIOR.md     v3.1 → v3.2  (two new rules — see above)
    decor/docs/claude/RAILS_SPECIFICS.md     v3.8 → v3.10 (Tailwind rebuild rule, v3.9;
                                                            ERB comment rule, v3.10)
    decor/docs/claude/SESSION_HANDOVER.md    v74.0 → v76.0 (Tailwind banner, v75.0;
                                                             this full summary + status
                                                             update, v76.0)
    decor/docs/claude/DECOR_PROJECT.md       v2.65 → v2.66 (this session's changelog +
                                                             Key file versions entries)

### NOT YET DONE — RESOLVED Session 76

All items below were confirmed complete by Ulli at the start of Session 76
(placed, tested, linted, security-scanned, committed, merged, deployed).
Preserved as historical record of what the checklist originally required:

    [x] Place all three delivered files into the actual project
    [x] bin/rails test
    [x] bundle exec rubocop -A / bundle exec rubocop
    [x] bin/brakeman --no-pager
    [x] bundle exec bundle-audit check --update
    [x] git workflow: branch → commit → push → PR → CI → merge → deploy

Note: Session 73's Category Help Pages checklist (see "Session 73 Summary"
below) was a SEPARATE item — also confirmed resolved by Ulli at the start
of Session 76.

---

## Session 73 Summary — Category Help Pages feature: RESOLVED Session 76 (confirmed checked and deployed)

> **Resolved Session 76:** Ulli confirmed at the start of Session 76 that
> this feature is now fully tested, lint/security-scanned, committed, and
> deployed. The full original summary below is preserved as historical
> record; its NOT YET DONE checklist no longer applies.

**5 new owner-facing help pages (Computers, Peripherals, Components,
Connections, Software), built entirely on top of the existing `SiteText`
generic text-page subsystem. No migration.** 7 files delivered (5
production, 2 test).

### What this request turned out to need

Before writing anything, `decor/app/models/site_text.rb`,
`decor/app/controllers/site_texts_controller.rb`,
`decor/app/controllers/admin/site_texts_controller.rb`,
`decor/config/routes.rb`, `decor/app/views/common/_navigation.html.erb`,
`decor/app/views/layouts/admin.html.erb`, the three
`decor/app/views/admin/site_texts/*.html.erb` views,
`decor/app/views/site_texts/show.html.erb`, `decor/db/schema.rb`, and
`decor/test/controllers/admin/site_texts_controller_test.rb` were all
requested and read directly (Never-Guess / Pre-Implementation
Verification — via the File Transfer Protocol export script). This
confirmed `SiteText` is a generic `key`/`content` model whose `KNOWN_TEXTS`
constant is the actual single source of truth driving every admin
selector — meaning the 5 new pages needed no schema change at all, just 5
new `KNOWN_TEXTS` entries + 5 new routes + 5 new nav links.

**Also surfaced a real documentation gap while reading:** `SiteText` had
never appeared anywhere in DECOR_PROJECT.md's "Data Model Overview" despite
existing since Session 18 — the same shape of gap as the still-open Session
68 issue (see GAP NOTICE above), just for a different model. Closed this
one: added a full "SiteText" entry to DECOR_PROJECT.md's Data Model
Overview this session.

### Two pre-existing bugs found and fixed (not new bugs from this session's own additions)

1. **`site_texts_controller.rb` (owner-facing) — stale `title_for_key`.**
   Session 20 introduced `SiteText.title_for_key` / `KNOWN_TEXTS` as the
   single source of truth for page titles, but that refactor only touched
   the admin controller — the owner-facing controller kept its own private
   `title_for_key` hash with only `"readme"` hardcoded, falling back to
   `key.titleize` otherwise. This coincidentally produced correct output for
   the 4 pre-existing keys (`.titleize` of "news"/"barter_trade"/"privacy"
   happens to match their configured titles) but would have shipped the
   WRONG title for the new pages (`"help_computers".titleize` → "Help
   Computers", not "Computers Help"). Fixed (v1.1) by deleting the private
   method and delegating to `SiteText.title_for_key`.
2. **`admin/site_texts_controller.rb` — hardcoded `url_for_key` case
   statement.** Required manual editing every time a `KNOWN_TEXTS` entry was
   added — the same "touch N places, miss one" trap as the Session 64
   admin-nav-menu gap and the Session 68 documentation gap. Every existing
   route's `as:` name is identical to its key, so this was generalized
   (v1.3) to a single `send("#{key}_path")` call, rescuing `NoMethodError`
   back to `root_path`. No future `KNOWN_TEXTS` addition should need to
   touch this file again for this purpose.

Both were caught by actually reading the files rather than assuming the
Session 20 refactor had been applied everywhere — see DECOR_PROJECT.md
"Category Help Pages Feature — Session 73" for the full write-up.

### New keys, titles, routes

    Key                  Title                Route helper
    help_computers       Computers Help       help_computers_path
    help_peripherals     Peripherals Help     help_peripherals_path
    help_components      Components Help      help_components_path
    help_connections     Connections Help     help_connections_path
    help_software        Software Help        help_software_path

Owner-facing: new links in the "Info" dropdown (`_navigation.html.erb`),
below a new divider separating them from the 4 pre-existing general-info
links; dropdown widened `w-36` → `w-48` (the new labels are longer than any
existing entry and would wrap at the old width). Admin-facing: **zero
changes needed** to `admin.html.erb`'s "Texts" dropdown or any of the three
admin `site_texts` views — all already iterate `KNOWN_TEXTS` generically, so
the 5 new entries appear automatically in Upload/Download/Delete.

### Files delivered (7: 5 production, 2 test; 0 migrations)

    decor/app/models/site_text.rb                            v1.1 → v1.2
    decor/app/controllers/site_texts_controller.rb            v1.0 → v1.1
    decor/app/controllers/admin/site_texts_controller.rb      v1.2 → v1.3
    decor/config/routes.rb                                    v3.6 → v3.7
    decor/app/views/common/_navigation.html.erb                v2.4 → v2.5
    decor/test/controllers/admin/site_texts_controller_test.rb v1.1 → v1.2
    decor/test/controllers/site_texts_controller_test.rb      NEW (v1.0)

### Test Coverage Check (per PROGRAMMING_GENERAL.md, offered proactively)

`site_texts_controller_test.rb` had never existed for the owner-facing
controller — flagged and written from scratch (3 tests: content render,
empty-placeholder path, and a regression test specifically proving the
`title_for_key` fix using the `help_computers` key). The admin controller
test file was extended with 2 new tests that deliberately use
`help_computers` — a key the OLD hardcoded `case` statement never
special-cased — so a regression back to the old code, or a typo in the new
`send("#{key}_path")` call, would fail these specific tests even though
tests against the 4 pre-existing keys would still pass. `site_text.rb`
(data-only change) and `_navigation.html.erb` (view/CSS only) needed no new
tests.

### Open item raised, not yet resolved

Whether `render_markdown` (in `application_helper.rb`, not reviewed this
session) enables Redcarpet's `:with_toc_data` extension — required for
Markdown header `id=` attributes, which in turn is required for in-page
anchor links (e.g. `[Trade Status](#trade-status)`) to work on any of the 5
new help pages. Raised when Ulli asked how to link to a multi-word Markdown
header; answered the general Markdown convention (lowercase, hyphenated)
but flagged that whether it actually works here depends on a file not yet
reviewed. Worth checking during the manual browser check below if any new
page is written with an in-page table of contents.

### NOT YET DONE — RESOLVED Session 76

All items below were confirmed complete by Ulli at the start of Session 76.
Preserved as historical record:

    [x] Place the 7 delivered files into the actual project
    [x] Upload actual Markdown content for the 5 new keys
    [x] bin/rails test
    [x] bundle exec rubocop -A / bundle exec rubocop
    [x] bin/brakeman --no-pager
    [x] bundle exec bundle-audit check --update
    [x] Manual browser check
    [x] git workflow: branch → commit → push → PR → CI → merge → deploy

---

## Session 72 Summary — CI Security fix, merge/deploy; Sessions 67–70 confirmed committed

**Ulli confirmed Sessions 67 (Component Suggestions Phase 4), 68 (UI
refinements — code live, formal summary still missing, see GAP NOTICE), 69
(UI Terminology Rename), and 70 (Owner Part Number) were ALL already
committed/pushed/merged/deployed to `main`** — this simply hadn't been
communicated to Claude in prior sessions. All "sitting locally,
uncommitted" language elsewhere in this document describing those four
sessions is stale as of this point.

**This session's own work:** the `feature/owner_part_number` PR's `CI/
Security (Ruby)` check failed post-migrate/test/lint/Brakeman. Correctly
diagnosed as `bundle-audit` (not Brakeman) via the actual CI log — 4 gems
batch-flagged (`loofah` → >= 2.25.2, `rails-html-sanitizer` → >= 1.7.1,
`sqlite3` → >= 2.9.5, `websocket-driver` → >= 0.8.2). Fixed with `bundle
update`, confirmed clean locally, re-pushed, merged (`gh pr merge --merge`),
deployed (`kamal deploy`).

**Net result:** Sessions 67, 68 (code), 69, 70 all confirmed live on `main`.
The only item still open afterward: Session 68's missing formal
documentation summary (paper-trail gap only — see GAP NOTICE above; the
code itself needs no further action).

---

## Session 70 Summary — Owner Part Number feature: IMPLEMENTED (resolved Session 72)

> **Resolved Session 72:** migrated, tested, lint/security-scanned, committed,
> merged, deployed — see "Session 72 Summary" above.

Implemented all 3 open design questions from Session 69 (11 of 12 files;
`schema.rb` regen completed via Session 72's `db:migrate` run):

1. **Uniqueness scope** kept the existing model/type dimension —
   `(owner, computer_model/component_type, owner_part_number, serial_number)`.
2. **Presence + defaulting** made symmetric across both models/fields — both
   default to `"-"` via `before_validation` (not `before_save` — see
   RAILS_SPECIFICS.md).
3. **Spares collision** — one-time `"SPARE-#{id}"` backfill migration, **no
   auto-assign going forward (Option B)** — a real, user-visible behaviour
   change: a second unserialized spare of the same type/owner is now
   rejected at save time.

Full technical detail (schema, files, the import-side dedup consequence,
scope notes): **DECOR_PROJECT.md, "Owner Part Number Feature — Sessions
69–72."**

---

## Session 69 Summary — UI Terminology Rename (implemented, resolved Session 72) + Owner Part Number (design only)

**Part 1 — UI Terminology Rename: IMPLEMENTED, 15 files, resolved Session 72.**
"Model"→"Computer Model", "Order Number"→"DEC Part Number", "Serial
Number"→"DEC Serial Number" — display text only, no attribute/column/route
renamed. Full mapping (including abbreviated-header variants and what was
deliberately left unchanged, e.g. CSV column headers): **DECOR_PROJECT.md,
"UI Terminology — Established Renames (Session 69)."** Future sessions must
use those labels for any new UI.

**Part 2 — Owner Part Number: design consultation only, NOT implemented
this session.** Reading `computer.rb`/`component.rb` directly (Never-Guess)
surfaced 3 open questions (uniqueness scope, presence asymmetry, spares
collision risk) — all 3 answered and implemented in Session 70; see "Session
70 Summary" above and DECOR_PROJECT.md for the full resolution.

---

## Session 67 Summary — Component Suggestions Phase 4: fully implemented (resolved Session 72)

All four Session 66-confirmed requirements delivered: manual-flag migration,
"Download Manual Changes" export, import rewrite (`delete_all` +
`insert_all(unique_by:)` — fixed the production timeout), paginated/
filterable admin index. 12 production + 4 test files. `bin/rails test`: 900
tests, 0 failures/errors at session close.

    decor/db/migrate/20260707000100_..._to_component_suggestions.rb        NEW
    decor/app/models/component_suggestion.rb                               v1.0 → v1.1
    decor/app/services/component_suggestion_import_service.rb              v1.0 → v2.0
    decor/app/services/manual_component_suggestions_export_service.rb      NEW (v1.1)
    decor/app/controllers/admin/component_suggestions_controller.rb       v1.0 → v1.2
    decor/config/routes.rb                                                 v3.5 → v3.6
    decor/app/views/layouts/admin.html.erb                                 v2.6 → v2.7
    decor/app/helpers/admin/component_suggestions_helper.rb               NEW
    decor/app/views/admin/component_suggestions/{_filters,_component_suggestion,index.turbo_stream}.html.erb  NEW
    decor/app/views/admin/component_suggestions/index.html.erb            v1.0 → v1.1
    + 4 test files updated/added

**create/update `manual`-flag semantics** (not restated elsewhere — the
authoritative behavior spec for this column): `create` always sets
`manual: "added"`, permanently — never reverts on later edits. `update`
promotes `manual` from `nil` → `"modified"` ONLY on a previously-untouched
row; a row already `"added"` or `"modified"` keeps its value unchanged.
Neither value is ever accepted as a raw form param — always set explicitly
in the controller.

Two mistakes made and corrected mid-session, both now MANDATORY
RAILS_SPECIFICS.md v3.7 / COMMON_BEHAVIOR.md v3.0 sections: a collection-route
prefix shape guessed wrong (see RAILS_SPECIFICS.md "Collection Routes Nested
in a Namespaced Resources Block"), and a flagged-but-still-guessed
`index.turbo_stream.erb` (see COMMON_BEHAVIOR.md "Flagging a Guess Does Not
Satisfy Never-Guess"). Also fixed an unrelated `json` gem CVE blocking CI.

**Habit worth keeping:** several "tests still failing" reports this session
turned out to be delivered files simply not yet copied into the actual
project paths (old versions still in place), not logic bugs in the new
code. When a "still failing" report comes in, check whether the failure
signature matches "old code still running" before assuming a new bug.

---

## Session 66 Summary — Order Number / Variant: design pivot, no implementation (implemented Session 67)

Design consultation only — no files touched. A full multi-column
variant-split design was worked out in complete detail, then set aside
before implementation (risk of "self-indulgent featuritis" relative to
confirmed need at the ~46,000-record scale). Full shelved design kept for
reference at `decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md` v1.0 — **not
implemented, not the current direction.**

**Adopted instead:** concatenate order number + variant into one string at
the DEC-database export stage (e.g. `"DELQA-00"`), concatenate both
descriptions with `" | "` — no schema split. Four requirements confirmed for
next session (manual-flag migration, "Download Manual Changes" backup
export, `delete_all`+`insert_all` import rewrite, paginated admin index) —
**all four implemented and deployed in Session 67**, see that summary above
and DECOR_PROJECT.md "Component Suggestions Feature — Phase 4" for the full
resolution.

---

## Session 65 Summary — Component order_number bulk maintenance (resolved Session 66)

Two new admin Components-dropdown items, 8 files: **"Re-validate Order
Numbers"** (POST, applies immediately, re-syncs `order_number_verified`
against `component_suggestions` via `update_column`) and **"Download
Unvalidated Order Numbers"** (GET, CSV, one row per component, not
deduplicated). Bug found and fixed mid-session: dropdown links omitted the
`admin_` prefix Rails still applies to `as:` routes inside `namespace
:admin`. See RAILS_SPECIFICS.md "Named Routes (as:) Inside namespace" for
the full rule. Confirmed committed/deployed in Session 66 — see
DECOR_PROJECT.md "Component Suggestions Feature — Phase 3" for full detail.

---

## Session 61 Summary

**Focus: Computers Statistics page + Statistics dropdown in the top nav.**

Local testing passed. All existing tests continue to pass.

### Files delivered this session (7 files)

    decor/config/routes.rb                                                v3.1 → v3.2
    decor/app/controllers/computer_statistics_controller.rb               v1.0 → v1.1  NEW
    decor/app/helpers/computer_statistics_helper.rb                       v1.0         NEW
    decor/app/views/computer_statistics/_filters.html.erb                 v1.0         NEW
    decor/app/views/computer_statistics/index.html.erb                    v1.0 → v1.1  NEW
    decor/app/views/common/_navigation.html.erb                           v2.3 → v2.4
    decor/test/controllers/computer_statistics_controller_test.rb         v1.0 → v1.1  NEW

### Feature: Computers Statistics page (`/computer_statistics`)

**Route:** `GET /computer_statistics` → `ComputerStatisticsController#index`
Named helper: `computer_statistics_path`.

**Controller strategy (two queries, Ruby-side sort):**
- Query 1: `Computer.where(device_type: "computer").group(:computer_model_id).count`
  Returns a Hash `{ computer_model_id => Integer }` scoped to actual computers only.
  Peripheral Computer records that reference a computer ComputerModel are excluded.
  (Confirmed in fixtures: `dec_unibus_router` has `computer_model: pdp11_70`.)
- Query 2: `ComputerModel.where(device_type: "computer")` — all computer models.
- Map to `[{ model:, count: }]`, reject count == 0, then sort in Ruby.

**Sort options** (param: `sort`):
- `most_common` (default) — `sort_by { [-count, name] }`
- `least_common`           — `sort_by { [count, name] }`
- `model_asc`              — `sort_by { name }`
- `model_desc`             — `sort_by { name }.reverse`

**Zero-count exclusion:** models with no registered computers are rejected before
the sort step. They do not appear in the table.

**Filter partial** — Search (LIKE by model name) + Sort only. No condition/run-status/
barter filters (those are per-computer attributes, not per-model attributes).

**Table layout:** `w-auto` (not `min-w-full`) so the table shrinks to content width.
Count column is `text-left pl-10` — sits close to the model name column.
Model names link to `computers_path(model: stat[:model].id)` (pre-filters computers
index to that model).

### Feature: Statistics dropdown in the top nav

`_navigation.html.erb` v2.4 — new "Statistics ▾" dropdown appended after "Software"
in the left nav group. Uses the same `data-controller="dropdown"` pattern as "Info".
First (and currently only) entry: "Computers" → `computer_statistics_path`.
Future statistics pages can be added as additional `link_to` entries in this dropdown.

---

## Session 60 Summary

**Focus: System tests — fixed all 48 failures/errors from Session 59's
`test:system` run.** Final result: 49 tests, 0 failures/errors/skips. 8
files (incl. `RAILS_SPECIFICS.md` v3.2 → v3.3, `_navigation.html.erb` v2.2 →
v2.3 — added the "Sign out" link required by system tests, also a genuine
UX fix since users previously had no nav sign-out at all).

Six root-cause categories fixed (assert_selector message-string
ArgumentError, Turbo navigation race in sign_in, missing sign-out link,
Capybara `select()` matching by text not value, Turbo Frame filter forms
not updating the URL, `<template>` elements needing `evaluate_script`) —
full rules and code examples: **RAILS_SPECIFICS.md v3.7, "System Tests —
Capybara Assertion Patterns" and adjacent sections.**

---

## Session 59 Summary

**Focus: System tests — Track 1 (JS-dependent interactions) + DRY fix.**

### Files delivered (7 files)

    decor/test/application_system_test_case.rb             v1.0 → v1.1
    decor/test/support/authentication_helper.rb            v2.0 → v2.1
    decor/test/controllers/computers_controller_test.rb    v1.10 → v1.11
    decor/test/system/authentication_test.rb               v1.0  NEW
    decor/test/system/computers_filters_test.rb            v1.0  NEW
    decor/test/system/components_filters_test.rb            v1.0  NEW
    decor/test/system/software_items_filters_test.rb       v1.0  NEW
    decor/test/system/connection_groups_test.rb            v1.0  NEW

---

## Priority 1 — Future Sessions

1. **System tests Track 2** — Tom Select combobox, admin CRUD flows, full auth flow.
2. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.
6. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
   `production.rb` to the app's public hostname.
7. **Storage Locations Session C (IN PROGRESS, Session 81) needs its two
   flagged gaps closed, then testing/commit/deploy; Sessions D–F remain
   NOT STARTED** — see DECOR_PROJECT.md "Storage Locations Feature —
   Session Plan" and "Session 81 Summary" above.

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

### Auto-assign rules
- `owner_group_id`: assigned on create as `max(owner.connection_groups.owner_group_id) + 1`
- `owner_member_id`: assigned on create as `max(in-memory siblings, db rows) + 1`
- Guard: `return if field.to_i > 0` — NOT `field.present?` (0.present? is true)

---

**End of SESSION_HANDOVER.md**
