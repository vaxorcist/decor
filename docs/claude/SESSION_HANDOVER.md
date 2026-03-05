# decor/docs/claude/SESSION_HANDOVER.md
# version 17.0

**Date:** March 5, 2026
**Branch:** feature/add-independent-devices-and-peripherals
**Status:** Session 16 work in progress — not yet committed.

---

## !! RELIABILITY NOTICE — READ FIRST !!

The `decor-session-rules` skill (v1.1) is installed. Its description contains
the first mandatory action — read it from the available_skills context before
doing anything else.

**MANDATORY at every session start:**

STEP 0 — Tool sanity check (from skill description — visible without reading file):
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

## Session Summary

Session 16 delivered:
1. Session start failure analysis — bash_tool not used due to false inference
   from environment context string. Skill v1.1 and COMMON_BEHAVIOR.md v2.2
   updated with two new rules: tool sanity check (step 0) and skill/rule doc
   change protocol (propose before modifying; present as download after).
2. device_type in export/import — "appliance" added as third record_type value
3. Owners index — filter narrowed (grid-cols-5); APPLIANCES column added

---

## Work Completed This Session

### 1. Rule Document and Skill Updates

    decor/docs/claude/COMMON_BEHAVIOR.md         (v2.2)
    decor-session-rules skill                    (v1.1)

Two new rules:
- "Tool Availability — Never Infer, Always Test": run `echo "bash_tool OK"`
  as step 0; never infer tool availability from environment context strings.
- "Skill and Rule Document Changes": propose before modifying; present result
  as downloadable file; never modify silently.

Failure mode documented: Session 16 turn 1 — bash_tool available but unused.
The system context said "web or mobile chat interface"; Claude inferred
(incorrectly) that bash_tool was unavailable and tried web_fetch with
file:// URLs instead.

### 2. device_type in Export / Import

    decor/app/services/owner_export_service.rb            (v1.1)
    decor/app/services/owner_import_service.rb            (v1.1)
    decor/app/views/data_transfers/show.html.erb          (v1.5)
    decor/test/services/owner_export_service_test.rb      (v1.1)
    decor/test/services/owner_import_service_test.rb      (v1.1)

"appliance" added as a third valid record_type value (alongside "computer"
and "component"). No new CSV column — record_type encodes device_type:
"computer" → device_type: 0, "appliance" → device_type: 1.

Export: device_type_appliance? predicate selects emitted string.
Import: "appliance" routes into computer_rows bucket with :appliance tag;
process_computer_row receives device_type as third argument.

show.html.erb v1.5 fixed by user (v1.4 had incorrect explanatory texts).

### 3. Owners Index — Filter Width and Appliances Column

    decor/app/views/owners/index.html.erb        (v3.3)
    decor/app/views/owners/_owner.html.erb       (v3.3)

index.html.erb: grid changed from grid-cols-4 to grid-cols-5 (filter column
reduced from 25% to 20% = 80% of previous); table expanded from col-span-3
to col-span-4, reclaiming freed space. APPLIANCES column header added.

_owner.html.erb: Appliances count cell added after Computers count cell,
using device_type_appliance scope. Computers cell now uses
device_type_computer.count (was .count — would have included appliances).
Both columns link to computers_path(owner_id:) — once computers index gains
device_type filtering, the appliances link can target appliances only.

---

## Lessons Learned This Session

### Never infer tool availability from environment context descriptions
The system context string "web or mobile chat interface" describes the
user-facing product, not which tools Claude has. One echo command tests
reality; reasoning from context strings does not.

### Skills must carry critical instructions in their description
The skill body requires a deliberate read — it provides no guarantee of
being seen. The description is injected automatically into every session
context and is the only part guaranteed to be visible. Step 0 (echo sanity
check) and the separator/token rules are now in the description.

### Propose before modifying skills or rule documents
Both are the user's property. No modification without prior approval.
Always present the result as a downloadable file — the web UI does not
show skill file contents.

### w-4/5 clips content within a grid slot; it does not resize the slot
To actually redistribute space between grid children, change the grid
column definition (grid-cols-N) and the span (col-span-N), not the width
of the element inside.

---

## Pending — Start of Next Session

### 1. Commit session 16 work
Suggested message:
```
Add appliance support to export/import and owners index; update session rules
```

Files to commit:
    decor/app/services/owner_export_service.rb
    decor/app/services/owner_import_service.rb
    decor/app/views/data_transfers/show.html.erb
    decor/app/views/owners/index.html.erb
    decor/app/views/owners/_owner.html.erb
    decor/test/services/owner_export_service_test.rb
    decor/test/services/owner_import_service_test.rb
    decor/docs/claude/COMMON_BEHAVIOR.md
    decor/docs/claude/DECOR_PROJECT.md
    decor/docs/claude/SESSION_HANDOVER.md

### 2. Computers index — device_type filtering (NEXT TASK)
The user asked: "What to do to make the computers index gain device_type
filtering?" This was deferred due to token limits.

Files needed to answer and implement:
    decor/app/views/computers/index.html.erb
    decor/app/views/computers/_filters.html.erb
    decor/app/views/computers/_computer.html.erb
    decor/app/controllers/computers_controller.rb
    decor/test/controllers/computers_controller_test.rb

Once reviewed, the answer will cover:
  - Adding a device_type filter param to the controller scope
  - Adding a device_type selector to _filters.html.erb
  - Optionally distinguishing computer vs appliance rows in _computer.html.erb
  - Updating the appliances link in owners/_owner.html.erb to filter by
    device_type once the filter exists

### 3. Naming — "appliance" placeholder still unresolved (carried over)
Final UI label for device_type: 1 not confirmed by English partner.
Once confirmed:
  - Update enum key in decor/app/models/computer_model.rb and
    decor/app/models/computer.rb
  - Update fixture labels
  - Update all UI-facing strings

### 4. UI changes — computers index and form (device_type) — carried over
  - Form: device_type selector on computer new/edit

### 5. UI changes — components form and show (component_category) — carried over
  component_category (integral/peripheral) not yet exposed in the UI.

### 6. BulkUploadService stale model references — low priority, carried over
    decor/app/services/bulk_upload_service.rb
    - Condition → ComputerCondition
    - computer.condition → computer.computer_condition
    - component.history field does not exist on Component model
    - component.condition → component.component_condition

---

## Git State

**Branch:** feature/add-independent-devices-and-peripherals
**Session 16 work is NOT yet committed.**
**First action next session:** commit session 16 files, then continue.

---

## Other Candidates

1. Dependabot PRs — dedicated session
2. Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
3. System tests: decor/test/system/ still empty
4. Account deletion + data export (GDPR)
5. Spam / Postmark DNS fix (awaiting Rob's dashboard findings)

---

## Documents Updated This Session

    decor/docs/claude/DECOR_PROJECT.md        v2.12
    decor/docs/claude/SESSION_HANDOVER.md     v17.0

---

**End of SESSION_HANDOVER.md**
