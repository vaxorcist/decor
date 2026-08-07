# decor/docs/claude/SESSION_HANDOVER.md
# version 92.0
# Session 91 (ad-hoc, direct continuation of Session 90's StorageLocation
#   show page — same feature, not a new A-F letter): Ulli reported the
#   Session 90 flat, alphabetical-by-name list wasn't sufficient to
#   identify an item. Reworked into four fixed-order category sections
#   (Computers, Peripherals, Components, Software), each shown only when
#   non-empty, with the full identifying-field set per category:
#     Computers/Peripherals: Model | DEC Part Number | DEC Serial Number |
#       Owner Part Number
#     Components:            Component Type | DEC Part Number | DEC Serial
#       Number | Owner Part Number
#     Software:               Software Name | Version
#   Sort: category first (fixed order), then case-insensitive alphabetical
#   by Model/Type/Software Name within each category (done in the
#   controller, not the view).
#   Implemented via Pre-Implementation Verification: a first export script
#   pulled storage_locations_controller.rb, storage_locations/show.html.erb,
#   storage_location.rb, computer.rb, component.rb, software_item.rb, and
#   two reference views (computers/show.html.erb, components/show.html.erb,
#   for the established DEC Part Number/DEC Serial Number/Owner Part Number
#   column-label convention) before any code was written. A second export
#   script (requested after Ulli asked for tests, before the git workflow)
#   pulled the fixture files (storage_locations.yml, computers.yml,
#   components.yml, software_items.yml), authentication_helper.rb, and the
#   existing storage_locations_controller_test.rb before any test code was
#   written.
#   Delivered: storage_locations_controller.rb v1.2 -> v1.3 (show action
#   rebuilt around three new private builder methods —
#   build_computer_rows/build_component_rows/build_software_rows — splitting
#   the single has_many :computers association into Computers vs
#   Peripherals via the device_type enum's generated device_type_computer/
#   device_type_peripheral scopes); storage_locations/show.html.erb v1.0 ->
#   v1.1 (four fixed-order sections replacing the single flat list);
#   storage_locations_controller_test.rb v1.0 -> v1.1 (full `show` action
#   test coverage added — access control, per-category field display,
#   per-category sort order, empty-section omission, cross-owner isolation;
#   zero fixture .yml files modified — every test assigns storage_location
#   via update!/create! INSIDE the test itself, relying on Rails'
#   transactional fixture rollback, specifically to avoid silently changing
#   shared computers.yml/components.yml/software_items.yml fixture state
#   that other, not-in-hand test files — e.g. Session 88's
#   computers_controller_test.rb Storage Location filter tests — may
#   depend on).
#   Ulli confirmed bin/rails test, rubocop, brakeman, bundle-audit, and a
#   manual browser check ALL PASSED for the controller+view pair
#   (v1.3/v1.1) — but this run predates the test file (v1.1), since Ulli
#   asked for tests to be written before the git workflow. The new test
#   file's own pass/fail status has NOT yet been confirmed — the full
#   checklist needs to be re-run now that it includes the new show-action
#   tests. Git workflow (branch -> commit -> push -> PR -> CI -> merge ->
#   deploy) has NOT been started — deferred at Ulli's explicit request to
#   write tests first; session ended at ~90% token budget, at Ulli's
#   explicit request for a full (non-delta) wrap-up rather than the usual
#   90%-budget delta-document handover.
# Session 90: Ad-hoc feature addition, unrelated to Storage Locations
#   Sessions D/E/F — Ulli asked for a `show` page on StorageLocation,
#   reachable via a link on the location's name at /storage_locations,
#   listing everything stored there (Computers, Peripherals, Components,
#   Software Items) combined into one flat list, sorted alphabetically,
#   regardless of category. This reverses Session B's original "no :show
#   action needed" decision (routes.rb v3.8 / storage_locations_
#   controller.rb v1.1's own comments) — reasonable at the time, but
#   Session C's has_many :computers/:components/:software_items
#   associations make a show page straightforward now.
#   Implemented via Pre-Implementation Verification: an export script
#   pulled routes.rb, storage_locations_controller.rb, storage_location.rb,
#   computer.rb, component.rb, software_item.rb, storage_locations/
#   index.html.erb, and computers/show.html.erb (as a display-convention
#   reference) before any code was written. A second, ad-hoc single-file
#   request followed for storage_locations/_storage_location.html.erb (the
#   index's row partial), which was not in the original export and turned
#   out to be the actual file needing the link added — not index.html.erb
#   itself, which only loops over that partial.
#   Delivered: config/routes.rb v3.8 → v3.9 (show added, except: [:show]
#   removed); storage_locations_controller.rb v1.1 → v1.2 (show action
#   added, scoped to Current.owner like every other action here — no admin
#   exception, unlike computers#show which is public); storage_locations/
#   show.html.erb v1.0 (NEW); storage_locations/_storage_location.html.erb
#   v1.0 → v1.2 (name wrapped in a link to the new show page).
#   Two corrections mid-session, both self-caught or user-caught quickly:
#     1. The delivered _storage_location.html.erb was initially named with
#        the @-encoded flat-file scheme even though it was a genuinely
#        single-file, ad-hoc delivery — Claude self-caught this before
#        presenting it (no user prompt needed) and redelivered under the
#        plain filename. See COMMON_BEHAVIOR.md's Session 90 note under
#        "Flagging a Guess Does Not Satisfy Never-Guess" / "File Transfer
#        Protocol" — confirms the Session 89 rule is doing its job.
#     2. The v1.1 link used `text-stone-900 hover:text-indigo-600`
#        (indigo only on hover), so it wasn't visually recognizable as a
#        link at rest — reported by Ulli, fixed in v1.2 to the established
#        clickable-value convention (DECOR_PROJECT.md "Design Patterns" →
#        Color Scheme): `text-indigo-600 hover:text-indigo-900`, indigo
#        from the resting state. Not a new rule — the convention was
#        already documented; this was a plain miss applying it. Also
#        flagged (not fixed this session): RAILS_UI.md was not loaded
#        before this view/CSS work, per RAILS_SPECIFICS.md v4.0's own
#        topic-index rule ("load for view/CSS/Stimulus/nav work") — worth
#        a deliberate check at the start of any Tailwind-touching task in
#        a future session.
#   No test written this session for the new `show` action — flagged to
#   Ulli as a pending Test Coverage Check item (needs test/fixtures/
#   storage_locations.yml, computers.yml, components.yml, software_items.yml,
#   and any existing storage_locations_controller_test.rb as a pattern,
#   none of which were requested/provided this session). Deferred, not
#   forgotten — see "Open Checklists" below. **RESOLVED Session 91** — see
#   that session's own changelog entry above.
#   Session ended at Ulli's explicit "wrap up now" request, not a token-
#   budget trigger this time — estimate was ~72-78% at that point.
# Session 89: Ad-hoc bug fix, unrelated to the Storage Locations plan —
#   Ulli reported the Components show page (e.g. /components/397) was
#   missing the Owner Part Number field. Root cause: Component#owner_
#   part_number (component.rb v1.6, Session 70) and its strong-params
#   permit (components_controller.rb v2.1, Session 70) were both correct
#   from the start; components/show.html.erb was simply never updated to
#   display it, even though the equivalent field was added to
#   computers/show.html.erb in Session 75. Same "single source of truth /
#   touch N places, miss one" shape as RAILS_SPECIFICS.md's own rule.
#   Fixed via Pre-Implementation Verification: an export script pulled
#   components/show.html.erb, component.rb, components_controller.rb, and
#   the known-working computers/show.html.erb for comparison before any
#   code was written. components/show.html.erb v1.9 -> v1.10 added the
#   field as a standalone row; revised immediately to v1.11 per Ulli's
#   follow-up feedback, placing Component Owner Part Number and Trade
#   Status side by side in one row (grid-cols-2 when logged in,
#   grid-cols-1 alone when logged out, since Trade Status stays
#   members-only and fully absent from the DOM for logged-out visitors).
#   No controller/model change needed; no new test needed (view-only
#   display change, no server-side logic altered).
#   Process note: the v1.10 delivery was made using the @-encoded
#   flat-filename scheme even though it was a single ad-hoc file with no
#   script involved — a misapplication of the multi-file File Transfer
#   Protocol to a case the protocol's own "Single ad-hoc file exchanges
#   don't need a script" line already excludes. Caught immediately by
#   Ulli; corrected by redelivering with the plain filename. See
#   COMMON_BEHAVIOR.md's Session 89 reinforcement note for the rule
#   reinforcement this produced. No new rule was needed — the existing
#   rule already covered this; the miss was a one-off application error.
#   Session ended at ~90% token budget (per Ulli's report of the system
#   warning).
# Session 88: Resumed the paused Storage Locations Session E. Fixed a
#   test-data bug in the existing Computers/Peripherals draft: 2 of 3
#   v1.12 tests called StorageLocation.create! with a name ("Attic Shelf
#   3") that collided with the alice_attic fixture already defining that
#   exact (owner_id, name) pair — raised ActiveRecord::RecordInvalid.
#   Fixed in computers_controller_test.rb v1.13 by referencing the
#   existing fixtures instead of creating new records. Full pre-commit
#   checklist (bin/rails test, rubocop, brakeman, bundle-audit, manual
#   browser check) then passed on the Computers/Peripherals draft. Wrote
#   the matching Components and SoftwareItems equivalents (8 files:
#   components_helper.rb v1.5, components_controller.rb v2.3,
#   components/_filters.html.erb v1.5, components_controller_test.rb v1.4,
#   software_items_helper.rb v1.1, software_items_controller.rb v1.5,
#   software_items/_filters.html.erb v1.1, software_items_controller_test.rb
#   v1.6) from the now-verified Computers pattern — same two-guard filter
#   logic (if logged_in? + ownership-existence check against a crafted
#   cross-owner storage_location_id), same UI placement (after Trade), same
#   3-test shape. Test fixtures deliberately chosen to avoid barter-status
#   confounds and referenced existing storage_locations fixtures directly
#   (no create! calls anywhere) — the lesson from the Computers test fix
#   was applied immediately rather than repeated. Full pre-commit checklist
#   passed on all three device types together. Git workflow (branch →
#   commit → push → PR → CI → merge) and kamal deploy — ALL CONFIRMED
#   SUCCESSFUL by Ulli. **Storage Locations Session E is now COMPLETE.**
#   Only Session F (export/import) remains open in the Storage Locations
#   plan.
#   Process note: Ulli asked that future sessions not generate more than
#   one export/import/placement script per exchange unless there's a
#   specific reason — applied for the remainder of this session (a single
#   placement script covered all 8 delivered files, rather than one per
#   device type).
# Session 87: Resolved the Gap Notice opened in Session 86 (the
#   computers_helper.rb "v1.9" anomaly). session_d_git_archaeology.sh
#   (generated Session 86) proved no commit on any branch ever produced a
#   v1.9 of that file — the last commit touching it was Session 52's
#   1c53569, which brought it to v1.8. A follow-up diff capture,
#   session_d_uncommitted_diff_report.sh (Session 87), confirmed the file's
#   own v1.9 content is real: sound, well-patterned, UNCOMMITTED local work
#   covering the Computers/Peripherals half of Storage Locations Session E
#   (computers_helper.rb, computers_controller.rb,
#   computers/_filters.html.erb, computers_controller_test.rb — a Storage
#   Location filter with an ownership-existence guard against a crafted
#   cross-owner id, plus 3 new tests). Not phantom history, not fabricated
#   commentary — just never committed, run, tested, or reviewed. The
#   original archaeology sweep's "Session E" commit-message hit was
#   confirmed unrelated (the Software feature's own A–F session plan reuses
#   the same letter for a different, already-shipped piece of work).
#   RESULT: Storage Locations Session D is now marked COMPLETE — the
#   Session 86 six-view + shared-partial audit stands on its own and is
#   unaffected by this discovery. Storage Locations Session E is marked IN
#   PROGRESS, PAUSED — per Ulli's explicit choice, the Computers/
#   Peripherals draft is left exactly as found (uncommitted, not run/
#   tested/lint/security-scanned); Components and SoftwareItems equivalents
#   remain NOT STARTED. No new code was written this session — status/
#   documentation update only, per Ulli's explicit request to close out D
#   and pause here.
# Session 86: Storage Locations Session D (Privacy Audit) — views half DONE
#   and CLEAN (all six owner read-only views + the shared _profile.html.erb
#   partial they all render); confirmed the partial-sharing leak vector
#   DECOR_PROJECT.md flagged does not exist in this codebase (none of the
#   six render the device partials that carry a Storage Location cell).
#   Also confirmed (informational) the three device partials' existing
#   per-row Current.owner guard is correct. Flagged an anomaly in
#   computers_helper.rb (already v1.9, Session E-shaped code, unverified
#   "privacy audit passed Session D" claim) — resolved Session 87, see
#   above. No code written/tested/committed this session.
# Session 85 (Reorg 4 of 4, plan agreed Session 83 — REORG PLAN NOW FULLY
#   COMPLETE): Trimmed COMMON_BEHAVIOR.md (v3.1 → v4.0, 33,291 → 26,401
#   chars) and PROGRAMMING_GENERAL.md (v2.0 → v3.0, 19,993 → 19,623 chars).
#   Same approach as Reorg 3: every "Real example" / "Why this rule exists"
#   narrative paragraph condensed to one line; rule statements, checklists,
#   and code/format examples kept verbatim. A cross-doc dedup check was run
#   (grepped all 5 files for repeated distinctive phrases/rule names) — no
#   unintentional literal duplication was found beyond the deliberate short
#   cross-reference pointers already established by Reorg 1
#   (SESSION_HANDOVER.md's "!! ... !!" banners) and Reorg 3
#   (RAILS_SPECIFICS.md's topic index); COMMON_BEHAVIOR.md's and
#   PROGRAMMING_GENERAL.md's both having an "Always Specify Complete
#   Paths"-style rule is a deliberate structural overlap (universal/
#   decor-specific vs. generic-programming framing), not accidental
#   duplication, and was left alone. One minor content addition beyond pure
#   trimming: PROGRAMMING_GENERAL.md's "Export / Import — Always Include a
#   Stable Unique Key" rule now lists storage locations' natural key
#   `(owner_id, name)` alongside the other four existing record types, for
#   Session F's benefit. **Total mandatory-rule-document set: 141,799 →
#   134,539 chars (~35,450 → ~33,635 tokens, ÷4 estimate) — a smaller
#   savings than Reorgs 1–3 since these two files were already comparatively
#   lean (mostly generic template rules, not narrative-heavy) going in.**
#   This closes out the 4-session Documentation Reorganization plan agreed
#   Session 83. See "Documentation Reorganization — Status" below.
# Session 84 (Reorg Sessions 2 and 3 of 4, continued in the same sitting as
#   Reorg 1 below): Reorg 2 trimmed DECOR_PROJECT.md (v2.73 → v2.74): cut
#   the Directory Tree section and the "Key file versions" history table,
#   compressed six fully-DONE feature write-ups to short pointers, removed
#   the Session 77/78 narrative sections (now redundant with
#   SESSION_HISTORY_ARCHIVE.md). Reorg 3 topic-split RAILS_SPECIFICS.md
#   (v3.15 → v4.0, ~98,000 chars) into four files: RAILS_SPECIFICS.md
#   (core Rails/Ruby/SQLite/routing rules + a topic index, ~21,000 chars,
#   still mandatory session-start reading), RAILS_UI.md v1.0 NEW
#   (Tailwind/nav/z-index/CSS/Tom Select/ERB rules, ~11,900 chars, load for
#   view/CSS/Stimulus work), RAILS_TESTING.md v1.0 NEW (fixture/Capybara/
#   CI/test-helper rules, ~15,150 chars, load before writing any test),
#   RAILS_MISC.md v1.0 NEW (email/mailer rules, ~7,500 chars, load for
#   mailer work only). Every rule's "why this rule exists" narrative was
#   trimmed to one line across all four files; rule statements and code
#   examples were kept verbatim. Also resolved the cross-doc issue flagged
#   at the end of Reorg 2: RAILS_SPECIFICS.md's old "Directory Tree
#   Maintenance — MANDATORY" section (which told future sessions to keep
#   DECOR_PROJECT.md's now-deleted tree section current) was removed
#   rather than repointed. **Session-start reliability notice below
#   updated accordingly** — the mandatory `cat` list still names five
#   files, but RAILS_SPECIFICS.md is now the ~21,000-char core file, not
#   the ~98,000-char monolith; RAILS_UI.md/RAILS_TESTING.md/RAILS_MISC.md
#   are explicitly NOT part of the mandatory list, same treatment as
#   SESSION_HISTORY_ARCHIVE.md. The "!! ... !!" banners below that used to
#   point into RAILS_SPECIFICS.md for UI/testing rules now point to the
#   correct new file. Reorg 4 (COMMON_BEHAVIOR.md/PROGRAMMING_GENERAL.md
#   trim + final cross-doc dedup) remains NOT STARTED.
# Session 84 (Reorg Session 1 of 4, plan agreed Session 83): Split this
#   file. Extracted every "## Session N Summary" block, the old per-session
#   header changelog, and the "Connections Feature — Design Reference"
#   appendix into a NEW file, decor/docs/claude/SESSION_HISTORY_ARCHIVE.md
#   v1.0 — verbatim, no rewording, same relative order. That file is NOT
#   part of the mandatory session-start read.
# Session 83 (intermediate, no project work): Rule-set documents had grown
#   too large (~102,000 tokens across all 5 mandatory docs), forcing the
#   delta-document workaround at every wrap-up. Agreed a 4-session reorg
#   plan.
# Full changelog for Sessions 65–82 (each session's own entry, written at
#   the time) is preserved verbatim in
#   decor/docs/claude/SESSION_HISTORY_ARCHIVE.md's "Original Header
#   Changelog" section — not repeated here.

