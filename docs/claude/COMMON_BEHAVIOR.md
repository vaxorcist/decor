# decor/docs/claude/COMMON_BEHAVIOR.md - version 4.2
# Session 90 (wrap-up): No new rule content. Reinforcement note added below
#   confirming the Session 89 single-ad-hoc-file @-encoding rule worked as
#   intended this session — Claude initially named a delivered file with
#   the @-encoding out of habit, self-caught it before presenting (no user
#   prompt needed this time), and redelivered under the plain filename.
#   Also: this session did view/CSS work (a Tailwind link-color class) and
#   flagged that RAILS_UI.md was not loaded first, per the topic-index
#   rule in RAILS_SPECIFICS.md v4.0 — see SESSION_HANDOVER.md's Session 90
#   entry for the resulting process note (out of scope for this file: no
#   COMMON_BEHAVIOR.md rule was broken, RAILS_SPECIFICS.md's own topic-load
#   rule was).
# Session 89: Merged into the "File Transfer Protocol" section below — see
#   the "Reinforced (Session 89)" paragraph. Also bumped version 4.1 → 4.2
#   is skipped in this history note since 4.1 was never itself shipped as
#   a merged file (delta_session88 was unmerged when delta_session89 was
#   generated); this file jumps 4.0 → 4.2 directly, folding in both.
# Session 88: Merged into the "File Transfer Protocol" section below — see
#   the "Reinforced (Session 88)" paragraph (multi-target export scripts;
#   splitting into multiple scripts is the exception, not the default).
# Session 85 (Reorg 4 of 4, plan agreed Session 83, concludes the reorg):
#   Trimmed this file per the agreed plan (see SESSION_HANDOVER.md
#   "Documentation Reorganization — Status"). Every rule's "Real example" /
#   "Why this rule exists" narrative paragraph was condensed to one line —
#   rule statements, checklists, and code/format examples (load-bearing for
#   Pre-Implementation Verification and Response Formatting) are unchanged.
#   The "AI Forgetfulness" section (pure rationale, no rule/example content)
#   was tightened but not gutted — it explains why the mechanical rules
#   below it exist. Full original narrative for every trimmed item remains
#   recoverable via git history of this file prior to Session 85.
# Sessions prior to 85: see git history of this file for the full
#   per-session changelog (Sessions 14, 16, 18, 20, 36, 54, 55, 67, 69, 71,
#   74 each added or reinforced a rule below).

**Universal Rules for All Interactions with This User**

**Last Updated:** August 5, 2026 (v4.2: Session 88+89 File Transfer
  Protocol reinforcements merged; Session 90 added a confirming note only,
  no new rule content)

---

## Skill and Rule Document Changes — MANDATORY PROTOCOL

### Before modifying any skill or rule document:
- ✅ Present the proposed change and explain the reasoning
- ✅ Wait for explicit user approval before making any edit
- ❌ NEVER modify a skill or rule document without prior approval

### After modifying any skill or rule document:
- ✅ Present the complete updated file as a downloadable file using present_files
- ✅ The user cannot inspect skill files directly in the web UI — a download is the only way they can review what changed
- ❌ NEVER assume the user can see the change without a download link

**Real example (Session 16):** the `decor-session-rules` skill was modified
twice without prior approval or a download link, and the user had to ask
for both explicitly.

---

## Tool Availability — Never Infer, Always Test

### NEVER assume a tool is unavailable based on environment context descriptions

Environment context strings like "web interface", "mobile", or "chat" describe
the user-facing product — they say nothing about which tools are available to
Claude internally. Inferring tool availability from these descriptions is wrong
and causes silent fallback to incorrect alternatives.

**Real example (Session 16):** environment context said "web or mobile chat
interface"; Claude wrongly inferred `bash_tool` was unavailable and used
`web_fetch` with `file://` URLs instead — `bash_tool` was available the
whole time and simply never tried.

**The fix: test, don't reason.**

At every session start, run a trivial command before doing anything else:
```bash
echo "bash_tool OK"
```

- If it works → proceed normally
- If it fails → report the failure explicitly; do NOT silently substitute another tool

**RULE: A tool is unavailable only when a test command confirms it fails — not
because environment context suggests it might not be present.**

---

## Reading Rule Documents — MANDATORY

### ALWAYS use bash cat, NEVER the view tool for rule documents

