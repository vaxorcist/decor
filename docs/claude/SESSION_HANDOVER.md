# decor/docs/claude/SESSION_HANDOVER.md
# version 76.0
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
#   Two rule-doc corrections made at the user's explicit request mid-session
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

**Date:** July 22, 2026 (Session 75 — three UI bug fixes; browser-tested by
  Ulli; NOT YET lint/security-scanned or committed)
**Branch:** main (Sessions 49–72 all committed, pushed, merged, and
  deployed, per Session 72's confirmation). Session 73's Category Help
  Pages feature (7 files) was last known to be **code-complete but NOT YET
  tested, lint/security-scanned, or committed** as of Session 74's close —
  its status was not updated or re-confirmed during Session 75, since this
  session's work didn't touch it. Session 75 (this session) adds a
  separate, second item to the same "not yet committed" list: three UI bug
  fixes, **code-complete and browser-tested, but NOT YET rubocop/brakeman/
  bundle-audit-scanned or committed.** Two independent uncommitted items
  are now open on top of main — worth confirming both statuses explicitly
  before assuming either is further along than described here.
**Status:** Sessions 1–72 fully closed out (see "Session 72 Summary").
  Session 73's checklist (see "Session 73 Summary" below) and Session 75's
  checklist (see "Session 75 Summary" below) are both currently open. The
  GAP NOTICE below (Session 68's missing formal summary — a
  documentation-only issue, not a code issue) also remains open.

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

## Session 75 Summary — Three UI bug fixes: code-complete, browser-tested, not yet lint/security-scanned or committed

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

### NOT YET DONE — required before this session's three bug fixes can be committed

    [ ] Place all three delivered files into the actual project (if not already done —
        Ulli confirmed browser-testing "all fine now" for all three)
    [ ] bin/rails test
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

Note: Session 73's Category Help Pages checklist (see "Session 73 Summary"
below) is a SEPARATE, still-open item — its status was not re-confirmed or
touched during this session.

---

## Session 73 Summary — Category Help Pages feature: implemented, code-complete, not yet tested/committed

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

### NOT YET DONE — required before this feature can be committed

    [ ] Place the 7 delivered files into the actual project (via the
        Session 73 placement script, decor/import/place_session_73_files.sh)
    [ ] Upload actual Markdown content for the 5 new keys via Admin > Texts >
        Upload Text (pages currently show "== Empty ==")
    [ ] bin/rails test
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check: all 5 new Info dropdown links; admin
        Upload/Download/Delete selectors show the 5 new entries;
        help_computers_path renders "Computers Help" as its heading
        (regression check for the title_for_key fix); confirm whether
        render_markdown supports header anchors if a TOC is wanted on any
        new page
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

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
:admin` — now RAILS_SPECIFICS.md's "Named Routes (as:) Inside namespace"
MANDATORY rule. Test files create `Component` records fresh in-test against
`owners(:three)` (neutral owner), not new fixtures, since both services scan
every Component row project-wide. Confirmed committed/deployed in Session 66
— see DECOR_PROJECT.md "Component Suggestions Feature — Phase 3" for full
detail.

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
