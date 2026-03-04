# COMMON_BEHAVIOR.md
# version 2.0
# decor/docs/claude/COMMON_BEHAVIOR.md
# Session 14: Major reliability update.
#   - Added "Reading Rule Documents" section — MANDATORY use of bash cat, never view tool.
#     view tool truncates files silently above ~16,000 characters. cat always returns complete content.
#   - Added "AI Forgetfulness — Why It Happens and How to Prevent It" section.
#   - Token estimate floor raised: 5+ large documents at session start → minimum 40% estimate.
#   - Added rule: always specify full paths when referring to or requesting files.

**Universal Rules for All Interactions with This User**

**Last Updated:** March 3, 2026 (v2.0: reliability rules; reading rules; AI forgetfulness documented)

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

`view` MAY be used for directory listings only — never for reading file content
that feeds into rule compliance or implementation decisions.

**Real example (Session 14, March 3, 2026):**
DECOR_PROJECT.md (636 lines) was read with the `view` tool. Lines 215–422 were
silently truncated. Claude completed a partial read and proceeded without noticing.
This is unacceptable — the rules set exists precisely to be read completely.

---

## AI Forgetfulness — Why It Happens and How to Prevent It

### Why AIs are not simply "better at remembering than humans"

This is a common and reasonable assumption — but it is only partially true.

**What AIs genuinely do better:**
- Perfect recall of everything currently in the context window
- No fatigue, mood, or distraction effects
- Consistent application of explicit rules when they are actively in focus

**What AIs do poorly — and why:**
- **Attention is not uniform across the context window.** Transformer-based models
  like Claude do not read a 600-line document the way a human reads sequentially.
  Content from the middle or end of a long document competes with content from
  hundreds of thousands of tokens of conversation history. Recent content and
  content near task instructions tends to dominate attention.
- **Rules read at session start decay in influence as the session grows.** By the
  time a test is being written at turn 20, the rule document read at turn 1 is
  competing with everything that followed. It is still in the context window —
  but its influence on generation is diluted.
- **Rules are not automatically cross-referenced at task time.** Claude does not
  automatically ask "what rule applies here?" before every action. Unless a rule
  is actively triggered by a task keyword or checklist step, it can be bypassed.
- **Truncated reads compound the problem.** If a rule was never fully read, it
  cannot be applied — regardless of attention.

**What this means in practice:**
The rules set is not self-enforcing. It requires:
1. Complete reads (bash cat, not view)
2. Explicit checklists that force rule recall at task time
3. The user's active intervention when rules are violated

**Claude's commitment:**
- Read all rule documents completely at session start (bash cat)
- Re-read the relevant sections of RAILS_SPECIFICS.md before writing tests
- Apply the Pre-Implementation Verification checklist without skipping steps
- When a rule failure occurs: acknowledge it specifically, correct it, and add it
  to the rule documents before end of session

---

## File Delivery — MANDATORY

### Always Present Files for Download

- ✅ EVERY new or updated file MUST be presented for download using the present_files tool
- ✅ This applies to ALL file types: .rb, .erb, .yml, .md, migrations, scripts, etc.
- ✅ Present the file IMMEDIATELY after creating/updating it — do not wait until end of response
- ✅ Multiple files in one response: present each one after it is created
- ❌ NEVER just show file contents in a code block without also presenting the download
- ❌ NEVER ask the user to copy/paste from a code block as a substitute for a download link

**Why this matters:**
The user needs to place files directly into the project. A download link is faster,
safer, and less error-prone than manual copy/paste from a code block.

### Always Specify Complete Paths

- ✅ ALWAYS specify the complete path (beginning with the project directory) when
  referring to, requesting, or delivering any file
- ✅ Format: `decor/path/to/filename.ext`
- ❌ NEVER refer to a file by its bare name only (e.g. `routes.rb` with no path)
- ❌ NEVER ask for a file without specifying its full path

Rails projects have many files with identical names in different directories
(`show.html.erb`, `_form.html.erb`, `index.html.erb`, etc.). Bare filenames
cause placement errors. Always give the full path.

