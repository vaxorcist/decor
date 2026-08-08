# decor/docs/claude/DECOR_PROJECT.md
# version 2.82
# Session 93: Implemented Storage Locations Session F (export/import) —
#   the last remaining piece of the Storage Locations feature. New
#   "! --- storage_locations ---" CSV section (natural key: name, no
#   synthetic ID needed), exported first and imported first (dependency
#   ordering). New "storage_location" column appended as the LAST column
#   on the computers/peripherals, components, and software CSV sections.
#   Import auto-creates an unrecognized referenced storage_location name
#   (confirmed design decision) rather than treating it as a lookup
#   failure — never a row error, at worst a row_warning if the name itself
#   fails validation, with the parent record still saved unassigned in
#   that case.
#     decor/app/services/owner_export_service.rb           v1.11 -> v1.12
#     decor/app/services/owner_import_service.rb            v1.12 -> v1.13
#     decor/app/services/all_owners_export_service.rb        v1.1 -> v1.2
#     decor/app/views/data_transfers/show.html.erb            v1.9 -> v1.10
#     decor/test/services/owner_export_service_test.rb        v2.0 -> v2.1
#     decor/test/services/owner_import_service_test.rb        v1.9 -> v1.10
#   Two bugs found and fixed opportunistically during implementation:
#   (1) all_owners_export_service.rb had a pre-existing column-misalignment
#   bug dating to Session 70 (owner_part_number was added to CSV_HEADERS
#   but never to the row-building array — every column since has been
#   silently shifted by one); fixed in the same v1.2 change.
#   (2) A manual browser check found that importing a CSV containing only
#   new storage_location data produced "Nothing to import — all records
#   already exist." — build_success_message in BOTH
#   data_transfers_controller.rb and admin/data_transfers_controller.rb
#   omitted storage_location_count from their hardcoded count lists. Fixed
#   in both files.
#     decor/app/controllers/data_transfers_controller.rb          v1.6 -> v1.7
#     decor/app/controllers/admin/data_transfers_controller.rb    v1.4 -> v1.5
#   Six Session F files passed the full pre-commit checklist (Ulli
#   confirmed). The two controller fixes were delivered after the browser-
#   check finding; Ulli confirmed "all fine now" but the checklist was not
#   explicitly re-run against them, and the git workflow/kamal deploy for
#   all eight files together was not confirmed this session — see
#   SESSION_HANDOVER.md "Open Checklists" for the itemized remaining work.
#   **STORAGE LOCATIONS FEATURE (Sessions A-F, plus the ad-hoc Show Page)
#   IS NOW CODE-COMPLETE across every planned piece** — only Session F's
#   final deploy confirmation remains open.
#   Also this session: Ulli declared Sessions 77+78's combined checklist,
#   Session 89's Owner Part Number display fix, and the Session 68 GAP
#   NOTICE all "finished" — see SESSION_HANDOVER.md for the full record;
#   no DECOR_PROJECT.md content describes those items directly, so no
#   further edit needed here beyond this note.
# Session 92 (ad-hoc, closes out the StorageLocation Show Page work from
#   Sessions 90-91): fixed a test bug found when Ulli ran the full suite
#   — StorageLocationsControllerTest's "show displays the Components
#   section..." raised a TypeError because components.yml never sets
#   order_number on any fixture (unlike computers.yml). Fixed with a
#   one-line in-test update! addition, no fixture or app code touched
#   (storage_locations_controller_test.rb v1.1 -> v1.2). Ulli then
#   confirmed tests passing, confirmed the show route's plain shape,
#   confirmed remaining file placement via manual browser check, and
#   completed the full git workflow + kamal deploy for all five files.
#   **The StorageLocation Show Page feature (Sessions 90-91-92) is now
#   FULLY COMPLETE: committed, tested, lint/security-scanned, merged, and
#   DEPLOYED.** See SESSION_HANDOVER.md, Session 92 changelog entry, for
#   full detail.
# Session 91 (ad-hoc, direct continuation of Session 90's StorageLocation
#   show page — same feature, not a new A-F letter): Ulli reported the
#   Session 90 flat, alphabetical-by-name list wasn't sufficient to
#   identify an item. Reworked into four fixed-order category sections
#   (Computers, Peripherals, Components, Software), each shown only when
#   non-empty, with the full identifying-field set per category:
#   Computer/Peripheral Model or Component Type, DEC Part Number, DEC
#   Serial Number, and Owner Part Number for Computers/Peripherals/
#   Components; Software Name and Version for Software. Sort: category
#   first (fixed order), then case-insensitive alphabetical by
#   Model/Type/Software Name within each category. See "Storage Locations
#   Feature — Session Plan" → "Show Page" below for the full updated
#   write-up. Also added the show action's first automated test coverage
#   (storage_locations_controller_test.rb v1.1) — the action had none
#   before this session. Ulli confirmed the full pre-commit checklist
#   passed for the controller+view code (v1.3/v1.1) before the test file
#   existed; the test file's own pass/fail status and the git workflow for
#   all of it are still open at wrap-up. Full narrative:
#   SESSION_HANDOVER.md, Session 91 changelog entry.
# Session 90: Ad-hoc feature addition, unrelated to Storage Locations
#   Sessions D/E/F — added a `show` page to StorageLocation (routes.rb
#   v3.9, storage_locations_controller.rb v1.2, storage_locations/
#   show.html.erb v1.0 NEW, storage_locations/_storage_location.html.erb
#   v1.2), reversing Session B's original "no show page needed" decision
#   now that Session C's has_many associations make combining and listing
#   everything at a location straightforward. See "Storage Locations
#   Feature — Session Plan" below for the new write-up. Not yet placed/
#   tested/committed/deployed; no automated test written yet (pending
#   fixture files). Full narrative: SESSION_HANDOVER.md, Session 90
#   changelog entry. **Superseded in part by Session 91** — the show
#   action and its view were reworked; routes.rb and
#   _storage_location.html.erb from this session are unaffected.
# Session 88: Storage Locations Session E — COMPLETE. Resumed the paused
#   Session E draft; fixed a test-data collision bug found in the
#   pre-commit run (computers_controller_test.rb v1.12 → v1.13 — 2 tests
#   created a StorageLocation with the same name as an existing fixture for
#   the same owner). Full pre-commit checklist then passed. Wrote the
#   matching Components and SoftwareItems filter-sidebar support (8 files)
#   from the verified Computers pattern. All three device types tested,
#   lint/security-scanned, committed, merged, and DEPLOYED together —
#   confirmed by Ulli. See "Storage Locations Feature — Session Plan" below
#   for the updated Session E write-up. Full incident detail:
#   SESSION_HANDOVER.md, Session 88 changelog entry.
# Session 87: Resolved the computers_helper.rb anomaly flagged Session 86.
#   Confirmed via git-diff capture (session_d_uncommitted_diff_report.sh)
#   that the file's "v1.9" content is a real, sound, UNCOMMITTED local
#   draft of Storage Locations Session E's Computers/Peripherals filter
#   code — not phantom history. Storage Locations Session D marked
#   COMPLETE below. Session E marked IN PROGRESS, PAUSED (Ulli's explicit
#   choice) — see "Storage Locations Feature — Session Plan" below for the
#   updated Session D/E write-ups (later superseded by Session 88's
#   completion, see above). Full incident detail: SESSION_HANDOVER.md,
#   Session 86/87 changelog entries. No code written this session.
# Session 86: Storage Locations Session D (Privacy Audit) — views/partial
#   audit done and clean (see SESSION_HANDOVER.md for detail). A new
#   unresolved anomaly in computers_helper.rb (already v1.9, Session
#   E-shaped code, unrecorded elsewhere) blocked marking Session D fully
#   complete or trusting Session E's status — resolved Session 87, see
#   above.
# Session 84 (Reorg Session 2 of 4, plan agreed Session 83, continued from
#   Reorg 1 in this same session): Trimmed this file per the agreed reorg
#   plan. Removed the "## Directory Tree" section, removed the "Key file
#   versions" table, compressed six fully-DONE historical feature write-ups
#   to short pointers, removed the full "Session 78" and "Session 77"
#   narrative sections (now in SESSION_HISTORY_ARCHIVE.md). Data Model
#   Overview, the still-active Storage Locations plan, Known Issues,
#   Design Patterns, and Quick Reference Commands left untouched.
# Session 82: Storage Locations Session C — CLOSED OUT. Both gaps flagged
#   in Session 81 fixed. Full Session C migrated, tested,
#   lint/security-scanned, committed, merged, and DEPLOYED — confirmed by
#   Ulli. Session D (Privacy Audit) unblocked.
# Sessions 41–81: see SESSION_HISTORY_ARCHIVE.md for full per-session
#   narrative. Compressed pointers to the fully-DONE features from this
#   era are retained below under their own short headings.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** August 8, 2026 (Session 93: implemented Storage
  Locations Session F — export/import, the last remaining piece of the
  Storage Locations feature. New storage_locations CSV section and a
  storage_location column on computers/peripherals/components/software.
  Found and fixed two pre-existing bugs opportunistically: a Session-70
  column-misalignment bug in all_owners_export_service.rb, and a
  duplicated missing-count-field bug in both data_transfers_controller.rb
  and admin/data_transfers_controller.rb, found via Ulli's manual browser
  check. Ulli confirmed the pre-commit checklist passed for the six
  Session F files and confirmed "all fine now" after the two controller
  fixes. **The Storage Locations feature (Sessions A-F plus the ad-hoc
  Show Page) is now CODE-COMPLETE across every planned piece** — only
  Session F's final git workflow/deploy confirmation remains open. See
  "Storage Locations Feature — Session Plan" → "Session F" below and
  SESSION_HANDOVER.md's Session 93 changelog entry for full detail.)