**Date:** August 6, 2026 (Session 91: ad-hoc rework of Session 90's
  StorageLocation show page — Ulli reported the flat, alphabetical-by-name
  list wasn't enough to identify an item. Reworked into four fixed-order
  category sections (Computers/Peripherals/Components/Software), each with
  the full identifying-field set, sorted category-first then
  alphabetically within category. Full `show` action test coverage was
  then written (storage_locations_controller_test.rb v1.1). Ulli confirmed
  the full pre-commit checklist — bin/rails test, rubocop, brakeman,
  bundle-audit, manual browser check — ALL PASSED for the controller+view
  pair (v1.3/v1.1) BEFORE the test file existed; the test file's own
  pass/fail status is NOT yet reconfirmed, and git workflow has not been
  started. Session ended at ~90% token budget, at Ulli's explicit request
  for a full, non-delta wrap-up. See this session's own changelog entry
  above for full detail.)
**Branch:** main (Sessions 1–76 all committed, pushed, merged, and
  deployed, per Ulli's confirmation at the start of Session 76). Sessions
  77 and 78's own work (11 files — see the archive's "Session 77 Summary"
  and "Session 78 Summary") status is UNCHANGED — no session since has
  confirmed placement/testing/commit for that work, which is a separate,
  unrelated bug-fix batch. **Storage Locations Sessions A, B, C, D, and E
  are ALL committed, pushed, merged, and DEPLOYED** — confirmed by Ulli
  (Session 88 confirmed the git workflow and kamal deploy for Session E
  covering all three device types — Computers/Peripherals, Components,
  SoftwareItems — together in one PR). **Storage Locations Session F
  (export/import) remains genuinely NOT STARTED** and is the only piece
  of that feature still open.
  **Session 89's single file (components/show.html.erb v1.11) has been
  delivered to Ulli but its own placement/test/commit/deploy status is NOT
  YET confirmed** — a plain single-file view change, not expected to need
  the full multi-file checklist treatment, but should still go through
  bin/rails test / rubocop / manual browser check before committing.
  **Session 90's original four files (config/routes.rb v3.9,
  storage_locations/_storage_location.html.erb v1.2) have been delivered
  to Ulli but placement/test/commit/deploy status is NOT YET confirmed**
  — the other two files Session 90 delivered (storage_locations_
  controller.rb, storage_locations/show.html.erb) have since been
  superseded by Session 91's v1.3/v1.1, below.
  **Session 91's three files — storage_locations_controller.rb v1.3,
  storage_locations/show.html.erb v1.1, storage_locations_controller_
  test.rb v1.1 — have been delivered to Ulli. The controller+view pair
  (v1.3/v1.1) has been placed and Ulli confirmed the full pre-commit
  checklist (bin/rails test, rubocop, brakeman, bundle-audit, manual
  browser check) ALL PASSED — but that run predates the test file. The
  test file (v1.1) has NOT yet been confirmed to pass, and the git
  workflow for all three files together has NOT been started.**
