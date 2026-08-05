# decor/docs/claude/DECOR_PROJECT.md
# version 2.76
# Session 87: Resolved the computers_helper.rb anomaly flagged Session 86.
#   Confirmed via git-diff capture (session_d_uncommitted_diff_report.sh)
#   that the file's "v1.9" content is a real, sound, UNCOMMITTED local
#   draft of Storage Locations Session E's Computers/Peripherals filter
#   code — not phantom history. Storage Locations Session D marked
#   COMPLETE below. Session E marked IN PROGRESS, PAUSED (Ulli's explicit
#   choice) — see "Storage Locations Feature — Session Plan" below for the
#   updated Session D/E write-ups. Full incident detail: SESSION_HANDOVER.md,
#   Session 86/87 changelog entries. No code written this session.
# Session 86: Storage Locations Session D (Privacy Audit) — views/partial
#   audit done and clean (see SESSION_HANDOVER.md for detail). A new
#   unresolved anomaly in computers_helper.rb (already v1.9, Session
#   E-shaped code, unrecorded elsewhere) blocked marking Session D fully
#   complete or trusting Session E's status — resolved Session 87, see above.
# Session 84 (Reorg Session 2 of 4, plan agreed Session 83, continued from
#   Reorg 1 in this same session): Trimmed this file per the agreed reorg
#   plan (see SESSION_HANDOVER.md "Documentation Reorganization — Status").
#   Changes made:
#   1. REMOVED the "## Directory Tree" section entirely (the ASCII tree
#      block + its regeneration command). It was last regenerated from a
#      real `tree` command at Session 41 and had been manually annotated
#      ever since — an increasingly unreliable secondary copy of
#      information that already lives correctly in each file's own
#      version-header comment and in `git log`. FLAGGED CROSS-DOC ISSUE
#      (not fixed this pass — out of scope for a DECOR_PROJECT.md-only
#      reorg session, and rule-document edits require prior proposal/
#      approval per COMMON_BEHAVIOR.md): RAILS_SPECIFICS.md's "Directory
#      Tree Maintenance — MANDATORY" section still instructs future
#      sessions to keep this now-deleted section current. That rule needs
#      a corresponding edit (either removed or repointed) — proposed as an
#      explicit action item for Reorg 3 (RAILS_SPECIFICS.md pass), not
#      applied silently here.
#   2. REMOVED the "Key file versions" table (the long flat list of every
#      file+version+session going back to Session 24). This dataset is
#      fully redundant with (a) `git log`, and (b) each file's own
#      mandatory version-header comment (PROGRAMMING_GENERAL.md "File
#      Version Control") — the table was pure duplication that only grew,
#      never shrank, every session.
#   3. COMPRESSED the following fully-DONE, historical feature write-ups
#      down to short pointers (their live, still-relevant facts — schema/
#      validation/scope details — already exist in "Data Model Overview"
#      below, which was NOT touched): "Software Feature — Session Plan",
#      "Component Suggestions Feature — Session Plan" (all 4 phases),
#      "Category Help Pages Feature — Session 73", "Owner Part Number
#      Feature — Sessions 69–72", "Component/Peripheral Dropdown
#      Enhancements — Session 76", "Tom Select Dropdown Sort Order Bug —
#      Session 76".
#   4. REMOVED the full "Session 78" and "Session 77" narrative sections.
#      Both describe code-complete-but-not-yet-placed work; their content
#      now lives in SESSION_HISTORY_ARCHIVE.md ("Session 77 Summary",
#      "Session 78 Summary", moved there in Reorg 1 this same session) and
#      the still-open combined checklist already lives in
#      SESSION_HANDOVER.md "Open Checklists". Nothing actionable was lost:
#      the NOT-YET-DONE checklist is the one live artifact from these two
#      sections, and it was already present in SESSION_HANDOVER.md before
#      this edit.
#   5. KEPT UNCHANGED (live reference content, not narrative duplication):
#      Data Model Overview, the full "Storage Locations Feature — Session
#      Plan" (Sessions D–F are still NOT STARTED, so this remains an
#      active working document, not historical record), "Appliances →
#      Peripherals Merger", "Connections Feature — Status", "Known Issues
#      & Solutions", "Design Patterns", "Quick Reference Commands".
#   Verified before finalizing: every schema/validation/scope fact
#   referenced by the removed/compressed sections above still exists
#   somewhere in the kept content (mainly Data Model Overview) — nothing
#   load-bearing for future Pre-Implementation Verification was deleted,
#   only session-narrative duplication and the two large historical
#   tables (tree, key-file-versions).
#   Full original narrative for every compressed section remains
#   recoverable via git history of this file and via
#   SESSION_HISTORY_ARCHIVE.md for the sessions that already moved there.
# Session 82: Storage Locations Session C — CLOSED OUT. Both gaps flagged
#   in Session 81 fixed: :storage_location_id added to strong params on
#   computers_controller.rb / components_controller.rb /
#   software_items_controller.rb; Storage Location own-view-only column
#   added to components/index.html.erb + components/_component.html.erb
#   (bringing Components to parity with Computers/Software Items). Full
#   Session C is now migrated, tested, lint/security-scanned, committed,
#   merged, and DEPLOYED — confirmed by Ulli. Session D (Privacy Audit)
#   can now start. See SESSION_HANDOVER.md / SESSION_HISTORY_ARCHIVE.md
#   "Session 82 Summary" for full detail.
# Sessions 41–81: see SESSION_HISTORY_ARCHIVE.md for full per-session
#   narrative. Compressed pointers to the fully-DONE features from this
#   era are retained below under their own short headings.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** August 4, 2026 (Session 87: resolved the Session 86
  computers_helper.rb anomaly — confirmed uncommitted local Session E
  draft, not phantom history. Storage Locations Session D marked
  COMPLETE, Session E marked IN PROGRESS/PAUSED; v2.76)