**Real example (Session 14, March 3, 2026):**
After delivering 11 files, the placement instructions listed bare filenames only.
User had to ask for the full paths explicitly.

### Download File Naming

- ✅ Use the bare filename as the download name (e.g. `show.html.erb`, `routes.rb`)
- ✅ Prefix with the immediate parent directory **only** when two or more files
  in the same response share the same filename (e.g. two `show.html.erb` files)
- ✅ Use `#` as the separator between directory and filename
  (e.g. `data_transfers#show.html.erb`, `owners#show.html.erb`)
- ❌ Do NOT add a directory prefix when the filename is already unique in the response
- ❌ Do NOT use `_` as the separator (indistinguishable from underscores in the filename)

**Examples:**

Single `show.html.erb` in the response → download name: `show.html.erb`

Two `show.html.erb` files in the same response → download names:
  `data_transfers#show.html.erb` and `owners#show.html.erb`

`routes.rb` is always unique → download name: `routes.rb` (no prefix needed)

### Upload File Naming

The browser uses the bare filename as the upload key. If two files with the
same name (e.g. `show.html.erb` from different directories) are attached to
the same message, the second silently overwrites the first — Claude only ever
sees one of them.

- ✅ Upload same-named files in **separate answers** (one file per message)
- ✅ After each upload, Claude will confirm which file it received before asking for the next
- ❌ Do NOT rename files before uploading — too much effort and error-prone
- ❌ Do NOT attach two same-named files in one message

**Example:**
```
Answer 1: attach decor/app/views/owners/show.html.erb
Answer 2: attach decor/app/views/computers/show.html.erb
```

**Why this matters (Session 12, March 1, 2026):**
Both `owners/show.html.erb` and `computers/show.html.erb` were attached in the
same message. The second upload (computers) overwrote the first (owners) in the
context, so Claude only saw one of them and had to ask for the other separately.

---

## Response Formatting

### Start and End Separators
- ✅ Start EVERY response with 80 "=" (equals signs) characters
- ✅ End EVERY response with 80 "=" (equals signs) characters
- Format: `================================================================================`

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
will always be a significant undercount. In Session 10 (February 27, 2026),
Claude estimated ~50% when the UI showed 90% — a gap large enough to cause
poor planning decisions.

**Session-start floor rule:**
When 5 or more large rule/project documents are uploaded at session start,
the token estimate must NEVER be below 40% — the fixed base cost alone
justifies this floor before any conversation content is counted.

**Rules:**

✅ When a system warning IS visible:
- Use the EXACT numbers from `<system_warning>Token usage: X/Y; Z remaining</system_warning>`
- Format: `**Token Usage:** X / Y (Z% used, ~W remaining)`
- Never contradict or adjust a system warning with a manual calculation
- Once a system warning appears, anchor all further estimates to it

✅ When NO system warning is visible:
- Provide an estimate, but label it explicitly as rough and likely an undercount
- Apply a correction factor: multiply naive visible-content estimate by ~2
- Apply session-start floor: never below 40% when 5+ large documents are loaded
- Format: `**Token Usage (estimate):** ~X / 200,000 (~Y% used) — rough estimate only; likely an undercount; trust your UI`
- Err HIGH rather than falsely reassuring
- Remind the user that the UI is the only reliable source

❌ NEVER:
- Stay silent just because no system warning is visible
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
  Correct: **Token Usage (estimate):** ~80,000 / 200,000 (~40% used) — rough estimate
           only; likely an undercount; trust your UI over this number
  WRONG:   **Token Usage (estimate):** ~8,000 / 200,000 (~4% used) ← ignores base cost
```

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

**Real example (Session 8, February 26, 2026):**
Research revealed that Rails 8.1.2 already fixes the minitest 6 incompatibility.
The correct conclusion was: "check if we're already on 8.1.2 — if so, just merge
the Dependabot PR." Instead, a multi-step plan was proposed (upgrade Rails, then
merge PR) without first checking the current Rails version. The user was already
on 8.1.2, making the Rails upgrade step unnecessary. The reframe question —
"what does this tell me about the whole situation?" — would have surfaced this
immediately.

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