The `view` tool truncates files that exceed ~16,000 characters and shows a
"truncated" notice — but only in Claude's internal output, not visibly to the user.
A truncated read is a partial read. Partial reads of rule documents mean rules are
missed. Missed rules cause failures that waste the user's time and tokens.

**RULE: Read ALL rule documents using `bash cat` at the start of every session.**

```bash
cat /mnt/user-data/uploads/COMMON_BEHAVIOR.md
cat /mnt/user-data/uploads/RAILS_SPECIFICS.md
cat /mnt/user-data/uploads/PROGRAMMING_GENERAL.md
cat /mnt/user-data/uploads/DECOR_PROJECT.md
cat /mnt/user-data/uploads/SESSION_HANDOVER.md
```

After reading each document, Claude MUST log the line count as confirmation:
`Read FILENAME — N lines, complete.`

**RULE: Read any other uploaded code or config file using `bash cat` as well.**

**RULE: This applies to skill files too.** Skill files read from `/mnt/skills/`
at session start must also be read via `bash cat` — never the `view` tool.
The truncation risk is identical regardless of where the file lives.

```bash
cat /mnt/skills/user/decor-session-rules/SKILL.md
```

`view` MAY be used for directory listings only — never for reading file content
that feeds into rule compliance or implementation decisions.

**Real examples:** DECOR_PROJECT.md was once read with `view` and silently
truncated mid-file without Claude noticing (Session 14); the
`decor-session-rules` skill was separately read with `view` instead of
`bash cat` even though it happened to be short enough not to truncate
(Session 36) — the tool choice is wrong regardless of file length.

---

## AI Forgetfulness — Why It Happens and How to Prevent It

### Why AIs are not simply "better at remembering than humans"

This is a common and reasonable assumption — but it is only partially true.

**What AIs genuinely do better:**
- Perfect recall of everything currently in the context window
- No fatigue, mood, or distraction effects
- Consistent application of explicit rules when they are actively in focus

**What AIs do poorly — and why:**
- **Attention is not uniform across the context window.** Content from the
  middle or end of a long document competes with everything else in the
  conversation; recent content and content near task instructions tends to
  dominate.
- **Rules read at session start decay in influence as the session grows.**
  The rule document read at turn 1 is still in context at turn 20 but its
  influence on generation is diluted by everything that followed.
- **Rules are not automatically cross-referenced at task time.** Unless a
  rule is actively triggered by a task keyword or checklist step, it can be
  bypassed.
- **Truncated reads compound the problem.** If a rule was never fully read,
  it cannot be applied — regardless of attention.

**What this means in practice:** the rules set is not self-enforcing. It requires:
1. Complete reads (bash cat, not view)
2. Explicit checklists that force rule recall at task time
3. The user's active intervention when rules are violated

**Claude's commitment:**
- Read all rule documents completely at session start (bash cat)
- Re-read the relevant sections of RAILS_SPECIFICS.md (or its topic files)
  before writing tests / view / mailer code
- Apply the Pre-Implementation Verification checklist without skipping steps
- When a rule failure occurs: acknowledge it specifically, correct it, and add it
  to the rule documents before end of session

---

## Flagging a Guess Does Not Satisfy Never-Guess (MANDATORY, learned Session 67)

**RULE: If a file's exact content is unknown, writing a plausible version
and labeling it as inferred/unverified is NOT a substitute for requesting
the actual file. It is still a guess — labeling it only shifts the burden
of verification onto the user instead of Claude asking for what's missing.**

The Never-Guess principle (SESSION_HANDOVER.md "NEVER GUESS RULE") already
covers path helpers, method names, and behavior. This rule closes a gap:
it applies equally to entire file contents, even when Claude is transparent
about the fact that it's guessing.

**Wrong — flagged but still shipped as a deliverable:**
```
[Claude writes index.turbo_stream.erb from the general Rails/Turbo
"append + replace" idiom, adds a comment block saying "FLAGGED — WRITTEN
FROM CONVENTION, NOT COPIED FROM AN EXISTING FILE... please diff this
against the real file before treating it as verified" — and delivers it
as a numbered file alongside genuinely-verified files in the same response.]
```

**Correct — ask for the file instead:**
```
"I don't have decor/app/views/software_items/index.turbo_stream.erb (or an
equivalent) to confirm this project's exact shape for this pattern. Could
you upload it? I'll write the new file from that rather than from the
general convention."
```

