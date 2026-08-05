# decor/docs/claude/SESSION_HANDOVER.md
# version 88.0
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
#   file. Extracted every "## Session N Summary" block (77, 82, 81, 80,
#   79, 78, 76, 75, 73, 72, 70, 69, 67, 66, 65, 61, 60, 59), the old
#   per-session header changelog, and the "Connections Feature — Design
#   Reference" appendix into a NEW file,
#   decor/docs/claude/SESSION_HISTORY_ARCHIVE.md v1.0 — verbatim, no
#   rewording, same relative order. That file is NOT part of the
#   mandatory session-start read (see the reliability notice below, which
#   still lists only five files).
#   This file is rewritten down to: the current Date/Branch/Status block,
#   the Documentation Reorganization plan/status, the still-open GAP
#   NOTICE (Session 68), the mandatory session-start reliability notice,
#   the standing "!!...!!" rule banners (kept unchanged — quick-reference
#   pointers into RAILS_SPECIFICS.md/COMMON_BEHAVIOR.md, not session
#   narrative, and out of scope for this pass), the still-open NOT YET
#   DONE checklists (Session 77, Session 78, Storage Locations D–F), a new
#   rolling "Session Log" (one line per session, last ~10, pointing to the
#   archive for full detail — older entries drop off as new ones are
#   added), and "Priority 1 — Future Sessions".
#   No rule content, checklist item, or status fact was changed, added, or
#   reworded during this split — this is a pure structural move. Verified
#   before finalizing: every "NOT YET DONE" / "NOT STARTED" item present in
#   v83.1 is still present somewhere in either this file or the archive;
#   every "!! ... !!" banner from v83.1 is still present verbatim below.
# Session 83 (intermediate, no project work): Rule-set documents had grown
#   too large (~102,000 tokens across all 5 mandatory docs, measured via
#   wc -c/4), forcing the delta-document workaround at every wrap-up. Full
#   analysis done this session; agreed a 4-session reorg plan (see below).
#   No file rewrites done this turn beyond a status-block edit — that was
#   left for Reorg Session 1 (this session, 84) to do with a full budget.
# Full changelog for Sessions 65–82 (each session's own entry, written at
#   the time) is preserved verbatim in
#   decor/docs/claude/SESSION_HISTORY_ARCHIVE.md's "Original Header
#   Changelog" section — not repeated here.

**Date:** August 4, 2026 (Sessions 86–87 covered Storage Locations Session D
  — the Privacy Audit. Session 86 did the six-view + shared-partial audit
  (clean) and flagged a computers_helper.rb anomaly rather than guess at
  it. Session 87 resolved that anomaly via a follow-up git-diff capture:
  it's real, sound, UNCOMMITTED local draft work for the Computers/
  Peripherals half of Session E, left exactly as found. Session D is now
  COMPLETE. Session E is IN PROGRESS, PAUSED per Ulli's explicit choice —
  no code was written in either session; both were audit/investigation/
  documentation only.)
