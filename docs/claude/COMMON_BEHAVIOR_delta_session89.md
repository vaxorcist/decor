# COMMON_BEHAVIOR_delta_session89.md
# Manually-mergeable delta for decor/docs/claude/COMMON_BEHAVIOR.md
# Target version after merge: v4.2 (currently v4.0)
# Generated Session 89 due to 90% token budget warning. Supersedes the
# still-unmerged COMMON_BEHAVIOR_delta_session88.md — apply BOTH steps
# below in order; do not apply the old Session 88 delta file separately,
# it is fully incorporated as Step 1 here.

═══════════════════════════════════════════════════════════════════════════
STEP 1 (carried over from the unmerged Session 88 delta — apply first):
In the "### File Transfer Protocol — Export/Import Scripts (Session 71)"
section, AFTER the existing "**Reinforced (Session 78):**" paragraph,
INSERT:
═══════════════════════════════════════════════════════════════════════════

**Reinforced (Session 88):** Ulli asked that future sessions not generate
more than one export/import/placement script per exchange unless there is
a specific reason to split them. The protocol above already supports this —
one export script can pull files for several unrelated targets in a single
run (see the Session 88 export script, which pulled pattern files plus two
different target device types' files in one script), and one placement
script can place any number of delivered files regardless of how many
distinct features or device types they span. Splitting into multiple
scripts is the exception, not the default — reserve it for cases with a
genuine reason (e.g. two completely separate deliveries the user explicitly
wants to run at different times).

═══════════════════════════════════════════════════════════════════════════
STEP 2 (new this session): immediately AFTER the Step 1 paragraph you just
inserted, ADD this second paragraph:
═══════════════════════════════════════════════════════════════════════════

**Reinforced (Session 89):** the @-encoded flat-name scheme was applied to
a genuinely single-file, ad-hoc delivery (`components/show.html.erb`) with
no script and no other files in the same batch — caught immediately by
Ulli. No new rule is needed; the existing line above ("Single ad-hoc file
exchanges don't need a script... just name the one file normally") already
covers this exactly. The miss was applying multi-file habit to a
single-file case rather than checking which situation actually applied.
Worth an explicit check at delivery time, before naming any output file:
"is this a script-driven multi-file batch, or one ad-hoc file?" — only the
former gets @-encoding.

═══════════════════════════════════════════════════════════════════════════
After merging both steps, bump the file's own version-header comment from
"version 4.0" to "version 4.2" (not 4.1 — that intermediate version was
never actually shipped as a merged file), and add two one-line pointers in
the file's own top-of-file changelog comment block: one for the Session 88
addition (multi-target export scripts), one for the Session 89 addition
(single-file @-encoding reinforcement).
═══════════════════════════════════════════════════════════════════════════