**Status:** Sessions 1–76 fully closed out and deployed. Sessions 77+78's
  combined checklist remains open (unchanged) — see "Open Checklists"
  below. **Storage Locations Sessions A through E are ALL fully closed
  out, tested, and deployed** — confirmed by Ulli. **Storage Locations
  Session F (export/import) is the only remaining piece of that feature
  and is genuinely NOT STARTED.** **Session 89's Owner Part Number display
  fix (components/show.html.erb v1.11) is code-complete and delivered but
  NOT YET placed/tested/committed/deployed** — a single-file, view-only
  change; doesn't depend on or block anything else. **The StorageLocation
  show page (Session 90, reworked Session 91) is code-complete: the
  controller+view pair (v1.3/v1.1) has passed the full pre-commit
  checklist per Ulli's confirmation, and a full test file (v1.1) now
  exists covering the `show` action for the first time — but the test
  file's own pass/fail status is unconfirmed and git workflow has not
  started for any of it.** This is an ad-hoc addition outside the original
  Storage Locations A–F plan and doesn't depend on or block Session F. The
  GAP NOTICE below (Session 68's missing formal summary) remains open and
  unaffected by any of this.

---

## Documentation Reorganization — Status (agreed Session 83)

The 5 mandatory rule documents had grown to ~102,000 tokens combined
(measured directly, Session 83), forcing the delta-document workaround at
every wrap-up. A 4-session reorg plan was agreed; all four are now DONE
(Sessions 84–85):

    Reorg 1 (DONE, Session 84): Split this file. Extracted every
      "## Session N Summary" block plus the old header changelog into
      decor/docs/claude/SESSION_HISTORY_ARCHIVE.md (NOT part of the
      mandatory session-start read). Rewrote SESSION_HANDOVER.md down to
      current status, open checklists, and a rolling one-line-per-session
      log.
    Reorg 2 (DONE, Session 84): Trimmed DECOR_PROJECT.md (v2.73 → v2.74,
      2,056 lines → 643 lines). Cut the Directory Tree section and the
      "Key file versions" history table; compressed six fully-DONE feature
      write-ups to one-line pointers; removed the Session 77/78 sections
      (now redundant with SESSION_HISTORY_ARCHIVE.md).
    Reorg 3 (DONE, Session 84): Topic-split RAILS_SPECIFICS.md (v3.15,
      ~98,000 chars) into RAILS_SPECIFICS.md v4.0 (core + topic index,
      ~21,000 chars, still mandatory), RAILS_UI.md v1.0 NEW (~11,900
      chars), RAILS_TESTING.md v1.0 NEW (~15,150 chars), RAILS_MISC.md
      v1.0 NEW (~7,500 chars).
    Reorg 4 (DONE, Session 85): Trimmed COMMON_BEHAVIOR.md (v3.1 → v4.0)
      and PROGRAMMING_GENERAL.md (v2.0 → v3.0) using the same approach as
      Reorg 3. Ran a cross-doc dedup grep across all 5 files; found no
      unintentional literal duplication.

**The 4-session Documentation Reorganization plan (agreed Session 83) is
FULLY COMPLETE.** Combined result: the 5 mandatory rule documents measured
~102,000 tokens at the start of Session 83; the same 5 files totaled
134,539 chars (~33,635 tokens, ÷4 estimate) after Session 85. (Note:
COMMON_BEHAVIOR.md has since grown again slightly via the Session 88/89/90
File Transfer Protocol reinforcements — still well under the pre-reorg
size.)

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

**RAILS_SPECIFICS.md is the core-only file as of Session 84 (v4.0,
~21,000 chars)** — it no longer contains the UI/CSS/Stimulus rules, the
test/Capybara/CI rules, or the mailer/email rules. Those moved to three
new files, **none of which are part of this mandatory list**:
- `decor/docs/claude/RAILS_UI.md` — read before any view/CSS/Stimulus/nav task.
- `decor/docs/claude/RAILS_TESTING.md` — read before writing ANY test file.
- `decor/docs/claude/RAILS_MISC.md` — read before any mailer/email task.

**Reinforced (Session 90):** this rule was itself skipped this session —
view/CSS work (a Tailwind link-color class) was done without loading
RAILS_UI.md first, and the result (`text-stone-900 hover:text-indigo-600`,
indigo only on hover) was a visible bug Ulli had to report. No new rule
needed — RAILS_SPECIFICS.md v4.0 already says to load RAILS_UI.md for this
kind of task. Worth a deliberate check at the start of any future
Tailwind/CSS-touching task: "is RAILS_UI.md loaded yet?"

**Checked, correctly, Session 91:** the show-page rework reused Tailwind
utility classes already established in computers/show.html.erb's own
field grid and sub-tables (no new or arbitrary-value classes introduced),
so RAILS_UI.md's Tailwind-rebuild-reminder rule didn't apply — this was
confirmed explicitly rather than assumed, addressing the exact gap flagged
in Session 90's note above.

**decor/docs/claude/SESSION_HISTORY_ARCHIVE.md is also NOT on this list.**
It holds historical session narrative only and is not needed for ordinary
session-start compliance. Consult it, and the three new topic files above,
only when the specific task actually needs them.

---

## !! GAP NOTICE — Session 68 has no formal summary anywhere (found Session 69, still open) !!

While reading files for the Session 69 UI rename task, several source
files delivered as part of the project (e.g.
`decor/app/views/admin/component_suggestions/index.html.erb`, which
carried a "Session 68 (cont'd)" changelog comment about dropdown-width/
full-bleed layout fixes) showed clear evidence of Session 68 work having
happened and been delivered. **But no "Session 68 Summary" has ever been
found in any version of this document, and DECOR_PROJECT.md's own header
changelog jumps straight from Session 67 to Session 69 with no Session 68
entry either.**

This was not reconstructed or guessed at — per the Never-Guess rule, no
"Session 68 Summary" has been fabricated from the partial evidence in the
source files. **This is flagged for Ulli to reconcile:** either a newer
version of these documents (containing the real Session 68 Summary)
exists outside this project and simply wasn't the version uploaded here,
or Session 68's rule-doc updates were never actually produced/delivered
despite the code changes shipping.

**Update (Session 72):** Ulli confirmed the underlying code for Sessions
67–70 has all been committed, pushed, merged, and deployed to `main` —
this documentation gap does not block or affect the code, which is live —
but is left flagged in case Ulli wants to reconstruct it later from source
history.

---

## Open Checklists

### Session 77 + 78 — combined NOT YET DONE (still open, no session since has addressed this)

Full narrative for both sessions is in SESSION_HISTORY_ARCHIVE.md
("Session 77 Summary", "Session 78 Summary"). The two sessions' file
deliveries were never confirmed placed/tested/committed, and Session 78's
own instruction was to commit both batches together. Combined checklist:

    [ ] Place all of Session 77's files: computers/_form.html.erb,
        owners/peripherals.html.erb, computers/show.html.erb,
        components/_filters.html.erb, component.rb, component_test.rb,
        components/_form.html.erb, common/_navigation.html.erb
        (8 files total — NOTE: computers/_form.html.erb and
        components/_form.html.erb are DIFFERENT files, both touched)
    [ ] Place all of Session 78's files: dropdown_controller.js,
        connection_groups/_form.html.erb, common/_navigation.html.erb
        (common/_navigation.html.erb is the SAME file touched by both
        sessions — Session 78's v2.6 → v2.7 edit is the one to place,
        it supersedes Session 77's v2.5 → v2.6)
    [ ] bin/rails test (including the 3 new component_test.rb search-scope
        tests from Session 77)
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check — confirm the Info dropdown z-index fix
        (Session 77) on ALL FIVE affected pages (Owners, Computers,
        Peripherals, Components, Software); confirm admin dropdowns close
        their siblings (Session 78); confirm Connection form Device
        dropdown shows Owner Part Number for both existing and newly-added
        rows (Session 78); confirm nav logo now sits at true page-center
        on every page (Session 78)
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy
        (both sessions' work together, per Session 78's own instruction)

### Storage Locations Session D — COMPLETE (Sessions 86–87)

    [x] Confirm storage_location does NOT appear in owners/computers.html.erb
    [x] Confirm storage_location does NOT appear in owners/peripherals.html.erb
    [x] Confirm storage_location does NOT appear in owners/components.html.erb
    [x] Confirm storage_location does NOT appear in owners/software.html.erb
    [x] Confirm storage_location does NOT appear in owners/show.html.erb
    [x] Confirm storage_location does NOT appear in owners/_owner.html.erb
    [x] Confirm storage_location does NOT appear in owners/_profile.html.erb
    [x] Confirm no partial is shared between the Session B/C owner-CRUD
        views and these read-only views
    [x] Reconcile the computers_helper.rb v1.9 anomaly (Session 87 —
        confirmed uncommitted local Session E draft, not phantom/committed
        history)

No further action needed — Session D is closed out.

### Storage Locations Session E — COMPLETE (Session 88)

All three device types now have Storage Location filter-sidebar support,
tested, lint/security-scanned, committed, merged, and DEPLOYED — confirmed
by Ulli:

    decor/app/helpers/computers_helper.rb              v1.9
    decor/app/controllers/computers_controller.rb       v1.25
    decor/app/views/computers/_filters.html.erb          v1.8
    decor/test/controllers/computers_controller_test.rb v1.13 (fixed a
      test-data collision bug found in this session's pre-commit run —
      see the Session 88 changelog entry at the top of this file)

    decor/app/helpers/components_helper.rb                  v1.5
    decor/app/controllers/components_controller.rb           v2.3
    decor/app/views/components/_filters.html.erb              v1.5
    decor/test/controllers/components_controller_test.rb     v1.4

    decor/app/helpers/software_items_helper.rb                  v1.1
    decor/app/controllers/software_items_controller.rb          v1.5
    decor/app/views/software_items/_filters.html.erb              v1.1
    decor/test/controllers/software_items_controller_test.rb     v1.6

No further action needed — Session E is closed out. Only Session F
(export/import) remains for the Storage Locations feature.

### Storage Locations Session F — NOT STARTED

Depends on A (done) and C (done). Unaffected by the Session D/E work
above. Full breakdown: **DECOR_PROJECT.md, "Storage Locations Feature —
Session Plan."**

### StorageLocation Show Page (Session 90, reworked Session 91) — pre-commit checklist passed for code, test coverage NOT yet reconfirmed, git workflow NOT started

Not part of the original A-F Session Plan — a direct feature request from
Ulli, reversing Session B's original "no show page" decision now that
Session C's associations make it easy. Session 91 reworked Session 90's
flat alphabetical list into four category-grouped sections with full
identifying fields, per Ulli's feedback that the flat list wasn't enough
to identify an item.

**Current file versions (supersedes the Session 90 versions listed in
earlier revisions of this checklist):**

    decor/app/controllers/storage_locations_controller.rb        v1.3
    decor/app/views/storage_locations/show.html.erb                v1.1
    decor/test/controllers/storage_locations_controller_test.rb   v1.1 (NEW
      show-action coverage — the action had zero tests before this)

Also still pending from Session 90, unaffected by the Session 91 rework:

    decor/config/routes.rb                                         v3.9
    decor/app/views/storage_locations/_storage_location.html.erb   v1.2

**Checklist:**

    [x] Place storage_locations_controller.rb v1.3 and
        storage_locations/show.html.erb v1.1 — Ulli confirmed this
    [x] bin/rails test / rubocop / brakeman / bundle-audit / manual
        browser check — Ulli confirmed ALL PASSED for the controller+view
        pair (this run predates the test file below)
    [ ] Place decor/config/routes.rb (v3.9) and decor/app/views/
        storage_locations/_storage_location.html.erb (v1.2), if not
        already done from Session 90
    [ ] Place decor/test/controllers/storage_locations_controller_test.rb
        (v1.1) — NEW show-action test coverage, written Session 91.
        Deliberately does NOT modify any fixture .yml file — every test
        assigns storage_location via update!/create! inside the test
        itself (see the file's own v1.1 header comment for the full
        rationale: avoiding side effects on computers_controller_test.rb/
        components_controller_test.rb/software_items_controller_test.rb,
        none of which were reviewed this session).
    [ ] Re-run bin/rails test now that the new test file is in place —
        NOT yet confirmed passing
    [ ] Re-run rubocop (test files are .rb, lint-checkable) — cheap and
        standard to re-confirm alongside the test run above
    [ ] bin/rails routes | grep storage_location — confirm the show route
        shape before relying on storage_location_path elsewhere (carried
        over from Session 90, still open if not already done)
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy
        (all of the above files together)
    [ ] Optional follow-up (flagged, not urgent — Session 90): consider
        loading RAILS_UI.md at the start of a future session before
        further Tailwind/CSS work on this feature. Note: Session 91's own
        view changes reused existing utility classes only, so this wasn't
        triggered again this session — see the "RELIABILITY NOTICE"
        section above.

### Session 89 — Owner Part Number display fix (components/show.html.erb v1.11) — NOT YET tested/committed

Single-file, view-only change. Independent of everything else in this
document.

    [ ] Place decor/app/views/components/show.html.erb v1.11
    [ ] bin/rails test, rubocop, manual browser check (confirm Owner Part
        Number now displays alongside Trade Status on a Component's show
        page, and that Trade Status remains fully absent from the DOM for
        logged-out visitors)
    [ ] git workflow (can be batched with any other pending work)

---

## Session Log (rolling — last ~12 sessions; full detail in SESSION_HISTORY_ARCHIVE.md)

Older entries drop off this list as new ones are added; nothing is lost —
every session ever logged remains in SESSION_HISTORY_ARCHIVE.md regardless
of whether it still appears here.

    91  Ad-hoc rework of Session 90's StorageLocation show page: Ulli
        reported the flat, alphabetical-by-name list wasn't enough to
        identify an item. Reworked into four fixed-order category
        sections (Computers/Peripherals/Components/Software), each with
        the full identifying-field set (Model/Type/Software Name, DEC
        Part Number, DEC Serial Number, Owner Part Number as applicable),
        sorted category-first then case-insensitively alphabetical within
        category. storage_locations_controller.rb v1.3, storage_locations/
        show.html.erb v1.1 — Ulli confirmed the full pre-commit checklist
        (test/rubocop/brakeman/bundle-audit/manual browser check) ALL
        PASSED. Then wrote full `show`-action test coverage
        (storage_locations_controller_test.rb v1.1, zero fixture .yml
        files touched — used in-test update!/create! instead, rolled back
        automatically by transactional fixtures). Test file's own
        pass/fail status and the git workflow for all three files both
        still open at wrap-up (~90% budget, Ulli's explicit request for a
        full, non-delta wrap-up).
    90  Ad-hoc feature (unrelated to Storage Locations D/E/F): added a
        StorageLocation show page listing everything stored there across
        all types, combined and sorted alphabetically, linked from the
        index. routes.rb v3.9, storage_locations_controller.rb v1.2,
        _storage_location.html.erb v1.2, show.html.erb v1.0 (NEW).
        Self-caught an @-encoding-on-single-file near-miss before
        delivery; user caught a link-color convention miss (fixed,
        indigo-at-rest not hover-only). No test written yet — pending
        fixtures. Ended at explicit wrap-up request, ~72-78% budget.
        **The show-page grouping and test coverage were reworked in
        Session 91 — see that entry above.**
    89  Ad-hoc bug fix (unrelated to Storage Locations): Components show
        page was missing Owner Part Number, present since Session 70 but
        never added to this view (same single-source-of-truth shape as
        prior sessions). Fixed via Pre-Implementation Verification export
        script + comparison against the known-working computers/show.html.erb.
        components/show.html.erb v1.9 -> v1.11 (v1.10 added the field
        standalone; v1.11 revised to place it side by side with Trade
        Status per Ulli's layout feedback). Caught and corrected a
        misapplied @-encoding on a single-file delivery mid-session.
        Session ended at ~90% token budget; rule-doc updates delivered as
        deltas.
    88  Resumed and COMPLETED Storage Locations Session E. Fixed a test
        collision bug in the existing Computers/Peripherals draft
        (computers_controller_test.rb v1.13), passed the full pre-commit
        checklist, then wrote the matching Components and SoftwareItems
        equivalents (8 files) from the verified pattern. All three device
        types tested, lint/security-scanned, committed, merged, and
        DEPLOYED together — confirmed by Ulli. Session F (export/import)
        is now the only remaining Storage Locations work.
    87  Resolved the Session 86 computers_helper.rb anomaly: git-diff
        capture confirmed it's a real, sound, UNCOMMITTED local draft of
        Storage Locations Session E's Computers/Peripherals filter code —
        not phantom history, not fabricated. Storage Locations Session D
        marked COMPLETE. Session E marked IN PROGRESS, PAUSED per Ulli's
        explicit choice. No code written this session.
    86  Storage Locations Session D (Privacy Audit): audited all six
        owners/* read-only views + the shared _profile.html.erb partial —
        ALL CLEAN, no storage_location leak. Found and flagged a
        computers_helper.rb anomaly (resolved Session 87). No code
        written/tested/committed.
    85  Reorg 4 (final reorg session): trimmed COMMON_BEHAVIOR.md (v3.1 →
        v4.0) and PROGRAMMING_GENERAL.md (v2.0 → v3.0). Documentation
        Reorganization plan now FULLY COMPLETE. No project code work.
    84  Reorg Sessions 1-3 (all in one sitting): split SESSION_HANDOVER.md
        into itself + SESSION_HISTORY_ARCHIVE.md; trimmed DECOR_PROJECT.md
        (2,056 → 643 lines); topic-split RAILS_SPECIFICS.md into itself
        (core, v4.0) + new RAILS_UI.md/RAILS_TESTING.md/RAILS_MISC.md. No
        project code work.
    83  Planning-only: measured rule-doc size (~102k tokens), agreed the
        4-session reorg plan. No project code work.
    82  Storage Locations Session C: both flagged gaps closed (strong params,
        Components index column). Migrated, tested, lint/security-scanned,
        committed, merged, DEPLOYED. Session D now unblocked.
    81  Storage Locations Session C: FK + forms + show/index pages
        implemented (20 files), two gaps flagged, migration-timestamp bug
        fixed. NOT tested/committed this session — closed out in 82.
    80  Storage Locations Session B: owner-facing CRUD. Implemented, tested,
        lint/security-scanned, committed, merged, DEPLOYED.

**Sessions 59–79 and earlier:** one-line log entries have aged off this
rolling list. Full narrative for every one of them (including Session 79's
design consultation + Session A, 76 dropdown fixes, 77/78 UI bug fixes,
and everything before) remains in **SESSION_HISTORY_ARCHIVE.md**, unchanged
and complete — nothing described in those sessions has been lost, only
removed from this rolling view.

---

## !! TOM SELECT sortField — must be explicit, never a boolean (learned Session 76) !!

`sortField: false` is not a valid Tom Select option — it silently falls back
to enumerating options by internal object key, which for numeric-id option
values (e.g. `collection_select`) means ascending id order, not the
alphabetical order the Rails query actually produced. Always use an
explicit sort spec: `sortField: { field: "text", direction: "asc" }`.
See **RAILS_UI.md** for the full rule (moved there from RAILS_SPECIFICS.md
in the Session 84 topic-split).

---

## !! CAPYBARA — capture expected text BEFORE Turbo navigation, not after (learned Session 76) !!

Reading `.text` (or any property) off a Capybara element AFTER a
`click_button`/`click_link` that navigates via Turbo risks
StaleElementReferenceError — Turbo replaces the DOM on navigation. Capture
the value into a plain string BEFORE the click, use that string in the
post-navigation assertion. See **RAILS_TESTING.md** for the full rule
(moved there from RAILS_SPECIFICS.md in the Session 84 topic-split).

---

## !! NAV LOGO CENTERING — a 1fr middle column centers on leftover space, not the viewport (learned Session 78) !!

If a nav bar has no max-width wrapper and centers its logo via a middle
`1fr` grid/flex column flanked by two unequal-width groups, the logo
centers on the LEFTOVER space between those groups, not the true viewport
center. Symptom: a page's own correctly-`mx-auto`-centered content gets
reported as "not centered" — the actual bug is the nav's logo position,
not the page. Fix: take the logo out of the flow, `absolute left-1/2
-translate-x-1/2` against a `relative` nav. See **RAILS_UI.md** for the
full rule and code examples (moved there from RAILS_SPECIFICS.md in the
Session 84 topic-split).

---

## !! STICKY HEADERS vs NAV DROPDOWNS — equal z-index ties broken by DOM order (learned Session 77) !!

A page-level sticky element (header, thead, filter sidebar) sharing the
same z-index as the nav's positioned wrapper will win ties against it,
since equal z-index is broken by DOM order and the page content comes
later in the document. Symptom: only the FIRST item of an open dropdown
looks obscured, not the whole menu. Fixed by raising the nav wrapper's
z-index clearly above any page-level z-10 sticky element. See
**RAILS_UI.md** for the full mechanism and code examples (moved there from
RAILS_SPECIFICS.md in the Session 84 topic-split).

---

## !! CI SECURITY CHECKS — bundle-audit reports in batches, confirm clean locally (learned Session 64, reinforced Session 72) !!

General rule (`CI/Security (Ruby)` = bundle-audit, not Brakeman; pull the
actual CI log rather than assume): see **RAILS_TESTING.md** "CI Security
Checks — Two Separate Tools" (moved there from RAILS_SPECIFICS.md in the
Session 84 topic-split).

**Session 72 incident:** `feature/owner_part_number` failed on four gems in
one batch: `loofah` (→ >= 2.25.2), `rails-html-sanitizer` (→ >= 1.7.1),
`sqlite3` (→ >= 2.9.5), `websocket-driver` (→ >= 0.8.2). Fixed with
`bundle update <the four>`, confirmed clean with `bundle-audit check
--update` before re-pushing. Full incident: SESSION_HISTORY_ARCHIVE.md
"Session 72 Summary."

---

## !! GEARED PAGINATION — paginate() SETS @page AND RENDERS ITSELF (learned Session 67) !!

`paginate(scope)` is not a data-fetch step — it assigns `@page` (never a
model-named ivar) and internally calls `respond_to { format.turbo_stream;
format.html }`, i.e. it renders the response. Every ivar the view needs
(`@page_title`, `@turbo_tbody_id`, `@load_more_id`, `@index_path`) MUST be
set BEFORE calling it — it must be the last line of the action.
See RAILS_SPECIFICS.md (core file, v4.0 as of the Session 84 topic-split)
for the full rule and the actual concern source.

---

## !! RAILS ENUM — read_attribute DOES NOT BYPASS TYPE-CASTING (learned Session 67) !!

To get the raw stored value of an enum column ("a"/"m"), use
`<attribute>_before_type_cast` — NOT `read_attribute(:<attribute>)`, which
still returns the mapped label ("added"/"modified"). See RAILS_SPECIFICS.md
(core file, v4.0) for the full rule.

---

## !! COLLECTION ROUTES IN A NAMESPACED resources BLOCK — A SECOND PREFIX SHAPE (learned Session 67) !!

A `collection do get :foo end` route nested inside `resources` already
inside `namespace :admin` prepends the action name to the already-prefixed
resource name (`download_manual_admin_component_suggestions_path`) —
DIFFERENT from a custom `as:` route declared directly in the namespace
(Session 65's `admin_foo_path` shape). Always verify with
`bin/rails routes | grep <name>` — never assume either shape.
See RAILS_SPECIFICS.md (core file, v4.0) for the full rule.

---

## !! FLAGGING A GUESS DOES NOT SATISFY NEVER-GUESS (learned Session 67) !!

Writing a file from general convention and labeling it "inferred, please
verify" is still a Never-Guess violation — it shifts verification burden
onto the user instead of Claude asking for the real file. See
COMMON_BEHAVIOR.md v4.2 for the full rule and the real examples (now
including a Session 90 example of applying it correctly to a missing
rule-document delta file, not just a code file).

---

## !! SYSTEM TESTS — BROWSER-LAYER LOGIN (learned Session 59) !!

`login_as` (AuthenticationHelper) posts to the Rails Rack adapter. It sets a
session cookie on the Rack test adapter — NOT on the Selenium browser process.
System tests run a real Chrome instance; its cookie jar is completely separate.

**Rule:** Never call `login_as` from a system test file.
Use `sign_in` (defined in ApplicationSystemTestCase v1.3) instead.
`sign_in` drives the real login form through the browser.

See `decor/test/application_system_test_case.rb` v1.3 for implementation,
or **RAILS_TESTING.md** (moved there in the Session 84 topic-split).

---

## !! SYSTEM TESTS — CAPYBARA ASSERTION PATTERNS (learned Session 60) !!

Five gotchas (assert_selector + message string raises ArgumentError;
Capybara select() matches by TEXT not value=; filter forms in Turbo Frames
don't update the URL; Turbo navigation races in sign_in/sign_out;
`<template>` elements need evaluate_script) — full rules, wrong/correct code
examples: **RAILS_TESTING.md, "System Tests — Capybara Assertion
Patterns"** (moved there from RAILS_SPECIFICS.md in the Session 84
topic-split).

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
See **RAILS_UI.md** "UI Renames" section for full checklist with examples
(moved there from RAILS_SPECIFICS.md in the Session 84 topic-split).

---

## !! FILE TRANSFER PROTOCOL — export/import scripts, @-encoded flat names !!

Session 71 replaced the old "Output Path Collision" rule (and the old
Download File Naming / Upload File Naming rules) with a single scheme: Claude
generates a shell script to export needed files into `decor/export/` (run from
inside that directory) and a placement script for delivered files staged in
`decor/import/`, both using @-encoded flat filenames (full path, `/`→`@`, all
dots except the true extension→`@`). `decor/export/` and `decor/import/` are
both gitignored. See COMMON_BEHAVIOR.md v4.2 "File Transfer Protocol —
Export/Import Scripts" for the full rule, including the Session 88 (multi-
target single scripts preferred), Session 89 (single ad-hoc files never
get @-encoded), and Session 90 (rule confirmed working — a near-miss was
self-caught before delivery) reinforcements.

**Applied again, Session 91:** two separate export scripts (one for
source/model/view files, a second — requested after Ulli asked for tests —
for fixtures/authentication_helper/existing test file); a 2-file
placement-scripted delivery for the controller+view pair; then a single
ad-hoc file (storage_locations_controller_test.rb, delivered under its
plain filename, no @-encoding) once the git workflow hadn't started yet
and only one file remained to deliver.

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
**RAILS_UI.md** for the full rule and the real example (moved there from
RAILS_SPECIFICS.md in the Session 84 topic-split).

---

## !! OUTPUT FILE NAMING — NEVER substitute underscores for dots !!

See COMMON_BEHAVIOR.md v4.2 for the full rule.

---

## !! FIXTURE DELIVERY RULE !!

Whenever a fixture file is modified, upload it to verify before closing the session.

**Note (Session 91):** no fixture .yml file was modified this session —
the new `show`-action tests deliberately avoid touching computers.yml/
components.yml/software_items.yml, assigning storage_location via
update!/create! inside each test instead (rolled back automatically by
Rails' transactional fixtures). This rule therefore did not apply this
session; flagged here only so a future session doesn't wonder why no
fixture file was delivered alongside the test file.

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

**Applied correctly Session 80, extended Session 90:** `storage_locations_
controller.rb`'s `set_storage_location` and ownership-guard before_actions
are scoped `only: %i[show edit update destroy delete_confirm]` — `:show`
was added in Session 90 alongside the new show action, excluding `new`/
`create`/`index` (which have no `:id`). Unchanged by Session 91's rework —
only the `show` action's own body and its private builder methods changed.

---

## !! paginate — NEVER assign the return value (learned Session 48) !!

`paginate scope` — no assignment. `@page = paginate(scope)` overwrites @page with nil.

---

## !! EXPORT/IMPORT — ALWAYS include a stable unique key (learned Session 49) !!

Every exported record type must carry a stable unique field for duplicate detection.
See PROGRAMMING_GENERAL.md v3.0 for the full rule.

---

## !! RESPONSE BODY ASSERTIONS — Use assert_body_includes (learned Session 50) !!

In integration tests, NEVER use `assert_match(text, response.body)` or
`refute_match(text, response.body)`. Use `assert_body_includes` /
`refute_body_includes` from ResponseHelpers instead.
See **RAILS_TESTING.md** for the full rule (moved there from
RAILS_SPECIFICS.md in the Session 84 topic-split).

**Applied correctly Session 80, reinforced Session 91:** the
`storage_locations_controller_test.rb`'s `show`-action tests use
`assert_body_includes` / `refute_body_includes` throughout, not
`assert_match`/`refute_match` — including for the "section omitted when
empty" assertions (`refute_body_includes "Peripherals ("`, matching the
heading's own parenthesized-count format rather than a bare category word
that could collide with unrelated nav text).

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

See **RAILS_UI.md** for the full rule (moved there from RAILS_SPECIFICS.md
in the Session 84 topic-split).

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

See **RAILS_UI.md** for the full rule (moved there from RAILS_SPECIFICS.md
in the Session 84 topic-split).

---

## !! before_validation vs before_save (learned Session 56) !!

If a model generates a field via callback AND validates it for presence, the
callback MUST be `before_validation` — NOT `before_save`.
See **RAILS_MISC.md** for the full rule (moved there from
RAILS_SPECIFICS.md in the Session 84 topic-split).

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

See **RAILS_MISC.md** "Email HTML" section for full rules (moved there
from RAILS_SPECIFICS.md in the Session 84 topic-split).

---

## !! ActionMailer::TestHelper in integration tests — include explicitly (learned Session 58) !!

ActionDispatch::IntegrationTest does NOT include ActionMailer::TestHelper
automatically. Include it explicitly in any test file using assert_emails.

---

## !! Newsletter fixture html_body — Set explicitly (learned Session 58) !!

Rails fixture loading bypasses model callbacks. Always set html_body explicitly.

---

## !! Admin update tests — include admin: "true" when updating self (learned Session 58) !!

See SESSION_HISTORY_ARCHIVE.md for the full incident narrative — the
underlying rule and example now live in **RAILS_TESTING.md**'s "NOT NULL
Boolean Columns" section, moved there from RAILS_SPECIFICS.md in the
Session 84 topic-split.

---

## Priority 1 — Future Sessions

1. **Storage Locations Session F (export/import)** — the last remaining
   piece of the Storage Locations feature. Depends on A and C (both done).
   See DECOR_PROJECT.md "Storage Locations Feature — Session Plan," Session
   F, for the full file-by-file breakdown (owner_export_service.rb,
   owner_import_service.rb, all_owners_export_service.rb,
   data_transfers/show.html.erb, plus test updates). Sessions D and E are
   both now COMPLETE — nothing further needed there.
2. **StorageLocation show page (Session 90, reworked Session 91)** —
   re-run bin/rails test now that storage_locations_controller_test.rb
   v1.1 exists (not yet confirmed passing), re-run rubocop, confirm
   decor/config/routes.rb (v3.9) and storage_locations/
   _storage_location.html.erb (v1.2) are placed if not already done, then
   git workflow for all five files together (controller, view, test,
   routes, row partial).
3. **Session 89's Owner Part Number display fix** — place
   components/show.html.erb v1.11, run bin/rails test / rubocop / manual
   browser check, then git workflow (can batch with other pending work).
4. **Sessions 77 + 78's combined checklist** — see "Open Checklists" above.
5. **System tests Track 2** — Tom Select combobox, admin CRUD flows, full auth flow.
6. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
7. **Account deletion + data export** (GDPR).
8. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
9. **BulkUploadService stale model references** — low priority.
10. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
    `production.rb` to the app's public hostname.

---

**End of SESSION_HANDOVER.md**