**Branch:** main (Sessions 1–76 all committed, pushed, merged, and
  deployed, per Ulli's confirmation at the start of Session 76). Sessions
  77 and 78's own work (11 files — see the archive's "Session 77 Summary"
  and "Session 78 Summary") status is UNCHANGED — no session since has
  confirmed placement/testing/commit for that work, which is a separate,
  unrelated bug-fix batch. Storage Locations Sessions A, B, and C are ALL
  committed, pushed, merged, and deployed — confirmed by Ulli. Storage
  Locations Session E has an UNCOMMITTED, untested local draft sitting in
  the working tree for the Computers/Peripherals side only (see "Storage
  Locations Session E" under Open Checklists) — not pushed, not on any
  branch, not part of `main`.
**Status:** Sessions 1–76 fully closed out and deployed. Sessions 77 and
  78's combined checklist (see "Open Checklists" below) remains the open
  item it was at the end of Session 78 — not addressed since. Storage
  Locations Sessions A, B, and C are ALL fully closed out and deployed.
  The Documentation Reorganization plan (Sessions 84–85) is fully complete.
  **Storage Locations Session D (Privacy Audit) is now COMPLETE** (Session
  86 views audit + Session 87 anomaly resolution — see the Session 86/87
  changelog entries above and "Storage Locations Feature — Session Plan"
  in DECOR_PROJECT.md). **Storage Locations Session E (filter-sidebar
  support) is IN PROGRESS, PAUSED:** an uncommitted, unreviewed local draft
  covers the Computers/Peripherals half only (helper, controller, filter
  view, 3 tests) — not run, tested, lint/security-scanned, or committed;
  Components and SoftwareItems equivalents are NOT STARTED. Paused here at
  Ulli's explicit request — see "Open Checklists" below for the concrete
  remaining steps whenever work resumes. **Session F (export/import)
  remains genuinely NOT STARTED** and is unaffected by any of this.
  The GAP NOTICE below (Session 68's missing formal summary) remains open
  and unaffected by any of this.

---

## Documentation Reorganization — Status (agreed Session 83)

The 5 mandatory rule documents had grown to ~102,000 tokens combined
(measured directly, Session 83), forcing the delta-document workaround at
every wrap-up. A 4-session reorg plan was agreed; three of the four are
now DONE, all in Session 84:

    Reorg 1 (DONE, Session 84): Split this file. Extracted every
      "## Session N Summary" block plus the old header changelog into
      decor/docs/claude/SESSION_HISTORY_ARCHIVE.md (NOT part of the
      mandatory session-start read). Rewrote SESSION_HANDOVER.md down to
      current status, open checklists, and a rolling one-line-per-session
      log.
    Reorg 2 (DONE, Session 84): Trimmed DECOR_PROJECT.md (v2.73 → v2.74,
      2,056 lines → 643 lines). Cut the Directory Tree section and the
      "Key file versions" history table; compressed six fully-DONE feature
      write-ups (Software, Component Suggestions Phases 1-4, Category Help
      Pages, Owner Part Number, two Session 76 dropdown fixes) to one-line
      pointers; removed the Session 77/78 sections (now redundant with
      SESSION_HISTORY_ARCHIVE.md). Data Model Overview, the still-active
      Storage Locations plan, Known Issues, Design Patterns, and Quick
      Reference Commands were left untouched (live reference content).
    Reorg 3 (DONE, Session 84 — completed in one session, no 3a/3b split
      needed): Topic-split RAILS_SPECIFICS.md (v3.15, ~98,000 chars) into
      RAILS_SPECIFICS.md v4.0 (core + topic index, ~21,000 chars, still
      mandatory), RAILS_UI.md v1.0 NEW (~11,900 chars), RAILS_TESTING.md
      v1.0 NEW (~15,150 chars), RAILS_MISC.md v1.0 NEW (~7,500 chars).
      Every "why this rule exists" narrative trimmed to one line; rule
      statements and code examples kept verbatim. Also resolved the
      Directory-Tree-Maintenance-rule staleness flagged at the end of
      Reorg 2 (see this file's own top-of-file changelog for detail).
    Reorg 4 (DONE, Session 85): Trimmed COMMON_BEHAVIOR.md (v3.1 → v4.0,
      33,291 → 26,401 chars) and PROGRAMMING_GENERAL.md (v2.0 → v3.0,
      19,993 → 19,623 chars) using the same approach as Reorg 3 — narrative
      paragraphs condensed to one line, rule statements/checklists/code
      examples kept verbatim. Ran a cross-doc dedup grep across all 5
      files; found no unintentional literal duplication beyond the
      deliberate short cross-reference pointers already established by
      Reorg 1 and Reorg 3. One small content addition alongside the trim:
      the Export/Import stable-key rule in PROGRAMMING_GENERAL.md now also
      lists storage locations' natural key, for Session F's benefit.

**The 4-session Documentation Reorganization plan (agreed Session 83) is
now FULLY COMPLETE as of this session.** Combined result across all four
reorg sessions: the 5 mandatory rule documents measured ~102,000 tokens
at the start of Session 83; the same 5 files now total 134,539 chars
(~33,635 tokens, ÷4 estimate) — Reorg 4's own contribution was smaller
than Reorgs 1–3 (COMMON_BEHAVIOR.md/PROGRAMMING_GENERAL.md were already
comparatively lean), but the combined effect of all four sessions is the
real win. Storage Locations Session D (Privacy Audit) is no longer
waiting on anything from this plan and is the clear next priority — see
"Priority 1 — Future Sessions" below.

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

**RAILS_SPECIFICS.md is now the core-only file as of Session 84 (v4.0,
~21,000 chars)** — it no longer contains the UI/CSS/Stimulus rules, the
test/Capybara/CI rules, or the mailer/email rules. Those moved to three
new files, **none of which are part of this mandatory list**:
- `decor/docs/claude/RAILS_UI.md` — read before any view/CSS/Stimulus/nav task.
- `decor/docs/claude/RAILS_TESTING.md` — read before writing ANY test file.
- `decor/docs/claude/RAILS_MISC.md` — read before any mailer/email task.

**decor/docs/claude/SESSION_HISTORY_ARCHIVE.md is also NOT on this list.**
It holds historical session narrative only (see its own header) and is
not needed for ordinary session-start compliance. Consult it, and the
three new topic files above, only when the specific task actually needs
them.

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
        (added to scope Session 86 — rendered by all six views above)
    [x] Confirm no partial is shared between the Session B/C owner-CRUD
        views and these read-only views (none of the six render the
        device partials — each builds its own inline table)
    [x] Reconcile the computers_helper.rb v1.9 anomaly (Session 87 —
        confirmed uncommitted local Session E draft, not phantom/committed
        history; see the Session 87 changelog entry at the top of this file)

No further action needed — Session D is closed out.

### Storage Locations Session E — IN PROGRESS, PAUSED (found Session 86, confirmed Session 87)

An uncommitted, unreviewed local draft already exists in the working tree,
covering the Computers/Peripherals half only:

    decor/app/helpers/computers_helper.rb              v1.9  (uncommitted)
    decor/app/controllers/computers_controller.rb       v1.25 (uncommitted)
    decor/app/views/computers/_filters.html.erb          v1.8  (uncommitted)
    decor/test/controllers/computers_controller_test.rb v1.12 (uncommitted)

Content reviewed and assessed sound Session 87 (Storage Location filter
gated `if logged_in?`, plus an ownership-existence guard against a crafted
cross-owner `storage_location_id`; 3 new tests covering happy path,
ownership guard, logged-out skip). **Paused here at Ulli's explicit
request — nothing further done this session.** Remaining steps whenever
this resumes:

    [ ] Run the full pre-commit checklist on the existing draft:
        bin/rails test, rubocop, brakeman, bundle-audit, manual browser check
    [ ] Write the matching Components equivalent (components_helper.rb,
        components_controller.rb, components/_filters.html.erb, tests)
    [ ] Write the matching SoftwareItems equivalent (software_items_helper.rb,
        software_items_controller.rb, software_items/_filters.html.erb, tests)
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy,
        all three device types together

Full file-by-file breakdown: **DECOR_PROJECT.md, "Storage Locations
Feature — Session Plan."**

### Storage Locations Session F — NOT STARTED

Depends on A (done) and C (done). Unaffected by the Session D/E situation
above. Full breakdown: **DECOR_PROJECT.md, "Storage Locations Feature —
Session Plan."**

---

## Session Log (rolling — last ~10 sessions; full detail in SESSION_HISTORY_ARCHIVE.md)

Older entries drop off this list as new ones are added; nothing is lost —
every session ever logged remains in SESSION_HISTORY_ARCHIVE.md regardless
of whether it still appears here.

    87  Resolved the Session 86 computers_helper.rb anomaly: git-diff
        capture (session_d_uncommitted_diff_report.sh) confirmed it's a
        real, sound, UNCOMMITTED local draft of Storage Locations Session
        E's Computers/Peripherals filter code (helper + controller +
        filter view + 3 tests) — not phantom history, not fabricated. The
        "Session E" commit hit from the original sweep was unrelated
        (Software feature's own A–F plan). Storage Locations Session D
        marked COMPLETE. Session E marked IN PROGRESS, PAUSED per Ulli's
        explicit choice. No code written this session.
    86  Storage Locations Session D (Privacy Audit): audited all six
        owners/* read-only views + the shared _profile.html.erb partial —
        ALL CLEAN, no storage_location leak. Confirmed the partial-sharing
        leak vector DECOR_PROJECT.md flagged doesn't exist here. Found and
        flagged a computers_helper.rb anomaly (already v1.9, Session
        E-shaped code, unverified claim) — resolved Session 87. No code
        written/tested/committed.
    85  Reorg 4 (final reorg session): trimmed COMMON_BEHAVIOR.md (v3.1 →
        v4.0) and PROGRAMMING_GENERAL.md (v2.0 → v3.0) — narratives
        condensed to one-liners, rules/checklists/examples kept verbatim.
        Cross-doc dedup grep found nothing unintentional. Documentation
        Reorganization plan (agreed Session 83) now FULLY COMPLETE. No
        project code work.
    84  Reorg Sessions 1-3 (all in one sitting): split SESSION_HANDOVER.md
        into itself + SESSION_HISTORY_ARCHIVE.md; trimmed DECOR_PROJECT.md
        (2,056 → 643 lines); topic-split RAILS_SPECIFICS.md into itself
        (core, v4.0) + new RAILS_UI.md/RAILS_TESTING.md/RAILS_MISC.md. No
        project code work. See "Documentation Reorganization — Status"
        above.
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
    79  Storage Locations: design consultation (7 questions answered) +
        Session A (migration/model/fixtures/tests). Implemented, tested,
        DEPLOYED.
    78  Admin dropdown-siblings fix; Connection form Owner Part Number gap;
        real nav-logo-centering bug fixed (reported bug was a red herring).
        Code-complete, NOT YET placed/tested/committed — see Open Checklists.
    77  Six small UI/search bug fixes + a real nav-dropdown z-index fix.
        One bug (admin dropdowns not closing siblings) reported but not
        diagnosed, picked up in 78. Code-complete, NOT YET placed/tested/
        committed — see Open Checklists.
    76  Component/Peripheral dropdown fixes (4 rounds), Tom Select sort-order
        bug fixed project-wide, CI-caught StaleElementReferenceError fixed.
        Also: Ulli confirmed Sessions 73 and 75 fully deployed.

**Sessions 59–75 and earlier:** one-line log entries have aged off this
rolling list. Full narrative for every one of them (including 65 Component
order_number bulk maintenance, 67 Component Suggestions Phase 4, 69 UI
Terminology Rename, 70 Owner Part Number, 72 CI Security fix, 73 Category
Help Pages, 75 three UI bug fixes) remains in **SESSION_HISTORY_ARCHIVE.md**,
unchanged and complete — nothing described in those sessions has been
lost, only removed from this rolling view.

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
COMMON_BEHAVIOR.md v3.0 for the full rule and the real example.

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
**RAILS_UI.md** for the full rule and the real example (moved there from
RAILS_SPECIFICS.md in the Session 84 topic-split).

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
See **RAILS_TESTING.md** for the full rule (moved there from
RAILS_SPECIFICS.md in the Session 84 topic-split).

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

See SESSION_HISTORY_ARCHIVE.md for the full incident narrative (previously
"SESSION_HANDOVER v64.0" — that version is superseded; the underlying rule
and example now live in **RAILS_TESTING.md**'s "NOT NULL Boolean Columns"
section, moved there from RAILS_SPECIFICS.md in the Session 84 topic-split).

---

## Priority 1 — Future Sessions

1. **Storage Locations Session E** — resume when ready. An uncommitted,
   unreviewed draft already covers Computers/Peripherals (see "Open
   Checklists" above for the exact remaining steps: pre-commit checklist
   on the existing draft, then write the matching Components and
   SoftwareItems equivalents, then the git workflow for all three
   together). Session D (Privacy Audit) is now COMPLETE — nothing further
   needed there. Session F (export/import) remains genuinely NOT STARTED
   and is unaffected — see DECOR_PROJECT.md "Storage Locations Feature —
   Session Plan."
2. **Sessions 77 + 78's combined checklist** — see "Open Checklists" above.
3. **System tests Track 2** — Tom Select combobox, admin CRUD flows, full auth flow.
4. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
5. **Account deletion + data export** (GDPR).
6. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
7. **BulkUploadService stale model references** — low priority.
8. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
   `production.rb` to the app's public hostname.

---

**End of SESSION_HANDOVER.md**
