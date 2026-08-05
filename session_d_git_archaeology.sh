#!/bin/bash
# decor/session_d_git_archaeology.sh - version 1.0
# Session 83 [Storage Locations Session D] — Privacy Audit follow-up.
#
# Purpose: investigate the computers_helper.rb v1.9 anomaly found while
# auditing the owner-facing read-only views — that file already contains
# Session E-scoped Storage Location filter helpers and a comment claiming
# "privacy audit passed Session D", even though SESSION_HANDOVER.md and
# DECOR_PROJECT.md both record Session D and Session E as NOT STARTED, and
# components_helper.rb / software_items_helper.rb have no matching code.
#
# This script does NOT change anything — read-only git inspection commands
# only. Run it from the decor/ project ROOT (the directory containing
# app/, config/, etc.) — NOT from decor/export/.
#
# Output: prints to the terminal AND writes everything to
#   decor/export/session_d_git_archaeology_report.txt
# so the whole thing can be copy/pasted or uploaded back in one file.

set -u
set -o pipefail
# NOTE: deliberately NOT using `set -e` here. Several of these git commands
# (especially the --grep sweeps) are expected to legitimately return no
# matches, and some environments' `git log` exits non-zero on an empty
# result set for certain pathspec combinations. We want every section to
# run regardless of whether an earlier one found anything, so failures are
# reported inline instead of aborting the whole script.

mkdir -p export
REPORT="export/session_d_git_archaeology_report.txt"
: > "$REPORT"  # truncate/create fresh

section() {
  echo "" | tee -a "$REPORT"
  echo "================================================================================" | tee -a "$REPORT"
  echo "$1" | tee -a "$REPORT"
  echo "================================================================================" | tee -a "$REPORT"
}

run() {
  # Runs a command, tees output to both terminal and report file, and
  # records whether it succeeded — without aborting the script on failure.
  echo "\$ $*" | tee -a "$REPORT"
  if ! "$@" 2>&1 | tee -a "$REPORT"; then
    echo "(command exited non-zero — see output above; script continuing)" | tee -a "$REPORT"
  fi
}

# --- Sanity check: confirm we're at the project root, not inside export/ ---
if [ ! -d "app" ] || [ ! -d ".git" ]; then
  echo "ERROR: this doesn't look like the decor/ project root (no app/ or .git/ found)."
  echo "Run this script from inside decor/, e.g.:"
  echo "  cd decor && bash session_d_git_archaeology.sh"
  exit 1
fi

section "STEP 1 — Commit history for computers_helper.rb"
run git log --oneline -- app/helpers/computers_helper.rb

section "STEP 2a — Commit history for components_helper.rb (comparison)"
run git log --oneline -- app/helpers/components_helper.rb

section "STEP 2b — Commit history for software_items_helper.rb (comparison)"
run git log --oneline -- app/helpers/software_items_helper.rb

section "STEP 3 — Full diff of the most recent computers_helper.rb commit"
LAST_COMMIT=$(git log -1 --format=%H -- app/helpers/computers_helper.rb 2>/dev/null)
if [ -n "${LAST_COMMIT:-}" ]; then
  echo "Most recent commit touching computers_helper.rb: $LAST_COMMIT" | tee -a "$REPORT"
  run git show "$LAST_COMMIT"
else
  echo "No commit history found for computers_helper.rb (uncommitted / untracked?)." | tee -a "$REPORT"
fi

section "STEP 4a — Which branches contain that commit"
if [ -n "${LAST_COMMIT:-}" ]; then
  run git branch -a --contains "$LAST_COMMIT"
else
  echo "Skipped — no commit hash from Step 3." | tee -a "$REPORT"
fi

section "STEP 4b — Does main's own history include changes to this file"
run git log --oneline main -- app/helpers/computers_helper.rb

section "STEP 5a — Broad sweep: any commit anywhere mentioning 'Storage Location'"
run git log --all --oneline --grep="Storage Location" -i

section "STEP 5b — Broad sweep: any commit anywhere mentioning 'Session E'"
run git log --all --oneline --grep="Session E" -i

section "STEP 6 — Uncommitted changes in the working tree right now"
run git status

section "DONE"
echo "Full report written to: $REPORT" | tee -a "$REPORT"
echo "Upload that one file back — no need to paste each section separately." | tee -a "$REPORT"