**Real example (Session 67):** `admin/component_suggestions/index.turbo_stream.erb`
was written from the standard Rails/Turbo convention, labeled as inferred
in its own header comment, and delivered alongside genuinely file-verified
files. The labeling didn't change what it was — a guess that put
verification work on the user instead of Claude asking for the real file
first. (It happened to match once uploaded — that was luck, not justification.)

**Reinforced (Session 90):** applied correctly under pressure — at
session wrap-up, two of the three uploaded delta files (`SESSION_HANDOVER_
delta_session89.md`, `DECOR_PROJECT_delta_session89.md`) referenced prior
"Session 88" delta files as already being in Ulli's possession and
containing text "not repeated here to save budget." Those Session 88 delta
files were never actually uploaded to this conversation. Rather than
reconstruct their content from the summary description (a real
temptation — the summaries were detailed enough to sound completable),
Claude flagged the gap explicitly and asked for the missing files instead
of merging from the description. This is the same shape as the Session 67
rule above, just applied to a rule-document *delta* file instead of an
`.erb` file.

---

## File Delivery — MANDATORY

### Always Present Files for Download

- ✅ EVERY new or updated file MUST be presented for download using the present_files tool
- ✅ This applies to ALL file types: .rb, .erb, .yml, .md, migrations, scripts, etc.
- ✅ Present the file IMMEDIATELY after creating/updating it — do not wait until end of response
- ✅ Multiple files in one response: present each one after it is created
- ❌ NEVER just show file contents in a code block without also presenting the download
- ❌ NEVER ask the user to copy/paste from a code block as a substitute for a download link

**Why this matters:** the user needs to place files directly into the
project. A download link is faster, safer, and less error-prone than
manual copy/paste from a code block.

### Always Specify Complete Paths

- ✅ ALWAYS specify the complete path (beginning with the project directory) when
  referring to, requesting, or delivering any file
- ✅ Format: `decor/path/to/filename.ext`
- ❌ NEVER refer to a file by its bare name only (e.g. `routes.rb` with no path)
- ❌ NEVER ask for a file without specifying its full path

Rails projects have many files with identical names in different directories
(`show.html.erb`, `_form.html.erb`, `index.html.erb`, etc.). Bare filenames
cause placement errors. Always give the full path.

**Real example (Session 14):** placement instructions for 11 delivered
files listed bare filenames only; the user had to ask for full paths.

### File Transfer Protocol — Export/Import Scripts (Session 71)

Replaces the old bare-filename/prefix-on-collision download rule, the old
per-file output-path-collision rule, and the old one-file-per-message upload
rule. All three existed to work around the same underlying problem — Rails'
repeated basenames (`_form.html.erb`, `index.html.erb`, etc.) across many
directories, plus the browser's dot-to-underscore mangling on upload. The
export/import script approach solves both problems structurally instead of
by naming convention, so the older workaround rules no longer apply.

**Encoding scheme:** flatten the full relative path (from the `decor/` root),
replacing `/` with `@`, and replacing every dot except the true file
extension's dot with `@` too — so each flattened name contains exactly one
literal `.`. One dot means the browser's upload mangling can't trigger, and
the full path being encoded means collisions can't happen either.
```
app/views/admin/component_suggestions/index.html.erb
  → app@views@admin@component_suggestions@index@html.erb
app/views/computers/_form.html.erb
  → app@views@computers@_form@html.erb
config/routes.rb
  → config@routes.rb
```

**When Claude needs files from the user:**
- ✅ Generate a shell script that copies the needed files from their real
  project locations into `decor/export/`, writing each with the @-encoded
  flat name above
- ✅ The script assumes it is run from within `decor/export/` — paths to the
  source files are relative (e.g. `../app/views/...`)
- ✅ Tell the user to run the script, then upload everything now sitting in
  `decor/export/` — no manual renaming needed, no collision risk
- ❌ Do NOT ask the user to hunt down and upload files one at a time anymore
- ❌ Do NOT ask the user to upload same-named files in separate messages —
  the flat @-encoding makes that workaround unnecessary

**When Claude delivers files to the user:**
- ✅ Write every delivered file using its @-encoded flat name, both as the
  path in `/mnt/user-data/outputs/` and as the download name shown via
  `present_files` — this single name serves both purposes now