**Current Status:** Sessions 1–76 all committed, pushed, merged, and
  deployed to main (per Ulli's confirmation at the start of Session 76).
  Sessions 77 and 78's own work (11 files — see SESSION_HANDOVER.md "Open
  Checklists" / SESSION_HISTORY_ARCHIVE.md "Session 77/78 Summary")
  status is UNCHANGED — no session since has touched or confirmed 77/78's
  placement; both remain a separate open item. **Storage Locations
  Sessions A, B, and C are ALL fully committed, tested, lint/
  security-scanned, and DEPLOYED** — confirmed by Ulli. **Storage
  Locations Session D (Privacy Audit) is now COMPLETE** (Sessions 86–87 —
  see "Storage Locations Feature — Session Plan" below). **Storage
  Locations Session E (filter-sidebar support) is IN PROGRESS, PAUSED:** an
  uncommitted, unreviewed local draft covers Computers/Peripherals only
  (found Session 86, content confirmed sound Session 87); paused at Ulli's
  explicit request. **Storage Locations Session F (export/import) remains
  genuinely NOT STARTED.** The Documentation Reorganization plan (Sessions
  84–85) is fully complete — see SESSION_HANDOVER.md "Documentation
  Reorganization — Status."

**Note on Directory Tree / Key file versions removal (Session 84):** this
file no longer carries a live directory tree or a running file-version
table. For "what does the current tree look like" or "what version is
file X at right now," use:
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6
git log --oneline -- decor/path/to/file.rb
head -3 decor/path/to/file.rb   # version-header comment, mandatory per PROGRAMMING_GENERAL.md
```

---

## Data Model Overview

### Owner
- has_many :computers, dependent: :destroy
- has_many :components, dependent: :destroy
- has_many :software_items, dependent: :destroy        ← Session 43
- has_many :connection_groups, dependent: :destroy
- has_many :storage_locations, dependent: :destroy     ← Session 79

### Computer
- belongs_to :owner
- belongs_to :computer_model
- belongs_to :computer_condition (optional)
- belongs_to :run_status (optional)
- belongs_to :storage_location (optional)              ← Session 81
- has_many :components, dependent: :destroy
- has_many :software_items, dependent: :destroy        ← Session 43
- has_many :connection_members, dependent: :destroy
- has_many :connection_groups, through: :connection_members
- device_type enum: { computer: 0, peripheral: 2 }, prefix: true
  NOTE: value 1 (appliance) was removed in Session 41; DB migration run manually by user.
  Hash form required to preserve non-contiguous integers (0 and 2).
  Do NOT renumber peripheral to 1 — that would corrupt existing DB records.
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)
- owner_part_number VARCHAR(20) NOT NULL  ← Session 70 (Owner Part Number feature)
  Defaults to "-" via before_validation when left blank (data-entry convenience).
  serial_number is ALSO now defaulted to "-" via before_validation when blank
  (was previously a hard validation error). Combined uniqueness scope widened
  from (owner_id, computer_model_id) to (owner_id, computer_model_id,
  owner_part_number, serial_number) — existing model dimension KEPT.

### ComputerModel
- device_type enum: { computer: 0, peripheral: 2 }, prefix: true
  Same hash form as Computer; appliance: 1 removed in Session 41.
- has_many :computers, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true

### SoftwareName  ← Session 43
- has_many :software_items, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true, length max 40
- validates :description, length max 100, optional
- Admin-managed (analogous to ComponentType)

### SoftwareCondition  ← Session 43
- has_many :software_items, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true, length max 40
- validates :description, length max 100, optional
- Admin-managed. Initial values: Complete, Incomplete, Subset.
- NOTE: column is "name" (not "condition" like legacy component_conditions table)

### SoftwareItem  ← Session 43
- belongs_to :owner
- belongs_to :computer, optional: true
- belongs_to :software_name
- belongs_to :software_condition, optional: true
- belongs_to :storage_location (optional)              ← Session 81
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)
- version VARCHAR(20), optional
- description VARCHAR(100), optional
- history VARCHAR(200), optional

### Component
- belongs_to :storage_location (optional)              ← Session 81
- order_number_verified: boolean NOT NULL, default false  ← Session 63 (Phase 1)
  true  = order_number was accepted from component_suggestions typeahead
  false = order_number typed freely (not validated against suggestions table)
- owner_part_number VARCHAR(20) NOT NULL  ← Session 70 (Owner Part Number feature)
  Defaults to "-" via before_validation when left blank, same as Computer.
  serial_number's previous allow_blank: true is REMOVED — serial_number is now
  presence: true and ALSO defaults to "-" via before_validation. This resolves
  the Computer/Component asymmetry flagged in the Session 69 design
  consultation. Combined uniqueness scope widened from (owner_id,
  component_type_id) to (owner_id, component_type_id, owner_part_number,
  serial_number) — existing type dimension KEPT.
  BEHAVIOUR CHANGE (Option B, confirmed Session 70): Session 28 intentionally
  allowed multiple unserialized spares of the same component_type per owner.
  A second such spare with no distinguishing value is now REJECTED at save
  time — no auto-assign mechanism exists going forward. Pre-existing
  collisions were one-time-backfilled with "SPARE-#{id}" placeholders by
  migration 20260716000100; this is a historical data fix, not an ongoing
  behaviour.

### ComponentSuggestion  ← Session 63 (Phase 1), updated Session 67 (Phase 4)
- Admin-managed lookup table for component order number autocomplete
- validates :order_number, presence: true, uniqueness: true, length max 20
- validates :description, length max 510, optional (widened from 100 — Session 67)
- validates :category, length max 40, optional (free text; informational display only)
- order_number VARCHAR(20) NOT NULL, UNIQUE index
- description  VARCHAR(510) nullable (widened Session 67 for concatenated main+variant text)
- category     VARCHAR(40)  nullable (NOT stored on component when suggestion accepted)
- manual       VARCHAR(1) nullable — enum :manual, { added: "a", modified: "m" }, prefix: true
  (Session 67). null = untouched bulk-import row (the normal case). "a" = added via
  the admin form, permanent. "m" = modified via the admin form after originating
  from bulk import. Read the RAW value with manual_before_type_cast, not
  read_attribute (see RAILS_SPECIFICS.md).
- scope :matching, ->(q) { where("order_number LIKE ?", "#{q}%").order(:order_number) }
- scope :order_number_contains, ->(q) { where("order_number LIKE ?", "%#{q}%") } (Session 67,
  substring match for the admin index filter — different from :matching's prefix match)

### SiteText  ← model dates to Session 18; documented here (genuine doc gap
  ### closed) Session 73
- Generic key/content lookup table backing every admin-managed, owner-facing
  static text page (README, News, Barter Trade, Privacy, and — as of Session
  73 — the 5 Category Help pages).
- key     VARCHAR(40) NOT NULL, UNIQUE index
- content TEXT NOT NULL (approved TEXT use — free-form Markdown body,
  per PROGRAMMING_GENERAL.md's TEXT exception for long free-form content)
- `KNOWN_TEXTS` (class constant) is the single source of truth: an array of
  `{ key:, title: }` hashes. Drives every admin selector (Upload/Download/
  Delete dropdowns) via `SiteText.options_for_select_list`, and page titles
  via `SiteText.title_for_key`. **Adding a new text page requires only a new
  KNOWN_TEXTS entry + a matching public route — no migration, no admin
  controller/view changes.**
- **Load-bearing naming convention (Session 73):** every public route's
  `as:` name MUST be identical to its `key` string. `Admin::
  SiteTextsController#url_for_key` (v1.3) relies on this to compute
  `send("#{key}_path")` generically for ANY key, with no per-key case
  branch. Breaking this convention for a future key silently falls back to
  `root_path` instead of the new page.
- `.for(key)` — convenience finder (Session 18)
- `SiteTextsController#show` (owner-facing, no `require_login` — public) and
  `Admin::SiteTextsController` (upload/download/delete, admin-only) are both
  fully generic over `KNOWN_TEXTS`.

### ConnectionGroup
- belongs_to :owner
- belongs_to :connection_type (optional)
- has_many :connection_members, dependent: :delete_all
- has_many :computers, through: :connection_members
- accepts_nested_attributes_for :connection_members, allow_destroy: true, reject_if: :all_blank
- owner_group_id: integer NOT NULL — auto-assigned (max+1) on create

### ConnectionMember
- belongs_to :connection_group
- belongs_to :computer
- owner_member_id: integer NOT NULL — per-group port numbering; auto-assigned on create
- label: VARCHAR(100) nullable

### StorageLocation  ← Session 79 (model), Session 80 (owner-facing CRUD), Sessions 81–82 (FK associations, DONE ✓)
- belongs_to :owner
- name VARCHAR(50) NOT NULL, uniqueness scoped to owner_id (not global —
  two owners may each have a location named "Garage")
- Private, owner-defined — NOT an admin-managed lookup table (unlike
  ComponentType/SoftwareName/ComponentSuggestion); same per-owner ownership
  pattern as ConnectionGroup.
- Owner-facing CRUD (Session 80): `StorageLocationsController` — index, new,
  create, edit, update, destroy, delete_confirm. EVERY action requires login
  AND is scoped to Current.owner (no public or other-owner-visible view at
  all — stricter than SoftwareItem's public-index model). No :show action —
  the index list is the only display surface needed for a name-only record.
  Reachable via "My Storage Locations" in the username dropdown
  (common/_navigation.html.erb v2.8).
- delete_confirm (Session 81, v1.1): real affected-record counts warning
  (@computers_count / @components_count / @software_items_count). Tested and
  confirmed working against a migrated database as of Session 82.
- has_many :computers/:components/:software_items, dependent: :nullify
  (Session 81, storage_location.rb v1.1).
- **Session C (Sessions 81–82) is DONE ✓** — migrated, tested,
  lint/security-scanned, committed, merged, and DEPLOYED — confirmed by
  Ulli. See SESSION_HISTORY_ARCHIVE.md "Session 81/82 Summary" for the
  complete file list.
- Privacy (confirmed in design consultation): visible only to the owning
  owner — excluded from every owners_controller read-only view of another
  owner's collection and from all other logged-in owners; included in the
  admin-wide export only (no dedicated admin UI). **Audited and CONFIRMED
  CLEAN (Sessions 86–87)** — see "Session D" below.
- See "Storage Locations Feature — Session Plan" below for the full
  confirmed design, Session D/E's current status, and the remaining
  Session F.

---

## Software Feature — Session Plan  ← Session 43

Option C (full separation, not a Component variant). ALL SIX SESSIONS
(A–F: migrations/models, Admin CRUD, owner index/show, owner create/edit/
destroy, computer/peripheral show integration, export/import) DONE ✓ as of
Session 48. Fully committed/deployed. Full detail: SESSION_HISTORY_ARCHIVE.md,
Sessions 43–48.

---

## Component Suggestions Feature — Session Plan  ← Session 62

Admin-managed `component_suggestions` lookup table driving a typeahead on
`components.order_number`. ALL FOUR PHASES DONE ✓:

    Phase 1  Migrations, model, admin CRUD, CSV import/export        DONE ✓ (Session 63)
    Phase 2  JSON endpoint + Stimulus typeahead                      DONE ✓ (Session 64)
    Phase 3  Order number bulk maintenance (admin tools)             DONE ✓ (Session 65)
    Phase 4  Manual flag, "Download Manual Changes", import rewrite  DONE ✓ (Session 67)
             (delete_all + insert_all — fixed a production timeout),
             paginated/filterable admin index

Schema/validation/scope facts: see "ComponentSuggestion" under Data Model
Overview above. Design/behaviour decisions (typeahead accept/reject rules,
the shelved order_number/variant schema-split design, the two route-helper-
naming mistakes caught before shipping): full detail in
SESSION_HISTORY_ARCHIVE.md, Sessions 62–67, and
`decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md` v1.0 (shelved design,
reference only). Fully committed/deployed as of Session 72.

---

## Category Help Pages Feature — Session 73 (RESOLVED Session 76 — checked and deployed)

5 new owner-facing help pages (one per device/software category), added as
pure `SiteText::KNOWN_TEXTS` data + routes — no migration. Keys: `help_computers`,
`help_peripherals`, `help_components`, `help_connections`, `help_software`.
Two pre-existing single-source-of-truth bugs found and fixed while
implementing (owner-facing `SiteTextsController` had its own stale
`title_for_key`; admin `url_for_key` was a hardcoded case statement) — see
RAILS_SPECIFICS.md "Single Source of Truth Refactors" for the generalized
rule this produced. Confirmed fully deployed at the start of Session 76.
Full file list and narrative: SESSION_HISTORY_ARCHIVE.md, Session 73.

---

## Owner Part Number Feature — Sessions 69–72 (IMPLEMENTED, migrated, tested, deployed)

Adds `owner_part_number VARCHAR(20) NOT NULL` (defaulting to `"-"`) to both
`Computer` and `Component`, alongside a widened uniqueness scope and a
symmetric `serial_number` presence/defaulting fix. See "Computer" and
"Component" under Data Model Overview above for the live schema/validation
facts. Confirmed design answers (uniqueness scope kept at the model/type
dimension; symmetric defaulting; one-time `"SPARE-#{id}"` backfill for
colliding pre-existing spares, no ongoing auto-assign; CSV export/import
updated on `owner_export_service.rb`/`owner_import_service.rb` only) and
the full incident detail (an unrelated `bundle-audit` CI failure across
four gems, fixed and confirmed before merge) are in
SESSION_HISTORY_ARCHIVE.md, Sessions 69–72. Fully committed, tested,
migrated, and deployed to `main` as of Session 72.

---

## Storage Locations Feature — Session Plan (Session 79, updated Session 80)

Owners can define their own private list of physical storage locations
(e.g. "Attic Shelf 3") and assign one to each of their own Computers,
Peripherals (device_type on Computer — not a separate table), Components,
and SoftwareItems. Design consultation (Session 79) confirmed:

    Q                                          Confirmed answer
    ─────────────────────────────────────────────────────────────────────
    FK or free text?                           FK (storage_location_id)
    name column length / description field?    VARCHAR(50), no description
    flat or hierarchical?                       Flat
    dedicated CRUD or inline creation?          Dedicated owner-facing CRUD
    delete behaviour?                           Nullify (with a warning
                                                 showing affected counts,
                                                 before destroy)
    admin visibility?                           Private from other owners
                                                 AND visitors; included in
                                                 the admin-wide export;
                                                 NO dedicated admin browsing
                                                 UI
    filter-sidebar support in scope?            Yes
    import: unknown referenced name?            Auto-create
    nav placement (new right-group problem)?    Right of the logo, in the
                                                 existing right-side flex
                                                 group (Admin / username /
                                                 Sign out) — safe since
                                                 Session 78 already took the
                                                 logo out of the grid/flex
                                                 flow entirely

### Dependency summary

```
A (model) ──> B (CRUD) ──> C (FK + forms) ──┬──> D (privacy audit)
   DONE         DONE          DONE           │       DONE
                                              └──> E (filters)
                                                  IN PROGRESS, PAUSED
                              A + C ─────────────> F (export/import)
                                                       NOT STARTED
```

### Session A — Migration + Model + Fixtures + Model Tests — DONE ✓ (Session 79)

Implemented, tested, lint/security-scanned, committed, merged, deployed.
Schema: `storage_locations` — `owner_id` (FK, NOT NULL), `name`
VARCHAR(50) NOT NULL, unique index on `(owner_id, name)`. No CHECK
constraint (matches the actual `component_suggestions` precedent). Deliberately
NOT included: the `has_many :computers/:components/:software_items`
associations — those FK columns don't exist until Session C.

### Session B — Owner-Facing CRUD (dedicated page) — DONE ✓ (Session 80)

Implemented, tested, lint/security-scanned, committed, merged, deployed.
Access model is stricter than SoftwareItem's precedent: EVERY action
(including index) requires login and is scoped to `Current.owner` — no
public or other-owner view. No `:show` action (name-only record; index
list + edit is the whole surface). The Session B `delete_confirm` shipped
as a deliberately honest, no-counts confirmation (the counting associations
don't exist yet) — flagged in both the controller and view as interim,
Session C's job to upgrade. Nav entry: "My Storage Locations" in the
existing right-side username dropdown.

### Session C — FK on Computer, Component, SoftwareItem + Forms + Show Pages — DONE ✓ (Sessions 81–82)

Implemented, tested, lint/security-scanned, committed, merged, and
DEPLOYED — confirmed by Ulli. Delivered across two sessions: Session 81
did the bulk of the work (20 files, including the migration, model
associations, form dropdowns, show/index display, and the real-counts
`delete_confirm` upgrade) but left two gaps flagged rather than guessed
through — `components/_component.html.erb`'s own-view-only Storage
Location column, and `:storage_location_id` missing from strong params on
all three referencing controllers. Session 82 closed both: strong params
added to `computers_controller.rb` (v1.24) / `components_controller.rb`
(v2.2) / `software_items_controller.rb` (v1.4); Components brought to
parity with Computers/SoftwareItems (`components/index.html.erb` v1.9,
`components/_component.html.erb` v1.8). Full file-by-file detail:
SESSION_HISTORY_ARCHIVE.md, "Session 81 Summary" and "Session 82
Summary." One unrelated `kamal deploy` DNS-timeout incident (resolved by
plain retry, no code change).

### Session D — Privacy Audit (dedicated, deliberately separate from Session C) — DONE ✓ (Sessions 86–87)

Depended on C (done). A dedicated pass, not assumed to fall out correctly
from Session C — this project has hit exactly this class of bug
repeatedly (Session 73/75 form-vs-show drift). Explicit read-through +
confirmation that `storage_location` does NOT appear in any of, plus the
shared partial they all render:

    decor/app/views/owners/computers.html.erb       — clean
    decor/app/views/owners/peripherals.html.erb     — clean
    decor/app/views/owners/components.html.erb      — clean
    decor/app/views/owners/software.html.erb        — clean
    decor/app/views/owners/show.html.erb            — clean
    decor/app/views/owners/_owner.html.erb          — clean
    decor/app/views/owners/_profile.html.erb        — clean (rendered by all
      six above; added to scope Session 86)

Confirmed (Session 86): none of the six share a partial with the Session
B/C owner-CRUD views — each builds its own inline table, so the
partial-sharing leak vector this section originally flagged does not
exist in this codebase. Also confirmed (informational): the three device
partials that DO carry a Storage Location cell
(`computers/_computer.html.erb` / `components/_component.html.erb` /
`software_items/_software_item.html.erb`) already correctly guard that
cell with a per-row `Current.owner == X.owner` check, falling back to a
plain em-dash for every other row. A separate anomaly found mid-audit
(`computers_helper.rb` already at v1.9 with unrecorded code) was
investigated and resolved Session 87 — it turned out to be an
uncommitted local draft of Session E's own work (see "Session E" below),
unrelated to Session D's own conclusion. Full detail: SESSION_HANDOVER.md,
Session 86/87 changelog entries.

### Session E — Filter Sidebar Support — IN PROGRESS, PAUSED (found Session 86, confirmed Session 87)

Depends on C (done). Independent of D. An uncommitted, unreviewed local
draft already exists for the Computers/Peripherals half only — reviewed
Session 87 and assessed sound (Storage Location filter gated
`if logged_in?`, plus an ownership-existence guard against a crafted
cross-owner `storage_location_id`; 3 new tests covering the happy path,
the ownership guard, and the logged-out skip). **Paused here at Ulli's
explicit request — not run, tested, lint/security-scanned, or committed.**

    decor/app/views/computers/_filters.html.erb   v1.8  (uncommitted) — DONE (draft)
    decor/app/controllers/computers_controller.rb v1.25 (uncommitted) — DONE (draft)
    decor/app/helpers/computers_helper.rb         v1.9  (uncommitted) — DONE (draft)
    + test/controllers/computers_controller_test.rb v1.12 (uncommitted, 3 new tests)

    decor/app/views/components/_filters.html.erb / components_controller.rb /
      components_helper.rb                        — NOT STARTED
    decor/app/views/software_items/_filters.html.erb / software_items_controller.rb /
      software_items_helper.rb                     — NOT STARTED
    + filter test coverage in each controller test file — Computers done
      (draft, uncommitted); Components/SoftwareItems NOT STARTED

Remaining steps when this resumes: run the full pre-commit checklist on
the existing Computers/Peripherals draft; write the matching Components
and SoftwareItems equivalents following the same pattern; then the git
workflow for all three device types together.

### Session F — Export/Import (owner-level and admin-level) — NOT STARTED

Depends on A and C (both done). Last, since it's the most cross-cutting
piece. Unaffected by the Session D/E situation above.

    decor/app/services/owner_export_service.rb
      new storage_locations CSV section, referenced BY NAME (no synthetic key
      needed — (owner_id, name) uniqueness is already the natural key);
      storage_location column added to Computer/Component/SoftwareItem sections
    decor/app/services/owner_import_service.rb
      storage_locations section imported BEFORE the Computer/Component/SoftwareItem
      sections (dependency ordering, same shape as computer_models needing to exist
      before computers); a referenced name not yet present for that owner is
      AUTO-CREATED (confirmed design decision) rather than skipped/rejected
    decor/app/services/all_owners_export_service.rb
      storage_location included (confirmed: not private from admins — this file
      is exempt from the Session D privacy audit)
    decor/app/views/data_transfers/show.html.erb   (mention new CSV section)
    + test updates: owner_export_service_test.rb, owner_import_service_test.rb

---

## Component/Peripheral Dropdown Enhancements — Session 76 (components/_form.html.erb Row 1)

Four small, successive fixes to the Row 1 "Computer/Peripheral" select in
`decor/app/views/components/_form.html.erb`: label rename ("Computer
Model" → "Computer/Peripheral"), Owner Part Number added to the option
label, column widened 50% (`grid-cols-[3fr_2fr_2fr]`), wording consistency.
All code-complete and deployed as part of Session 76's confirmed-deployed
batch. Full narrative: SESSION_HISTORY_ARCHIVE.md, "Session 76 Summary."

## Tom Select Dropdown Sort Order Bug — Session 76 (tom_select_controller.js, project-wide)

`sortField: false` (present since Session 54) is not a valid Tom Select
option — it silently sorted every Tom Select dropdown (Computer Model,
Condition, Run Status) by database id instead of name. Fixed with an
explicit `sortField: { field: "text", direction: "asc" }`. Full mechanism:
RAILS_SPECIFICS.md, "Tom Select sortField — Must Be an Explicit Sort Spec."

---

## Appliances → Peripherals Merger — FULLY COMPLETE (Sessions 41–42)

- `appliance` (device_type=1) removed from enum on `Computer` and `ComputerModel`.
- Both enums now use hash form `{ computer: 0, peripheral: 2 }`.
- Import backward compat: CSV record_type `"appliance"` → mapped to `:peripheral`. Keep.

---

## Connections Feature — Status

    Part 1a: Migrations + models + fixtures             DONE (Session 31)
    Part 1b: Model tests                                DONE (Session 32)
    Part 2:  Admin ConnectionTypes CRUD                 DONE (Session 33)
    Part 3:  Owner device show pages — read-only        DONE (Sessions 34–35)
    Part 4:  Owner ConnectionGroup CRUD                 DONE (Session 36)
    Part 5:  owner_group_id / owner_member_id / labels  DONE (Sessions 38–39) ✓

---

## Known Issues & Solutions

### New admin:: resources require an admin.html.erb nav update — same session (Session 63/64)
Adding `resources :foo` inside `namespace :admin do ... end` in routes.rb does
NOT surface the feature anywhere. The admin menu bar lives in
`decor/app/views/layouts/admin.html.erb` (a separate layout from
`common/_navigation.html.erb`), with each top-level item being its own
dropdown `<div data-controller="dropdown">` block.
**Rule: any session that adds a new `admin::` resources block MUST also add
the corresponding `link_to` inside the matching dropdown in admin.html.erb
(or a new dropdown, if the resource doesn't fit an existing menu group),
before the session is considered complete — not as a follow-up.**

### CI Security (Ruby) failures — always confirm which tool, and confirm clean before pushing (Session 64, reinforced Session 72)
`CI/Security (Ruby)` is `bundle-audit` (gem-version CVE scan), NOT Brakeman
(static code scan) — two separate CI jobs. A clean local `bin/brakeman`
proves nothing about this check. Pull the actual CI log
(`gh run view <run-id> --log-failed`) before assuming which tool failed.
`bundle-audit` reports vulnerabilities in batches — fixing what one CI run
shows can unmask more on the next run. Always confirm with a full local
`bundle exec bundle-audit check --update` returning "No vulnerabilities
found" before re-pushing.

### CI/Tests (System) failures — get the actual log; don't assume relation to the current session's other changes (Session 76)
A `CI/Tests (System)` failure can be a pre-existing latent bug in a test
file, unrelated to whatever else is being worked on in the same PR/branch.
Pull the actual log (`gh run view <run-id> --log-failed`) and trace the
failing line before assuming it's caused by the session's other work.

### System tests — browser-layer login (Session 59)
`login_as` uses the Rack adapter. System tests require `sign_in` (browser form).
Never call `login_as` from a system test file.

### Manual data migrations — check ALL tables (Session 42)
Grep `db/schema.rb` for the column name to find all affected tables.

### Never Guess — Read the File or Ask (Session 39)
Claude must never invent a path helper, method name, or behaviour without reading
the actual file.

### enum hash form required after non-contiguous gap (Session 41)
`enum :device_type, { computer: 0, peripheral: 2 }, prefix: true`

### owner_group_id / owner_member_id — 0.present? is true (Session 38)
Guard must be `return if field.to_i > 0` not `return if field.present?`.

### data-turbo="false" disables Turbo on all descendants (Session 53)
A Turbo-method link inside a data-turbo="false" ancestor silently falls back to GET.

### CSS grid grid-cols-N causes nav link overflow (Session 53)
Use grid-cols-[auto_1fr_auto] for left/logo/right navbars.

---

## Design Patterns

### Color Scheme
- Clickable values:    `text-indigo-600 hover:text-indigo-900`
- Destructive actions: `text-red-600 hover:text-red-900`
- Non-clickable data:  `text-stone-600`
- Table headers:       `text-stone-500 uppercase`
- Barter offered:      `text-green-700`
- Barter wanted:       `text-amber-600`
- Barter no_barter:    `text-stone-400` (em-dash)

### Button Labels
- Primary: descriptive ("Update Computer", "Save Component")
- Secondary: "Done" — never "Cancel"

### UI Naming (Connections feature)
- "Connection Group" → "Connection" in all user-facing text
- "Connection Member" → "Port" in all user-facing text

### UI Terminology — Established Renames (Session 69)

**These are the current, correct UI labels. Any new form/view/table added in
future sessions MUST use the right-hand column — not the legacy left-hand
term — for these fields.** Attribute/column/route names are UNCHANGED;
only displayed text changed.

    Legacy UI label      Current UI label        Underlying attribute (unchanged)
    ────────────────────────────────────────────────────────────────────────────
    "Model"               "Computer Model"         computer_model_id / computer.computer_model
    "Order Number"        "DEC Part Number"         order_number
    "Serial Number"       "DEC Serial Number"       serial_number

**Compact/abbreviated headers** (narrow table columns) follow the same
mapping, abbreviated consistently:
    "Order" / "Order No."   → "DEC P/N" (owners/computers.html.erb, owners/peripherals.html.erb)
                               or "DEC Part No." (components/index.html.erb, owners/components.html.erb)
    "Serial" / "Serial No." → "DEC S/N" or "DEC Serial No." (same file-pairing as above)

**Scope confirmed with the user (Session 69):** this includes the Admin >
Component Suggestions screens and the Components dropdown menu items
("Re-validate DEC Part Numbers", "Download Unvalidated DEC Part Numbers") —
i.e. the rename applies project-wide to every place these concepts are
displayed to a user, not just the primary Computer/Component forms.

**Exception noted Session 76:** the Component form's Row 1 selector for
which Computer/Peripheral a Component belongs to is deliberately labeled
"Computer/Peripheral", not "Computer Model" — since that field selects a
*device* (which may be either type), not a *model* the way the Computer
form's own Model field does. Not a rename of the established "Model" →
"Computer Model" mapping above; a different field entirely.

**Explicitly NOT renamed (still say "order_number"/"serial_number"):**
- CSV column headers and literal field-name references in
  `decor/app/views/data_transfers/show.html.erb` and
  `decor/app/views/admin/bulk_uploads/new.html.erb` — these are the actual
  import/export contract column names; renaming them would break CSV
  compatibility with existing exported files.
- The downloaded CSV filename in
  `decor/app/controllers/admin/component_order_numbers_controller.rb`
  (`unvalidated_order_numbers_<date>.csv`) — not yet addressed; flagged for
  the user to decide whether it's in scope.
- Ruby/JS identifiers, method names, route helpers, DB columns, and internal
  code comments describing *past* decisions (left as historical record).

---

## Quick Reference Commands

```bash
bin/rails server
bin/rails test
bin/rails test:system
bin/rails db:migrate
kamal app exec --reuse "bin/rails db:migrate"
kamal deploy
gh pr merge --merge --delete-branch
git pull
```

---

**End of DECOR_PROJECT.md**
