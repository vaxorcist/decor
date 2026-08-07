# SESSION_HANDOVER_delta_session89.md
# Manually-mergeable delta for decor/docs/claude/SESSION_HANDOVER.md
# Target version after merge: v90.0 (currently v88.0)
# Generated Session 89 due to 90% token budget warning. Supersedes the
# still-unmerged SESSION_HANDOVER_delta_session88.md — apply Steps 1-6
# below (carried over verbatim from that file) FIRST, then apply Steps
# 7-9 (new this session). Do not apply the old Session 88 delta file
# separately.

═══════════════════════════════════════════════════════════════════════════
STEPS 1-6 (carried over unchanged from the unmerged Session 88 delta —
apply exactly as originally written, in order; full text already in
Ulli's possession in SESSION_HANDOVER_delta_session88.md, not repeated
here to save budget this session):
═══════════════════════════════════════════════════════════════════════════

1. INSERT the Session 88 changelog block at the top, above "# Session 87:".
2. REPLACE the Date/Branch/Status block with the Session 88 wording.
3. REPLACE the "### Storage Locations Session E — IN PROGRESS, PAUSED..."
   section with "### Storage Locations Session E — COMPLETE (Session 88)".
4. Cosmetic-only Session F wording tweak (optional, as noted in the
   original delta).
5. INSERT the "88  Resumed and COMPLETED..." line at the top of the
   Session Log, DROP the oldest line ("76  Component/Peripheral...").
6. REPLACE Priority 1 item 1 with the "Storage Locations Session F
   (export/import)" wording.

═══════════════════════════════════════════════════════════════════════════
STEP 7 (new this session): INSERT this new changelog block at the very
top of the file, ABOVE the Session 88 block you just inserted in Step 1
(i.e. it becomes the newest entry):
═══════════════════════════════════════════════════════════════════════════

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
#   COMMON_BEHAVIOR.md's Session 89 reinforcement note (delta pending
#   merge — see COMMON_BEHAVIOR_delta_session89.md) for the rule
#   reinforcement this produced. No new rule was needed — the existing
#   rule already covered this; the miss was a one-off application error.
#   Session ended at ~90% token budget (per Ulli's report of the system
#   warning) — this session's own rule-document updates are delivered as
#   manually-mergeable deltas (this file + COMMON_BEHAVIOR_delta_session89.md
#   + DECOR_PROJECT_delta_session89.md) rather than full regenerated files,
#   per the "Token budget awareness" / handover-mode rule. Ulli should
#   merge these (which also fold in the still-pending Session 88 deltas —
#   see each delta file's own "STEPS 1-N carried over" section) and start
#   a fresh conversation for Session 90.

═══════════════════════════════════════════════════════════════════════════
STEP 8 (new this session): REPLACE the "**Date:**" / "**Branch:**" /
"**Status:**" block (as it reads after Step 2 above, dated August 5, 2026,
Session 88) with:
═══════════════════════════════════════════════════════════════════════════

**Date:** August 5, 2026 (Session 89: ad-hoc bug fix only — Components
  show page was missing Owner Part Number; fixed and revised per Ulli's
  layout feedback. Unrelated to the Storage Locations plan. See the
  Session 89 changelog entry above for full detail. Session ended at
  ~90% token budget — this session's rule-document updates are deltas,
  not full files; see the note at the end of that changelog entry.)
**Branch:** main (Sessions 1-76, and Storage Locations Sessions A, B, C,
  D, and E, are ALL committed, pushed, merged, and DEPLOYED — confirmed by
  Ulli as of Session 88). Sessions 77 and 78's own work (11 files) status
  is UNCHANGED and remains open — see "Open Checklists" below. **Session
  89's single file (components/show.html.erb v1.11) has been delivered to
  Ulli but its own placement/test/commit/deploy status is NOT YET
  confirmed as of this note** — a plain single-file view change, not
  expected to need the full multi-file checklist treatment, but Ulli
  should still run it through bin/rails test / rubocop / manual browser
  check before committing, per the standard Testing Workflow in
  PROGRAMMING_GENERAL.md. Storage Locations Session F (export/import)
  remains genuinely NOT STARTED.
**Status:** Sessions 1-76, and Storage Locations Sessions A-E, fully
  closed out and deployed. Sessions 77+78's combined checklist remains
  open (unchanged). **Session 89's Owner Part Number display fix
  (components/show.html.erb v1.11) is code-complete and delivered but NOT
  YET placed/tested/committed/deployed** — a single-file, view-only
  change; add to whichever session's git workflow batch Ulli chooses to
  run next (it doesn't depend on or block Sessions 77/78 or Storage
  Locations F). Storage Locations Session F remains the only open item in
  that feature's plan. The GAP NOTICE below (Session 68's missing formal
  summary) remains open and unaffected by any of this.

═══════════════════════════════════════════════════════════════════════════
STEP 9 (new this session): in "## Session Log (rolling...)", INSERT this
new line at the TOP of the list (above the "88  Resumed and COMPLETED..."
line from Step 5), and DROP the current oldest line to keep the window at
~10 entries (check which line is oldest after Step 5's own drop is
applied — it will be the line that was second-oldest before this step):
═══════════════════════════════════════════════════════════════════════════

    89  Ad-hoc bug fix (unrelated to Storage Locations): Components show
        page was missing Owner Part Number, present since Session 70 but
        never added to this view (same single-source-of-truth shape as
        prior sessions). Fixed via Pre-Implementation Verification export
        script + comparison against the known-working computers/show.html.erb.
        components/show.html.erb v1.9 -> v1.11 (v1.10 added the field
        standalone; v1.11 revised to place it side by side with Trade
        Status per Ulli's layout feedback). Caught and corrected a
        misapplied @-encoding on a single-file delivery mid-session — see
        COMMON_BEHAVIOR.md Session 89 note. Session ended at ~90% token
        budget; rule-doc updates delivered as deltas.

═══════════════════════════════════════════════════════════════════════════
End of delta. After merging Steps 1-9, bump the file's own version-header
comment from "version 88.0" to "version 90.0" (not 89.0 — that
intermediate version was never actually shipped as a merged file).
═══════════════════════════════════════════════════════════════════════════