- ✅ Also generate a placement shell script that copies each delivered file
  from `decor/import/` back to its real path under `decor/`
- ✅ The script assumes it is run from within `decor/import/` — destination
  paths are relative (e.g. `../app/views/...`) — and uses `mkdir -p` for any
  destination directory that doesn't exist yet
- ✅ Tell the user to move the delivered files into `decor/import/`, then run
  the script from inside that directory
- ❌ Do NOT apply the old bare-filename / `#`-prefix-on-collision naming to
  delivered files anymore — the @-encoded name is now the only naming rule
- ❌ Do NOT write two delivered files to the same output path — this is now
  structurally impossible under @-encoding (the full path is in the name),
  but stay alert regardless

**`decor/export/` and `decor/import/` are both `.gitignore`d** — both are
transient staging directories and are never committed.

**Single ad-hoc file exchanges don't need a script.** If only one file is
being requested or delivered in a response, a script is unnecessary ceremony —
just name the one file normally (full path stated in prose, correct dots per
the rule below). The script protocol is for **multi-file** transfers, which
is where the old rules were actually failing.

**Reinforced (Session 78):** a 2-file request was made as plain prose
instead of the mandatory export script — no new rule needed, just a plain
miss. Worth a deliberate check at request time: "is this more than one
file? If so, generate the script — don't just list filenames in prose."

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

**Reinforced (Session 90) — rule worked as intended:** a single ad-hoc
file (`storage_locations/_storage_location.html.erb`) was drafted with the
@-encoded name out of habit, but this time Claude self-caught the mistake
before presenting it to Ulli — no user correction needed — and redelivered
under the plain filename. Confirms the Session 89 reinforcement is doing
its job as an explicit pre-delivery check, not just a one-off fix.

### Output File Naming — Never Substitute Underscores for Dots

- ✅ When creating a file for download with `create_file`, use the **exact filename
  including all dots** (e.g. `application.html.erb`, not `application_html.erb`)
- ❌ NEVER substitute underscores for dots in output filenames

**Why this matters:** browsers substitute underscores for dots when the
user *uploads* a multi-dot file — that constraint is an upload-only
limitation. When Claude *creates* a file with `create_file`, it controls
the filename entirely and must use the correct name with dots.

**Real example (Session 54):** `application.html.erb` was created as
`application_html.erb` — the upload/download constraint was confused and
applied in the wrong direction.

---

## Response Formatting

### Start and End Separators
- ✅ Start EVERY response with 80 "=" (equals signs) characters
- ✅ End EVERY response with 80 "=" (equals signs) characters
- Format: `================================================================================`
- ❌ NEVER omit the separators — not for short responses, not for wrap-up responses

**Real example (Session 18):** the first substantive response of the
session (delivering 11 files) omitted both separators along with the
token estimate and misapplied two other formatting rules — none of the
four rules were new, the checklist simply wasn't checked.

### Token Usage Reporting

**Ground truth:** the UI is ALWAYS the authoritative source. Claude's estimates
are supplementary and must NEVER be used to reassure the user that capacity remains.

