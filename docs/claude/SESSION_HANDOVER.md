# decor/docs/claude/SESSION_HANDOVER.md
# version 94.0
# Session 93: Two pieces of work.
#   (1) Ulli declared all other open work "finished" at session start —
#   Sessions 77+78's combined checklist, Session 89's Owner Part Number
#   display fix, and the Session 68 GAP NOTICE are all closed per this
#   explicit instruction, NOT because the underlying placement/testing/
#   deploy work was newly verified this session. If any of them resurface
#   later, they'll be dealt with fresh rather than treated as carried-over
#   unfinished business — see "Open Checklists" below, which now reflects
#   this closure.
#   (2) Implemented Storage Locations Session F (export/import) — the last
#   remaining piece of the Storage Locations feature. Delivered via
#   Pre-Implementation Verification: an export script pulled
#   owner_export_service.rb, owner_import_service.rb,
#   all_owners_export_service.rb, data_transfers/show.html.erb,
#   owner_export_service_test.rb, owner_import_service_test.rb,
#   storage_location.rb, computer.rb, component.rb, software_item.rb,
#   owner.rb, and storage_locations.yml before any code was written.
#   New "! --- storage_locations ---" CSV section (natural key: name,
#   per PROGRAMMING_GENERAL.md's stable-unique-key rule — no synthetic ID),
#   exported first and imported first (dependency ordering). New
#   "storage_location" column appended as the LAST column on the
#   computers/peripherals, components, and software CSV sections. Import
#   auto-creates an unrecognized storage_location name on any referencing
#   row (confirmed design decision, DECOR_PROJECT.md Session F) — never a
#   row error, at worst a row_warning if the name itself fails validation
#   (e.g. over 50 characters), with the parent record still saved without
#   a location in that case.
#     decor/app/services/owner_export_service.rb           v1.11 -> v1.12
#     decor/app/services/owner_import_service.rb            v1.12 -> v1.13
#     decor/app/services/all_owners_export_service.rb        v1.1 -> v1.2
#     decor/app/views/data_transfers/show.html.erb            v1.9 -> v1.10
#     decor/test/services/owner_export_service_test.rb        v2.0 -> v2.1
#     decor/test/services/owner_import_service_test.rb        v1.9 -> v1.10
#
#   BUG FOUND AND FIXED (pre-existing, unrelated to Storage Locations
#   itself — discovered opportunistically while touching
#   all_owners_export_service.rb for the storage_location column):
#   CSV_HEADERS in that file derives from
#   OwnerExportService::COMPUTER_SECTION_HEADERS, which Session 70 widened
#   to add owner_part_number. CSV_HEADERS grew to match automatically at
#   that time, but the to_csv row-building array was NEVER updated to
#   match — it kept pushing only 9 values with no owner_part_number. Every
#   row in the admin-wide "All Owners" export has been silently misaligned
#   since Session 70: the header promised owner_part_number in column 5,
#   but the actual value there was serial_number's, shifting every
#   subsequent column by one. Same "single source of truth / touch N
#   places, miss one" shape as the Session 89 components/show.html.erb gap.
#   Fixed in the same v1.2 change as the storage_location column addition.
#     decor/app/services/all_owners_export_service.rb  (fix included in
#       the v1.1 -> v1.2 bump above)
#
#   SECOND BUG FOUND AND FIXED (found via Ulli's manual browser check after
#   the pre-commit checklist passed): importing a CSV containing ONLY new
#   storage_location rows (or only a new storage_location reference on an
#   otherwise-unchanged computer/component/software row) produced the
#   flash message "Nothing to import — all records already exist.", even
#   though OwnerImportService had created and saved the location(s).
#   Root cause: build_success_message in BOTH
#   decor/app/controllers/data_transfers_controller.rb AND
#   decor/app/controllers/admin/data_transfers_controller.rb (the
#   owner_collection branch) hardcode a fixed list of count fields to
#   check, and storage_location_count was never added to either list —
#   same "touch N places, miss one" shape as the bug above, and the SECOND
#   time this exact pair of files has independently missed the same new
#   count field (v1.3 of the admin controller already fixed an identical
#   omission of connection_group_count/software_item_count, Session 48).
#   Fixed by adding a storage_location_count line to both files' `parts`
#   list, with an explicit "every new count field needs a line in BOTH
#   copies, same change" comment added to each to make the next recurrence
#   less likely.
#     decor/app/controllers/data_transfers_controller.rb          v1.6 -> v1.7
#     decor/app/controllers/admin/data_transfers_controller.rb    v1.4 -> v1.5
#
#   Pre-commit checklist (bin/rails test, rubocop -A + rubocop, brakeman,
#   bundle-audit) confirmed passing by Ulli for the six Session F files.
#   Manual browser check surfaced the flash-message bug above; the two
#   controller fixes were delivered and Ulli confirmed "all fine now" —
#   but the RE-RUN of the full pre-commit checklist against the two
#   controller fixes, and the full git workflow (branch → commit → push →
#   PR → CI → merge) plus kamal deploy for all eight files together, were
#   NOT explicitly confirmed step-by-step in this session and remain open
#   checklist items below (flagged rather than assumed, per Never-Guess).
#   Test coverage for the two controller fixes (build_success_message) was
#   offered but not completed this session — Ulli moved straight to
#   wrap-up; flagged as a pending Test Coverage Check item below.
# Session 92 (ad-hoc, closes out the StorageLocation Show Page work from
#   Sessions 90-91): Ulli ran the full test suite after Session 91's
#   wrap-up and hit one failure: StorageLocationsControllerTest's "show
#   displays the Components section..." test raised
#   `TypeError: no implicit conversion of nil into String` inside
#   `response_helpers.rb`'s `assert_body_includes`. Diagnosed via
#   Pre-Implementation Verification (export script pulling the test file,
#   controller, view, response_helpers.rb, all four fixture files, and
#   authentication_helper.rb before proposing any fix) rather than
#   guessing from the stack trace alone. Root cause: decor/test/fixtures/
#   components.yml v1.5 never sets `order_number` on ANY component
#   fixture (unlike computers.yml, where every fixture sets it
#   explicitly) — so `components(:pdp11_memory).order_number` was `nil`,
#   and `assert_body_includes(nil)` called `response.body.include?(nil)`,
#   which raises this exact TypeError (the `nil` is the argument to
#   `include?`, not `response.body` itself — worth noting since the
#   surface symptom looks like a nil response body). Fixed with a single
#   line in the test's own `update!` call, adding
#   `order_number: "ORD-COMPONENT-1"` alongside the `owner_part_number`
#   override already there — consistent with the test file's own stated
#   v1.1 design of never touching shared fixture `.yml` files. No
#   controller/view/model change needed; no fixture file modified.
#   decor/test/controllers/storage_locations_controller_test.rb v1.1 ->
#   v1.2. Ulli then confirmed `bin/rails test` passing, confirmed the
#   `show` route shape via `bin/rails routes | grep storage_location`
#   (plain RESTful member route, no namespace-prefix quirks — the
#   remaining open item from Session 91's checklist), confirmed
#   routes.rb v3.9 and _storage_location.html.erb v1.2 placement via a
#   manual browser check, and completed the FULL git workflow (branch ->
#   commit -> push -> PR -> CI -> merge) plus `kamal deploy` for all five
#   files together. **The StorageLocation Show Page feature (Sessions
#   90-91-92) is now FULLY COMPLETE: committed, tested, lint/
#   security-scanned, merged, and DEPLOYED.** No new rule-document content
#   needed — the diagnosis and fix both followed existing rules
#   (Pre-Implementation Verification / Never-Guess for the diagnosis;
#   PROGRAMMING_GENERAL.md's "Derive Test Assertions from Data" pattern
#   already justified fixing it in-test rather than touching the shared
#   fixture).
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