**Current Status:** Sessions 1–76 all committed, pushed, merged, and
  deployed to main (per Ulli's confirmation at the start of Session 76).
  Sessions 77 and 78's own work is now CLOSED per Ulli's explicit Session
  93 declaration — see SESSION_HANDOVER.md "Open Checklists" (not
  independently re-verified; treat any resurfacing issue as a fresh bug
  report). **Storage Locations Sessions A through E are ALL fully
  committed, tested, lint/security-scanned, and DEPLOYED** — confirmed by
  Ulli (Session D: Sessions 86–87 privacy audit; Session E: Session 88 —
  Computers/Peripherals draft fixed and verified, Components and
  SoftwareItems equivalents written from the pattern, all three device
  types tested and DEPLOYED together). **Storage Locations Session F
  (export/import) is now CODE-COMPLETE (Session 93) — six files delivered
  and pre-commit-checklist-passed, plus two controller bug-fix files
  delivered after a manual-browser-check finding. Only the final git
  workflow and kamal deploy confirmation remain open** — see
  SESSION_HANDOVER.md "Open Checklists" for the itemized list. **This
  closes out every planned piece of the Storage Locations Feature —
  Session Plan (A through F).** The Documentation Reorganization plan
  (Sessions 84–85) is fully complete — see SESSION_HANDOVER.md
  "Documentation Reorganization — Status." **Session 89's Owner Part
  Number display fix is now CLOSED per Ulli's explicit Session 93
  declaration** (not independently re-verified). **The StorageLocation
  show page (Sessions 90-91-92) is now FULLY COMPLETE: committed, pushed,
  merged, tested, lint/security-scanned, and DEPLOYED** — confirmed by
  Ulli. This was an ad-hoc addition, independent of Session F.

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

### StorageLocation  ← Session 79 (model), Session 80 (owner-facing CRUD), Sessions 81–82 (FK associations, DONE ✓), Sessions 90-91-92 (show page, reworked, DEPLOYED)
- belongs_to :owner
- name VARCHAR(50) NOT NULL, uniqueness scoped to owner_id (not global —
  two owners may each have a location named "Garage")
- Private, owner-defined — NOT an admin-managed lookup table (unlike
  ComponentType/SoftwareName/ComponentSuggestion); same per-owner ownership
  pattern as ConnectionGroup.
- Owner-facing CRUD (Session 80): `StorageLocationsController` — index,
  **show (added Session 90, reworked Session 91)**, new, create, edit,
  update, destroy, delete_confirm. EVERY action requires login AND is
  scoped to Current.owner (no public or other-owner-visible view at all —
  stricter than SoftwareItem's public-index model). Reachable via "My
  Storage Locations" in the username dropdown
  (common/_navigation.html.erb v2.8).
- **show (Session 90, reworked Session 91):** lists everything currently
  stored at this location, now split into four fixed-order category
  sections — Computers, Peripherals, Components, Software — each shown
  only when it has at least one item, rather than Session 90's original
  single flat alphabetical list. Within each section, items are sorted
  case-insensitively by their own Model/Type/Software Name. Each row shows
  the full identifying-field set: Computer/Peripheral Model or Component
  Type, DEC Part Number (order_number), DEC Serial Number (serial_number),
  and Owner Part Number for Computers/Peripherals/Components; Software
  Name and Version for Software. Each item's name still links to its own
  show/edit page, same as Session 90. Reachable via a link on the
  location's name on the index page (`_storage_location.html.erb` v1.2,
  unchanged since Session 90). See "Storage Locations Feature — Session
  Plan" below for full detail. Session 91's rework was prompted directly
  by Ulli reporting that Session 90's flat list wasn't enough to identify
  an item.
- delete_confirm (Session 81, v1.1): real affected-record counts warning
  (@computers_count / @components_count / @software_items_count). Tested and
  confirmed working against a migrated database as of Session 82.
- has_many :computers/:components/:software_items, dependent: :nullify
  (Session 81, storage_location.rb v1.1).
- **Session C (Sessions 81–82) is DONE ✓** — migrated, tested,
  lint/security-scanned, committed, merged, and DEPLOYED — confirmed by
  Ulli. See SESSION_HISTORY_ARCHIVE.md "Session 81/82 Summary" for the
  complete file list.
- **Session E (Session 88) is DONE ✓** — filter-sidebar support for all
  three device types, tested and DEPLOYED — confirmed by Ulli.
- Privacy (confirmed in design consultation): visible only to the owning
  owner — excluded from every owners_controller read-only view of another
  owner's collection and from all other logged-in owners; included in the
  admin-wide export only (no dedicated admin UI). **Audited and CONFIRMED
  CLEAN (Sessions 86–87)** — see "Session D" below. The show page (Session
  90, reworked Session 91) preserves this: no admin exception,
  `Current.owner`-scoped like every other action.
- See "Storage Locations Feature — Session Plan" below for the full
  confirmed design, Session D/E's completion, the Session 90/91 show-page
  work, and the remaining Session F.

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
Overview above. Design/behaviour decisions: full detail in
SESSION_HISTORY_ARCHIVE.md, Sessions 62–67, and
`decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md` v1.0 (shelved design,
reference only). Fully committed/deployed as of Session 72.

---

## Category Help Pages Feature — Session 73 (RESOLVED Session 76 — checked and deployed)

5 new owner-facing help pages (one per device/software category), added as
pure `SiteText::KNOWN_TEXTS` data + routes — no migration. Keys: `help_computers`,
`help_peripherals`, `help_components`, `help_connections`, `help_software`.
Two pre-existing single-source-of-truth bugs found and fixed while
implementing — see RAILS_SPECIFICS.md "Single Source of Truth Refactors"
for the generalized rule this produced. Confirmed fully deployed at the
start of Session 76. Full file list and narrative: SESSION_HISTORY_ARCHIVE.md,
Session 73.

---

## Owner Part Number Feature — Sessions 69–72 (IMPLEMENTED, migrated, tested, deployed)

Adds `owner_part_number VARCHAR(20) NOT NULL` (defaulting to `"-"`) to both
`Computer` and `Component`, alongside a widened uniqueness scope and a
symmetric `serial_number` presence/defaulting fix. See "Computer" and
"Component" under Data Model Overview above for the live schema/validation
facts. Confirmed design answers and the full incident detail are in
SESSION_HISTORY_ARCHIVE.md, Sessions 69–72. Fully committed, tested,
migrated, and deployed to `main` as of Session 72.

**Session 89 addendum — display gap found and fixed:** `Component#owner_
part_number` (v1.6, Session 70) and its strong-params permit
(`components_controller.rb` v2.1, Session 70) were correctly implemented
from the start, but `decor/app/views/components/show.html.erb` was never
updated to display the field — every version between v1.7 (Session 22)
and v1.9 (Session C) added other fields without ever adding this one.
Same "single source of truth / touch N places, miss one" shape as the
`RAILS_SPECIFICS.md` "Single Source of Truth Refactors" rule and this same
page's own earlier Session 73/75 history. Data was saveable and correct in
the database the entire time; only the Components show page failed to
render it. Fixed in `components/show.html.erb` v1.11: Component Owner Part
Number is now displayed side by side with Trade Status in one row
(`grid-cols-2` when logged in, `grid-cols-1` alone when logged out, since
Trade Status remains members-only and must stay completely absent from
the DOM for logged-out visitors — same guard as before). No controller or
model change was needed. No new automated test — view-only display change,
no server-side logic altered. **Not yet placed/tested/committed/deployed
as of Session 90** — see SESSION_HANDOVER.md "Open Checklists."

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
                                                      DONE
                              A + C ─────────────> F (export/import)
                                                       CODE COMPLETE
                                                       (Session 93),
                                                       pending deploy
```

(Ad-hoc, outside this A-F letter scheme: a Show Page was added in Session
90 and reworked in Session 91 — see its own subsection at the end of this
plan.)

### Session A — Migration + Model + Fixtures + Model Tests — DONE ✓ (Session 79)

Implemented, tested, lint/security-scanned, committed, merged, deployed.
Schema: `storage_locations` — `owner_id` (FK, NOT NULL), `name`
VARCHAR(50) NOT NULL, unique index on `(owner_id, name)`. No CHECK
constraint. Deliberately NOT included: the has_many associations — those
FK columns don't exist until Session C.

### Session B — Owner-Facing CRUD (dedicated page) — DONE ✓ (Session 80)

Implemented, tested, lint/security-scanned, committed, merged, deployed.
Access model is stricter than SoftwareItem's precedent: EVERY action
requires login and is scoped to `Current.owner` — no public or
other-owner view. Originally shipped with no `:show` action (name-only
record; index list + edit was the whole surface) — **reversed in Session
90, see below.** The Session B `delete_confirm` shipped as a deliberately
honest, no-counts confirmation — upgraded in Session C. Nav entry: "My
Storage Locations" in the existing right-side username dropdown.

### Session C — FK on Computer, Component, SoftwareItem + Forms + Show Pages — DONE ✓ (Sessions 81–82)

Implemented, tested, lint/security-scanned, committed, merged, and
DEPLOYED — confirmed by Ulli. ("Show Pages" here refers to the Computer/
Component/SoftwareItem show pages gaining a Storage Location display
field — not the StorageLocation model's own show page, added later in
Session 90.) Delivered across two sessions: Session 81 did the bulk of the
work (20 files, migration, model associations, form dropdowns, show/index
display, real-counts `delete_confirm`); Session 82 closed two flagged
gaps (strong params on three controllers; Components index/row Storage
Location column). Full file-by-file detail: SESSION_HISTORY_ARCHIVE.md,
"Session 81 Summary" and "Session 82 Summary."

### Session D — Privacy Audit (dedicated, deliberately separate from Session C) — DONE ✓ (Sessions 86–87)

Depended on C (done). Confirmed `storage_location` does NOT appear in any
of the six owners/* read-only views or the shared `_profile.html.erb`
partial they all render. Confirmed no partial is shared between the
Session B/C owner-CRUD views and these read-only views. A separate
anomaly found mid-audit (`computers_helper.rb` already at v1.9 with
unrecorded code) was investigated and resolved Session 87 — an
uncommitted local draft of Session E's own work, unrelated to Session D's
own conclusion. Full detail: SESSION_HANDOVER.md, Session 86/87 changelog
entries.

### Session E — Filter Sidebar Support — DONE ✓ (Session 88)

Depended on C (done). Independent of D (also done). All three device
types now support the Storage Location filter, using an identical
two-guard pattern in every controller (`if logged_in?` + an
ownership-existence check against `Current.owner.storage_locations`,
closing the crafted cross-owner `storage_location_id` probe) and identical
UI placement (Storage Location select, positioned after Trade, in each
`_filters.html.erb`):

    decor/app/helpers/computers_helper.rb              v1.9
    decor/app/controllers/computers_controller.rb       v1.25
    decor/app/views/computers/_filters.html.erb          v1.8
    decor/test/controllers/computers_controller_test.rb v1.13

    decor/app/helpers/components_helper.rb                  v1.5
    decor/app/controllers/components_controller.rb           v2.3
    decor/app/views/components/_filters.html.erb              v1.5
    decor/test/controllers/components_controller_test.rb     v1.4

    decor/app/helpers/software_items_helper.rb                  v1.1
    decor/app/controllers/software_items_controller.rb          v1.5
    decor/app/views/software_items/_filters.html.erb              v1.1
    decor/test/controllers/software_items_controller_test.rb     v1.6

Test fixtures for all three device types reference the existing
storage_locations.yml fixtures (alice_attic, bob_garage) directly — no
StorageLocation.create! calls anywhere, avoiding a uniqueness collision
that was caught and fixed in computers_controller_test.rb v1.13 (2 tests
originally created a duplicate "Attic Shelf 3" for owner one, colliding
with the alice_attic fixture under the (owner_id, name) uniqueness
validation). Full pre-commit checklist passed on all three device types
together; git workflow and kamal deploy confirmed successful by Ulli.

### Session F — Export/Import (owner-level and admin-level) — CODE
    COMPLETE (Session 93), pending final deploy confirmation

Depended on A and C (both done). Implemented via Pre-Implementation
Verification: an export script pulled owner_export_service.rb,
owner_import_service.rb, all_owners_export_service.rb, data_transfers/
show.html.erb, owner_export_service_test.rb, owner_import_service_test.rb,
storage_location.rb, computer.rb, component.rb, software_item.rb,
owner.rb, and storage_locations.yml before any code was written.

**Design, as implemented:**
- New `! --- storage_locations ---` CSV section. Natural key: `name`
  (scoped to the owner the whole file already belongs to) — no synthetic
  ID needed, confirming the design already recorded in
  PROGRAMMING_GENERAL.md's "Export / Import — Always Include a Stable
  Unique Key." Exported first (`OwnerExportService#to_csv`); imported
  first (`OwnerImportService#dispatch_rows`) — dependency ordering, so a
  referencing computer/component/software row can find an already-created
  location, though this is a convenience rather than a strict requirement
  (see next point).
- `storage_location` column appended as the LAST column on
  `COMPUTER_SECTION_HEADERS`, `COMPONENT_SECTION_HEADERS`, and
  `SOFTWARE_SECTION_HEADERS` — append-only positioning chosen so any CSV
  exported before this feature (missing the column entirely) still
  imports correctly with no location assigned, rather than needing a
  version-detection branch.
- Import behaviour for a `storage_location` value on a computer/component/
  software row: blank → no location, no warning (the normal case).
  Matches an existing location for that owner → assigned. Does NOT match
  an existing location → **AUTO-CREATED** (the confirmed design decision
  from the original Session Plan design consultation, re-confirmed at
  Session 93's kickoff) rather than treated as a lookup failure like
  ComputerModel/ComponentType/SoftwareName — there's no admin catalog to
  ask, since storage locations are private, owner-defined data. A name
  that fails validation on auto-create (e.g. over 50 characters) produces
  a `row_warning`, not a `row_error` — the parent computer/component/
  software item is still saved, just without a location.
- `AllOwnersExportService` also gained the `storage_location` column,
  confirmed exempt from the Session D privacy audit (admin-wide export
  only) per the original design consultation recorded above under
  "StorageLocation."
- `CONNECTION_SECTION_HEADERS` deliberately NOT touched — a connection has
  no physical location independent of its member computers' own locations.

**Bugs found and fixed during implementation (both flagged to Ulli, not
silently absorbed):**
1. `all_owners_export_service.rb` — a pre-existing, unrelated bug dating to
   Session 70: `CSV_HEADERS` derived from `COMPUTER_SECTION_HEADERS`
   (which Session 70 widened to add `owner_part_number`) automatically
   grew to include that column, but the `to_csv` row-building array was
   never updated to match — every row exported by this admin-wide service
   since Session 70 has had `owner_part_number`'s column silently missing,
   shifting every subsequent value by one. Fixed in the same `v1.2` change
   that added `storage_location`.
2. `data_transfers_controller.rb` and `admin/data_transfers_controller.rb`
   — found via Ulli's manual browser check: importing a CSV containing
   only new `storage_location` data reported "Nothing to import — all
   records already exist," because both controllers' `build_success_message`
   hardcode a fixed list of count fields and neither included
   `storage_location_count`. This is the SECOND time this exact
   two-controller duplication has independently missed a new
   `OwnerImportService` counter (the first: Session 48,
   `connection_group_count`/`software_item_count`). Fixed in both files,
   each now carrying an explicit comment that any future counter added to
   `OwnerImportService`'s result hash needs a matching line in BOTH
   controllers in the SAME change.

    decor/app/services/owner_export_service.rb                  v1.12
    decor/app/services/owner_import_service.rb                   v1.13
    decor/app/services/all_owners_export_service.rb               v1.2
    decor/app/views/data_transfers/show.html.erb                    v1.10
    decor/test/services/owner_export_service_test.rb                v2.1
    decor/test/services/owner_import_service_test.rb                v1.10
    decor/app/controllers/data_transfers_controller.rb                v1.7
    decor/app/controllers/admin/data_transfers_controller.rb           v1.5

**Test coverage:** the six Session F files include full new coverage for
the `storage_locations` section and the `storage_location` column
(section-presence, header-match, row-content, blank-vs-assigned, ordering-
before-computers, auto-create-on-reference, blank-column-produces-no-
warning) — see the test files' own version-header comments for the
complete list. The two controller fixes do NOT yet have test coverage
(`build_success_message`'s `storage_location_count` handling) — offered at
end-of-task per PROGRAMMING_GENERAL.md's mandatory check, but Ulli moved to
wrap-up before the controller test files were provided. Flagged as a
pending item in SESSION_HANDOVER.md "Open Checklists."

**Status: CODE COMPLETE, pending final deploy confirmation.** Ulli
confirmed the full pre-commit checklist (`bin/rails test`, rubocop,
brakeman, bundle-audit) passed for the six Session F files, and a manual
browser check surfaced the flash-message bug described above. After the
two controller fixes were delivered, Ulli confirmed "all fine now" — but
did not explicitly re-run the checklist against those two files, and the
git workflow (branch → commit → push → PR → CI → merge) plus `kamal
deploy` for all eight files together were not confirmed in this session.
See SESSION_HANDOVER.md "Open Checklists" for the itemized remaining work.
**This closes out every planned piece (A through F) of the Storage
Locations Feature — Session Plan**, pending only that final deploy
confirmation.

### Show Page (ad-hoc addition, Session 90 — outside the original A-F plan; reworked Session 91; test bug fixed and DEPLOYED Session 92)

Ulli asked, independently of the A-F plan above, for a page at
`/storage_locations/:id` listing everything currently stored at that
location — Computers, Peripherals, Components, and Software Items.
Reverses Session B's original "No :show action — the index list is the
only display surface needed" decision (see "StorageLocation" under Data
Model Overview above) — that decision predates Session C's has_many
:computers/:components/:software_items associations, which make this
straightforward now.

**Session 90 (initial version):** combined everything into one flat list,
sorted alphabetically by display name, deliberately NOT grouped by type.
Each item's name linked out to its own show/edit page (`computer_path` /
`component_path` / `software_item_path`, matching the same conventions
already used on computers/show.html.erb's own Components and Software
sub-tables).

**Session 91 (rework):** Ulli reported the Session 90 flat list wasn't
sufficient to identify an item — a bare Computer Model or Component Type
name alone doesn't distinguish between two similar units. Reworked into
four fixed-order category sections, each rendered only when it has at
least one item:

    Category      Fields displayed
    ─────────────────────────────────────────────────────────────────
    Computers     Computer Model, DEC Part Number, DEC Serial Number,
                  Owner Part Number
    Peripherals   Peripheral Model, DEC Part Number, DEC Serial Number,
                  Owner Part Number
    Components    Component Type, DEC Part Number, DEC Serial Number,
                  Owner Part Number
    Software      Software Name, Version

Sections always appear in this fixed order (Computers, Peripherals,
Components, Software) regardless of item counts. Within each section,
items are sorted case-insensitively by their own Model/Type/Software
Name — computed and sorted in the controller, not the view. Each row's
name still links to the item's own show/edit page, unchanged from
Session 90. Access model unchanged from every other StorageLocation
action: private, scoped to `Current.owner`, no admin exception (unlike
`computers#show`, which is public).

**Implementation notes (Session 91):**
- `Computer`/`Peripheral` share one table and one `has_many :computers`
  association on `StorageLocation` (storage_location.rb v1.1, unchanged);
  the split into two sections uses the `device_type` enum's own generated
  `device_type_computer`/`device_type_peripheral` scopes
  (`enum :device_type, { computer: 0, peripheral: 2 }, prefix: true` — see
  "Computer" under Data Model Overview above), not a new column or
  association.
- Three new private controller methods — `build_computer_rows` (shared by
  both Computers and Peripherals, since the field set is identical),
  `build_component_rows`, `build_software_rows` — each return an array of
  plain hashes (model/type/software name, order_number, serial_number,
  owner_part_number where applicable, and the link path), sorted with
  `sort_by { |row| row[key].downcase }`.
- Verified field/association names against the actual uploaded
  `computer.rb`, `component.rb`, `software_item.rb`, and
  `storage_location.rb` before writing any code (Pre-Implementation
  Verification) — not guessed.

    decor/app/controllers/storage_locations_controller.rb   v1.2 → v1.3
    decor/app/views/storage_locations/show.html.erb           v1.0 → v1.1

Unaffected by this rework (still at their Session 90 versions, now
placed, tested, and DEPLOYED as part of Session 92's git workflow):

    decor/config/routes.rb                                       v3.9
    decor/app/views/storage_locations/_storage_location.html.erb  v1.2

**Test coverage (Session 91, fixed Session 92):** the `show` action had
zero automated tests before Session 91. `decor/test/controllers/
storage_locations_controller_test.rb` v1.0 → v1.1 added full coverage:
login/ownership guards (matching the pattern used by every other action
in this file), correct field display per category, correct
case-insensitive sort within each category (derived from the fixtures'
actual data, not hardcoded expected strings — per PROGRAMMING_GENERAL.md's
"Derive Test Assertions from Data, Not Constants"), a category section
being omitted entirely when empty, and cross-owner isolation. Deliberately
modifies NO fixture `.yml` file — every test assigns `storage_location`
via `update!` on existing fixtures, or creates a small number of new
`Computer` rows for the Peripherals tests (since no existing alice/bob
fixture has `device_type: peripheral`), entirely inside the test itself.
This relies on Rails' transactional fixture rollback rather than
permanent fixture changes, specifically to avoid silently affecting other
test files not reviewed this session (`computers_controller_test.rb`'s
own Storage Location filter tests from Session 88,
`components_controller_test.rb`, `software_items_controller_test.rb`).
**Session 92:** the first full-suite run of v1.1 hit a TypeError in the
Components-section test — `components.yml` never sets `order_number` on
any fixture (unlike `computers.yml`), so `component.order_number` was
`nil` and got passed into `assert_body_includes`. Fixed in v1.2 with a
one-line addition to the test's own `update!` call
(`order_number: "ORD-COMPONENT-1"`), keeping the "no shared fixture file
touched" design intact.

**Status: FULLY COMPLETE.** Ulli confirmed `bin/rails test`, rubocop,
brakeman, bundle-audit, and a manual browser check ALL PASSED for the
controller+view pair, then confirmed the fixed test file (v1.2) passing,
confirmed the `show` route's plain RESTful shape via `bin/rails routes`,
confirmed `routes.rb`/`_storage_location.html.erb` placement via a manual
browser check, and completed the full git workflow (branch → commit →
push → PR → CI → merge) plus `kamal deploy` for all five files together.
See SESSION_HANDOVER.md "Open Checklists" for the closed-out record.

---

## Component/Peripheral Dropdown Enhancements — Session 76 (components/_form.html.erb Row 1)

Four small, successive fixes to the Row 1 "Computer/Peripheral" select in
`decor/app/views/components/_form.html.erb`. All code-complete and
deployed as part of Session 76's confirmed-deployed batch. Full
narrative: SESSION_HISTORY_ARCHIVE.md, "Session 76 Summary."

## Tom Select Dropdown Sort Order Bug — Session 76 (tom_select_controller.js, project-wide)

`sortField: false` (present since Session 54) is not a valid Tom Select
option — it silently sorted every Tom Select dropdown by database id
instead of name. Fixed with an explicit
`sortField: { field: "text", direction: "asc" }`. Full mechanism:
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
the actual file. **Extended in practice Session 90 to rule-document delta
files** — when a delta referenced other delta content "already in Ulli's
possession" that had not actually been uploaded, Claude asked for the
missing files rather than reconstructing them from the summary given.
**Applied again Session 91:** before writing the show-page rework or its
tests, exported and read the actual controller/view/model files and, for
the tests, the actual fixture files and authentication_helper.rb, rather
than assuming field names, association names, or which fixtures already
carried a `storage_location_id`.

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

**Reinforced (Session 90):** a delivered link used `text-stone-900
hover:text-indigo-600` — indigo only on hover, not at rest — so it wasn't
visually recognizable as a link. This convention already existed
(this section); the miss was applying it incorrectly (hover-only) rather
than not knowing it. Worth double-checking that the *resting* class,
not just the hover class, is the indigo one whenever writing a clickable
value.

**Applied correctly (Session 91):** the reworked StorageLocation show
page's per-category tables reuse this exact convention
(`text-indigo-600 hover:text-indigo-900`) for every row's name link, and
reuse `text-stone-600` for the non-clickable identifying fields (DEC Part
Number, DEC Serial Number, Owner Part Number, Version) — no new colors
introduced.

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
Component Suggestions screens and the Components dropdown menu items — the
rename applies project-wide to every place these concepts are displayed to
a user, not just the primary Computer/Component forms.

**Exception noted Session 76:** the Component form's Row 1 selector for
which Computer/Peripheral a Component belongs to is deliberately labeled
"Computer/Peripheral", not "Computer Model" — since that field selects a
*device* (which may be either type), not a *model*.

**Applied correctly (Session 91):** the reworked StorageLocation show
page's column headers use "DEC Part Number" and "DEC Serial Number"
throughout (Computers/Peripherals/Components sections), matching this
established mapping — not the legacy "Order Number"/"Serial Number"
labels.

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