**Why Claude's estimates are structurally unreliable:**
Claude cannot see or measure:
- The system prompt (Anthropic's own instructions — likely tens of thousands of tokens)
- Tool definitions (present_files, bash_tool etc. schemas sent every request)
- API and conversation structure overhead
- How uploaded files actually tokenize on the server side

This invisible fixed base cost means Claude's naive count of visible content
will always be a significant undercount (Session 10: Claude estimated ~50%
when the UI showed 90%).

**Session-start floor rule:**
When 5 or more large rule/project documents are uploaded at session start,
the token estimate must NEVER be below 50% — the fixed base cost alone
justifies this floor before any conversation content is counted.
(Floor was 40% through Session 54; raised to 50% in Session 55.)

**Rules:**

✅ When a system warning IS visible:
- Use the EXACT numbers from `<system_warning>Token usage: X/Y; Z remaining</system_warning>`
- Format: `**Token Usage:** X / Y (Z% used, ~W remaining)`
- Never contradict or adjust a system warning with a manual calculation
- Once a system warning appears, anchor all further estimates to it

✅ When NO system warning is visible:
- Provide an estimate, but label it explicitly as rough and likely an undercount
- Apply a correction factor: multiply naive visible-content estimate by ~2
- Apply session-start floor: never below 50% when 5+ large documents are loaded
- Format: `**Token Usage (estimate):** ~X / 200,000 (~Y% used) — rough estimate only; trust your UI`
- Err HIGH rather than falsely reassuring
- Remind the user that the UI is the only reliable source

❌ NEVER:
- Stay silent just because no system warning is visible
- Omit the token estimate on a response that follows a file delivery
- Report 0% or "unknown"
- Suggest remaining capacity is comfortable based on an estimate alone
- Use estimates to reassure the user that there is plenty of room left

**Rough estimation guide (apply ×2 correction factor to the sum):**
- Each large uploaded document (~500 lines): ~5,000–8,000 tokens (before ×2)
- Each response of ~500 words: ~700 tokens (before ×2)
- Each code block of ~50 lines: ~500 tokens (before ×2)
- Context window: ~200,000 tokens for claude.ai

**Example:**
```
System warning present:
  Warning text:  Token usage: 93143/190000; 96857 remaining
  Correct report: **Token Usage:** ~93,000 / 190,000 (49% used, ~97,000 remaining)
  WRONG:          **Token Usage:** ~18,600 / 190,000 (9.8% used) ← contradicts warning

No system warning, 5 large docs loaded:
  Correct: **Token Usage (estimate):** ~80,000 / 200,000 (~50% used) — rough estimate
           only; trust your UI over this number
  WRONG:   **Token Usage (estimate):** ~8,000 / 200,000 (~4% used) ← ignores base cost
```

**Real example, recurred twice (Sessions 69 and 74):** a response
following a large multi-file delivery ended with a closing summary and
separator but no token estimate at all, both times caught only because
the user asked for it. Root cause both times: the closing block (both
separators AND the token line) isn't automatically applied to a response
that ends on a tool call or a follow-up question unless checked
explicitly as its own fixed step, separate from writing the substantive
content — this applies regardless of response length.

---

## Systematic Workflow

### For Every Task - Follow This Pattern:

**1. Analyze Requirements**
- Understand what's needed
- Make informed assumptions
- Identify what files/information are required

**2. Check Ruleset BEFORE Starting Work**
- Review all applicable rules
- Check for requirements that apply to this task type
- Don't skip this step!

**3. Execute the Work**
- Implement the solution
- Follow all applicable patterns and rules

**4. Re-Check Ruleset AFTER Completion**
- Some rules only become obvious during/after work
- Verify nothing was missed
- Iterate internally if needed

**5. Present Only Final Results**
- Do NOT present intermediate results
- Only show complete, verified solutions
- All internal iterations should be invisible to user

---

## Pre-Implementation Verification (MANDATORY)

**BEFORE implementing ANY solution, Claude MUST explicitly verify and state the following.**

### General Principle

Have all relevant files in hand before writing a single line of code. The specific
files needed depend on the framework and task type. See the appropriate framework
document for detailed checklists (e.g. RAILS_SPECIFICS.md for Ruby on Rails).

### For Writing Tests (generic):
- [ ] **I have seen the actual test data / fixtures used by this project**
      Do not assume fixture names, record counts, or data values.
- [ ] **I have seen existing test patterns to follow**
      Use the project's established patterns — do not invent new ones.
- [ ] **I have READ THE ACTUAL PARALLEL TEST FILE — not just the handover summary**
      Reading `computer_test.rb` before writing `computer_model_test.rb` would
      have immediately shown the correct enum assertion pattern. Summaries lie by
      omission. Always read the file.

### For Implementing Features (generic):
- [ ] **I have all files involved in this change**
      Not just the main file — also related helpers, partials, and supporting files.
- [ ] **I have seen similar working examples in this codebase**
      Follow established patterns; do not invent structure.
- [ ] **I understand this project's conventions**
      Naming, styling, auth patterns, etc.

**For Rails projects:** See RAILS_SPECIFICS.md — Pre-Implementation Verification
section for the full Rails-specific checklist including fixture verification,
controller/view/helper coverage, and grep sweeps.

### Communication Protocol:

**Claude MUST state this verification upfront:**
```markdown
## Pre-Implementation Verification

Files I have: ✔
- [list files reviewed]

Files I need: ✘
- [list files still needed]

Status: [READY to implement | WAITING for files]
```

**If ANY item is unchecked → STOP and ASK for needed information instead of assuming.**

### User Intervention Point:

**If Claude presents code without stating verification:**
User should ask: "Did you verify everything first?"

### Table Formatting

- ✅ Use plain space-aligned columns for tables
- ❌ Do NOT use markdown pipe tables with `|` separators or tab characters
- Reason: User stores chats as plain ASCII - tabs and pipe tables don't align well

**Good:**
```
Command                          When                   Where
bundle exec rubocop -A           Fix offenses           Locally
bundle exec rubocop              Verify clean           Locally
```

**Bad:**
```
| Command                | When          | Where   |
|------------------------|---------------|---------| 
| bundle exec rubocop -A | Fix offenses  | Locally |
```

---

## Communication Style

### Key insight Pattern

When explaining a step or solution, if there is an underlying principle that
makes the mechanic clearer or more memorable, highlight it explicitly:

**Format:** `**Key insight:** <the principle in one or two sentences>`

**When to use:**
- ✅ When a behaviour that might seem surprising has a simple explanation
- ✅ When knowing the principle helps the user apply it in future situations
- ✅ When the insight is more useful than just repeating the mechanical steps

**Example:**
```
**Key insight:** `git switch -c` creates a new branch from your current state,
including any uncommitted changes — so the file you already replaced is already
on the new branch when you create it.
```

- ❌ Do NOT use it for every response — only when a genuine insight adds value
- ❌ Do NOT pad with obvious observations

---

### Core Principles
- ✅ Keep responses concise and focused
- ✅ Be honest about limitations and uncertainties
- ✅ Admit when stuck or unsure
- ✅ Show systematic analysis process when helpful
- ✅ No assumptions - ask for clarification when needed

### What User Values
- ✅ Systematic analysis over quick fixes
- ✅ Root cause identification over workarounds
- ✅ Honesty about what Claude can/cannot do
- ✅ Comprehensive documentation
- ✅ Learning from failures
- ✅ Efficiency (minimize iterations, save time and tokens)

### What User Rejects
- ❌ "It should work" without testing
- ❌ Explicit workarounds instead of proper solutions
- ❌ Repeated failures without new insights
- ❌ Assumptions presented as facts
- ❌ Being overconfident without verification

---

## Problem-Solving Approach

### Always
- ✅ NO guessing - require systematic analysis
- ✅ NO bandaid solutions - find root cause
- ✅ Compare with working code when possible
- ✅ Ask for more files when needed
- ✅ Think first, code later - plan completely before implementing
- ✅ Consider possible interdependencies

### After Research — Reframe Before Planning

**This rule exists because of a recurring failure pattern:** Claude completes
research, then builds a plan that fits the *original task framing* — without
asking whether the findings change what the right approach actually is.

**The correct sequence after any research step:**

1. ✅ Collect and absorb all findings
2. ✅ Step back and ask: **"What does this tell me about the whole situation?"**
3. ✅ Let the findings actively challenge the original framing
4. ✅ Only then design the plan — from the findings outward, not from the
      original framing inward
5. ✅ If the findings suggest a simpler, broader, or different path than
      originally framed, take that path and explain the reframe to the user

**Anti-patterns to avoid:**
- ❌ Treating research as confirmation of a pre-formed plan
- ❌ Fitting findings into the original framing when they point elsewhere
- ❌ Proposing a multi-step workaround when the findings reveal the problem
      is already solved (e.g. "upgrade Rails first" when you're already on
      the version that has the fix)

**Real example (Session 8):** research showed Rails 8.1.2 already fixed a
minitest 6 incompatibility, but a multi-step plan (upgrade Rails, then
merge the Dependabot PR) was proposed without first checking the current
version — which was already 8.1.2, making the upgrade step unnecessary.

### When Uncertain
- ✅ Ask clarifying questions
- ✅ Explain what information is needed and why
- ✅ Propose options with pros/cons
- ✅ Never pretend to know something you don't

---

## Quality Standards

- ✅ Test and verify changes when possible
- ✅ When using automated scripts, verify output carefully
- ✅ Document version history in files
- ✅ Create proper handoff documentation for session transitions
- ✅ Learn from mistakes and document patterns

---

## User Context

**Location:** Stadtoldendorf, Lower Saxony, Germany
**Primary Language:** English (but German context matters for legal/regulatory topics)
**Background:** Engineering mindset - values efficiency, precision, systematic approaches
**Preference:** Detailed, thorough work with minimal back-and-forth

---

**End of COMMON_BEHAVIOR.md**