**Date:** August 8, 2026 (Session 93: implemented Storage Locations
  Session F — export/import, the last remaining piece of the Storage
  Locations feature. Found and fixed two pre-existing bugs opportunistically
  while implementing it: a column-misalignment bug in
  all_owners_export_service.rb dating to Session 70, and a duplicated
  missing-count-field bug in both data_transfers_controller.rb and
  admin/data_transfers_controller.rb's success-message builders, found via
  Ulli's manual browser check. Ulli confirmed the pre-commit checklist
  passed for the six Session F files and confirmed "all fine now" after
  the two controller fixes. Also: Ulli declared Sessions 77+78's combined
  checklist, Session 89's Owner Part Number display fix, and the Session
  68 GAP NOTICE all "finished" at session start — closed per that explicit
  instruction, not because the underlying work was newly verified. See
  this session's own changelog entry above for full detail.)
**Branch:** main (Sessions 1–76, Storage Locations A–E, and the
  StorageLocation Show Page are all previously confirmed committed, pushed,
  merged, and DEPLOYED.) **Storage Locations Session F — six files
  delivered and pre-commit-checklist-passed
  (owner_export_service.rb v1.12, owner_import_service.rb v1.13,
  all_owners_export_service.rb v1.2, data_transfers/show.html.erb v1.10,
  owner_export_service_test.rb v2.1, owner_import_service_test.rb v1.10)
  plus two controller bug-fix files delivered after a manual-browser-check
  finding (data_transfers_controller.rb v1.7,
  admin/data_transfers_controller.rb v1.5) — but the git workflow (branch →
  commit → push → PR → CI → merge) and kamal deploy for all eight files
  together have NOT been explicitly confirmed as of this wrap-up.** Per
  Ulli's Session 93 declaration, Sessions 77+78's combined checklist,
  Session 89's Owner Part Number display fix, and the Session 68 GAP
  NOTICE are all now CLOSED (declared finished, not independently
  re-verified) — see "Open Checklists" below.
**Status:** **The Storage Locations feature (Sessions A through F plus the
  ad-hoc Show Page) is now CODE-COMPLETE across all planned pieces** — only
  Session F's final git workflow/deploy confirmation remains open (see
  "Open Checklists" below). Two bugs found and fixed during Session F's
  implementation (see this session's changelog entry) are both part of the
  same not-yet-deployed batch. Test coverage for the two controller
  build_success_message fixes is a pending item (see "Open Checklists").
  Per Ulli's Session 93 declaration, all previously-open items EXCEPT
  Storage Locations Session F are now closed — see "Open Checklists" below
  for the updated record.

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

**Closed (Session 93):** Ulli declared this notice "finished" alongside
all other open work at the start of Session 93. The underlying documentation
gap itself has NOT been reconstructed or resolved — this closure means the
gap is no longer tracked as open business, not that a "Session 68 Summary"
was found or written. If it needs revisiting later, treat it as a fresh
request.

**Update (Session 72):** Ulli confirmed the underlying code for Sessions
67–70 has all been committed, pushed, merged, and deployed to `main` —
this documentation gap does not block or affect the code, which is live —
but is left flagged in case Ulli wants to reconstruct it later from source
history.

---

## Open Checklists

### Storage Locations Session F — CODE COMPLETE, deploy status open

    decor/app/services/owner_export_service.rb                  v1.12
    decor/app/services/owner_import_service.rb                   v1.13
    decor/app/services/all_owners_export_service.rb               v1.2
    decor/app/views/data_transfers/show.html.erb                    v1.10
    decor/test/services/owner_export_service_test.rb                v2.1
    decor/test/services/owner_import_service_test.rb                v1.10
    decor/app/controllers/data_transfers_controller.rb                v1.7
    decor/app/controllers/admin/data_transfers_controller.rb           v1.5

    [x] Place all eight files
    [x] bin/rails test / rubocop -A + rubocop / brakeman / bundle-audit —
        confirmed passing by Ulli for the first six files
    [x] Manual browser check — surfaced the "Nothing to import" flash-
        message bug (see Session 93's changelog entry); fixed by the two
        controller files above; Ulli confirmed "all fine now" after the fix
    [ ] Re-run bin/rails test / rubocop / brakeman / bundle-audit against
        the two controller fixes specifically (not explicitly re-confirmed
        this session)
    [ ] Test coverage for build_success_message's storage_location_count
        fix in BOTH controllers — offered, not yet written (needs
        decor/test/controllers/data_transfers_controller_test.rb and
        decor/test/controllers/admin/data_transfers_controller_test.rb;
        neither was uploaded this session)
    [ ] git workflow: branch → commit → push → PR → CI → merge (all eight
        files together)
    [ ] kamal deploy

**This closes out the Storage Locations Feature — Session Plan A-F.** Once
the checklist above is complete, DECOR_PROJECT.md's Session F section
should be updated from "code-complete, pending deploy" to "DONE ✓."

### Sessions 77 + 78 — CLOSED (declared finished, Session 93, per Ulli's
    explicit instruction — NOT independently re-verified)

Full narrative for both sessions remains in SESSION_HISTORY_ARCHIVE.md
("Session 77 Summary", "Session 78 Summary"). The file-placement/test/
commit/deploy status documented in prior versions of this section was
never independently confirmed — Ulli chose to close this out at the start
of Session 93 rather than have it carried forward indefinitely. If any of
the specific fixes described in those two sessions turn out to be missing
in a future session, treat it as a fresh bug report, not as "Session 77/78
was never finished."

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

No further action needed — Session E is closed out.

### StorageLocation Show Page (Sessions 90-91-92) — COMPLETE

Not part of the original A-F Session Plan — a direct feature request from
Ulli, reversing Session B's original "no show page" decision now that
Session C's associations make it easy. Session 91 reworked Session 90's
flat alphabetical list into four category-grouped sections with full
identifying fields, per Ulli's feedback that the flat list wasn't enough
to identify an item. Session 92 fixed a test-fixture-data bug found when
Ulli ran the full suite and completed the full git workflow and deploy.

**Final file versions, all committed/pushed/merged/DEPLOYED (Session 92,
confirmed by Ulli):**

    decor/config/routes.rb                                          v3.9
    decor/app/controllers/storage_locations_controller.rb           v1.3
    decor/app/views/storage_locations/show.html.erb                   v1.1
    decor/app/views/storage_locations/_storage_location.html.erb      v1.2
    decor/test/controllers/storage_locations_controller_test.rb      v1.2
      (v1.1 -> v1.2, Session 92: fixed a nil order_number bug in the
      Components-section test)

    [x] Place all five files
    [x] bin/rails test / rubocop / brakeman / bundle-audit / manual
        browser check — ALL PASSED (test file's own bug fixed Session 92)
    [x] bin/rails routes | grep storage_location — confirmed plain
        RESTful member route shape, no namespace-prefix quirks
    [x] git workflow: branch → commit → push → PR → CI → merge — DONE
    [x] kamal deploy — DONE

No further action needed — this feature is closed out. (Optional,
not-urgent follow-up noted Session 90 — loading RAILS_UI.md before future
Tailwind/CSS work on this feature — remains just a general habit reminder,
not a per-feature open item; see the "RELIABILITY NOTICE" section above.)

### Session 89 — Owner Part Number display fix — CLOSED (declared
    finished, Session 93, per Ulli's explicit instruction — NOT
    independently re-verified)

`decor/app/views/components/show.html.erb` v1.11 was delivered in Session
89 with its own placement/test/commit/deploy status left open. Closed per
Ulli's Session 93 declaration. If the Owner Part Number field turns out to
still be missing from a Component's show page in a future session, treat
it as a fresh bug report.

---

## Session Log (rolling — last ~12 sessions; full detail in SESSION_HISTORY_ARCHIVE.md)

Older entries drop off this list as new ones are added; nothing is lost —
every session ever logged remains in SESSION_HISTORY_ARCHIVE.md regardless
of whether it still appears here.

    93  Ulli declared all other open work "finished" at session start
        (Sessions 77+78, Session 89's display fix, Session 68 GAP NOTICE —
        all closed per explicit instruction, not re-verified). Implemented
        Storage Locations Session F (export/import): new
        storage_locations CSV section (natural key: name, exported/
        imported first) and a storage_location column appended to
        computers/peripherals/components/software sections; import
        auto-creates an unrecognized referenced name. Found and fixed two
        pre-existing bugs opportunistically: a Session-70-dating column-
        misalignment bug in all_owners_export_service.rb (owner_part_number
        was in CSV_HEADERS but never in the row-building array), and a
        duplicated missing-count-field bug in both
        data_transfers_controller.rb and admin/data_transfers_
        controller.rb's build_success_message (storage_location_count
        omitted from both, found via Ulli's manual browser check — a CSV
        containing only new storage locations reported "Nothing to
        import"). Six Session F files passed the full pre-commit checklist;
        two controller fixes delivered after the browser-check finding,
        Ulli confirmed "all fine now." git workflow and kamal deploy for
        all eight files, plus a re-run of the checklist against the two
        controller fixes and new test coverage for
        build_success_message, remain open.
    92  Ad-hoc bug fix closing out the StorageLocation Show Page feature:
        Ulli's full test run hit a TypeError in the Components-section
        test caused by components.yml never setting order_number on any
        fixture. Fixed with a one-line in-test update! addition
        (storage_locations_controller_test.rb v1.1 -> v1.2), no fixture
        or app code touched. Ulli then confirmed tests passing, confirmed
        the show route's plain shape via bin/rails routes, confirmed
        routes.rb/_storage_location.html.erb placement via manual browser
        check, and completed the full git workflow + kamal deploy for all
        five files. StorageLocation Show Page feature now FULLY COMPLETE.
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

**Sessions 59–80 and earlier:** one-line log entries have aged off this
rolling list. Full narrative for every one of them (including Session 80's
owner-facing CRUD, Session 79's design consultation + Session A, 76
dropdown fixes, 77/78 UI bug fixes, and everything before) remains in
**SESSION_HISTORY_ARCHIVE.md**, unchanged
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

1. **Storage Locations Session F — finish the deploy checklist.** Code is
   complete and the six-file pre-commit checklist passed; two controller
   bug fixes were added after a manual-browser-check finding. Remaining:
   re-run the checklist against the two controller fixes, write test
   coverage for build_success_message's storage_location_count handling in
   both controllers, then the full git workflow and kamal deploy for all
   eight files together. See "Open Checklists" above for the itemized list.
2. **System tests Track 2** — Tom Select combobox, admin CRUD flows, full auth flow.
3. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
4. **Account deletion + data export** (GDPR).
5. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
6. **BulkUploadService stale model references** — low priority.
7. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
   `production.rb` to the app's public hostname.

(Sessions 77+78's combined checklist and Session 89's Owner Part Number
display fix are REMOVED from this list — both closed per Ulli's Session 93
declaration; see "Open Checklists" above. **StorageLocation show page
(Sessions 90-91-92) is now FULLY COMPLETE** — removed from this list; see
"Open Checklists" above for the closed-out
record.)

---

**End of SESSION_HANDOVER.md**
