# decor/docs/claude/SESSION_HANDOVER.md
# version 13.0

**Date:** March 1, 2026
**Branch:** main (all session 12 work committed and deployed — see note below)
**Status:** Destroy-redirect tests merged; cascade delete added; computers/show updated

---

## Session Summary

Session 12 closed out the pending work from Session 11 (destroy-redirect tests),
added Rails-layer cascade delete for computer → components, updated computers/show
to match owners/show width and component table layout, added a source=computer_show
redirect for deleting components from the show page, and updated the rule documents.

---

## Work Completed This Session

### 1. Destroy-redirect tests — standalone files created

    decor/test/controllers/computers_controller_test.rb    (v1.0)
    decor/test/controllers/components_controller_test.rb   (v1.0)

Session 11's `_additions.rb` stub files were sitting in the test directory as
literal files, not merged into anything. Root cause: no `computers_controller_test.rb`
or `components_controller_test.rb` existed — they needed to become standalone files.
Stale `_additions.rb` files should be deleted from `decor/test/controllers/`.

Fixture labels verified: `owners(:one)` = alice, `computers(:alice_pdp11)`,
`components(:pdp11_cpu)` — all confirmed correct from the additions files.

### 2. Computer cascade delete (Rails layer)

    decor/app/models/computer.rb              (v1.4)
    decor/test/models/computer_test.rb        (v1.3)

`has_many :components, dependent: :nullify` → `dependent: :destroy`.
Database-level ON DELETE CASCADE still to be added in a later migration.
Test: "destroying a computer destroys its components" (uses alice_pdp11 which
has pdp11_memory + pdp11_cpu in fixtures — two real components).

### 3. computers/show layout

    decor/app/views/computers/show.html.erb    (v1.5)

- `max-w-5xl` → `max-w-7xl` (matches owners/show)
- Components table columns: Type | Order No. | Serial No. | Description | Actions
- Order No. and Serial No. columns added
- Delete button added next to Edit (owner/admin only)
- Delete uses `source=computer_show` → stays on computer show page

### 4. source=computer_show redirect

    decor/app/controllers/components_controller.rb         (v1.5)
    decor/test/controllers/components_controller_test.rb   (v1.1)

New `source=computer_show` branch in `destroy`:
- `source=owner`         → `owner_path(owner)`
- `source=computer_show` → `computer_path(computer)`   ← new
- `source=computer`      → `edit_computer_path(computer)`
- (none)                 → `components_path`

### 5. Rule set updates

    decor/docs/claude/COMMON_BEHAVIOR.md    (v1.9)
    decor/docs/claude/DECOR_PROJECT.md      (v2.10)

COMMON_BEHAVIOR v1.9: Upload file naming rule — same-named files from different
directories must be uploaded in separate answers, not together in one message.

---

## Lessons Learned This Session

### Same-named file uploads overwrite silently
The browser uses the bare filename as the upload key. Uploading
`owners/show.html.erb` and `computers/show.html.erb` in the same message
causes the second to silently overwrite the first. Claude only sees one.
Fix: upload in separate answers. Rule added to COMMON_BEHAVIOR.md v1.9.

### _additions.rb stubs must not be committed as files
Session 11 committed the additions files to the test directory as literal
`.rb` files. They were not valid test files (no class declaration, no
require). The correct handling: either merge immediately into existing test
files, or create proper standalone test files. Stubs in the test directory
confuse both Rails test discovery and future developers.

---

## Pending — Start of Next Session

### 1. Delete stale stub files
```bash
rm decor/test/controllers/computers_controller_test_additions.rb
rm decor/test/controllers/components_controller_test_additions.rb
```
These were committed in Session 11 and replaced by proper files this session.

### 2. Database-level ON DELETE CASCADE for computer → components
Rails-layer `dependent: :destroy` added this session. The matching DB
migration (adding `ON DELETE CASCADE` to the FK constraint) is still needed.
SQLite requires full table recreation for this — use the
`disable_ddl_transaction!` + raw SQL pattern from RAILS_SPECIFICS.md.

### 3. BulkUploadService stale model references (low priority, carried over)

    decor/app/services/bulk_upload_service.rb
    — Fix: Condition → ComputerCondition (column: name)
    — Fix: computer.condition → computer.computer_condition
    — Fix: component.history field does not exist on Component model
    — Fix: component.condition → component.component_condition

---

## Git State

**Branch:** main
**All session 12 work should be committed and deployed before starting session 13.**
**First action:** delete the two stale `_additions.rb` stub files (see Pending #1).

---

## Other Candidates

1. Dependabot PRs — dedicated session
2. Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
3. System tests: decor/test/system/ still empty
4. Account deletion + data export (GDPR)
5. Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
6. BulkUploadService stale model references (see Pending above)

---

## Documents Updated This Session

    decor/docs/claude/COMMON_BEHAVIOR.md        v1.9
    decor/docs/claude/DECOR_PROJECT.md          v2.10
    decor/docs/claude/SESSION_HANDOVER.md       v13.0

Note: RAILS_SPECIFICS.md and PROGRAMMING_GENERAL.md unchanged this session.

---

**End of SESSION_HANDOVER.md**
