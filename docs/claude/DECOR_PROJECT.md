# decor/docs/claude/DECOR_PROJECT.md
# version 2.37
# Session 42: Appliances → Peripherals merger fully complete.
#   Four live files cleaned up. DB bug fixed (computer_models device_type=1 rows).
#   Stale "cosmetic work remaining" note removed — all done.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 28, 2026 (Session 42)
**Current Status:** Sessions 1–42 committed and deployed.

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 41 — upload decor_tree.txt to refresh):
```
decor//
├── app/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── base_controller.rb
│   │   │   ├── bulk_uploads_controller.rb
│   │   │   ├── component_conditions_controller.rb
│   │   │   ├── component_types_controller.rb
│   │   │   ├── computer_models_controller.rb           ← Session 41 (v1.4)
│   │   │   ├── conditions_controller.rb
│   │   │   ├── connection_types_controller.rb
│   │   │   ├── data_transfers_controller.rb            ← Session 41 (v1.2)
│   │   │   ├── invites_controller.rb
│   │   │   ├── owners_controller.rb
│   │   │   ├── run_statuses_controller.rb
│   │   │   └── site_texts_controller.rb
│   │   ├── concerns/
│   │   │   ├── authentication.rb
│   │   │   └── pagination.rb
│   │   ├── application_controller.rb
│   │   ├── components_controller.rb
│   │   ├── computers_controller.rb                     ← Session 41 (v1.19)
│   │   ├── connection_groups_controller.rb
│   │   ├── data_transfers_controller.rb                ← Session 42 (v1.5)
│   │   ├── home_controller.rb
│   │   ├── owners_controller.rb                        ← Session 41 (v1.9)
│   │   ├── password_resets_controller.rb
│   │   ├── sessions_controller.rb
│   │   └── site_texts_controller.rb
│   ├── helpers/
│   │   └── computers_helper.rb                        ← Session 42 (v1.6)
│   ├── models/
│   │   ├── computer.rb                                 ← Session 41 (v2.0)
│   │   └── computer_model.rb                          ← Session 41 (v1.3)
│   ├── services/
│   │   ├── owner_export_service.rb                     ← Session 41 (v1.4)
│   │   └── owner_import_service.rb                     ← Session 41 (v1.5)
│   └── views/
│       ├── admin/
│       │   └── data_transfers/
│       │       └── show.html.erb                      ← Session 42 (v1.2)
│       ├── common/
│       │   └── _navigation.html.erb                   ← Session 41 (v2.0)
│       ├── data_transfers/
│       │   └── show.html.erb                          ← Session 42 (v1.8)
│       ├── layouts/
│       │   └── admin.html.erb                         ← Session 41 (v2.0)
│       └── owners/
│           ├── _owner.html.erb                        ← Session 41 (v3.5)
│           ├── computers.html.erb                     ← Session 41 (v1.3)
│           ├── connections.html.erb                   ← Session 41 (v1.1)
│           ├── peripherals.html.erb                   ← Session 41 (v1.2)
│           └── show.html.erb                          ← Session 41 (v2.2)
├── config/
│   └── routes.rb                                      ← Session 41 (v2.6)
└── test/
    ├── controllers/
    │   ├── admin/
    │   │   ├── computer_models_controller_test.rb      ← Session 41 (v1.3)
    │   │   └── data_transfers_controller_test.rb       ← Session 41 (v1.2)
    │   ├── computers_controller_test.rb                ← Session 41 (v1.8)
    │   └── owners_controller_test.rb                  ← Session 41 (v1.8)
    ├── fixtures/
    │   ├── computer_models.yml                         ← Session 41 (v1.3)
    │   └── computers.yml                              ← Session 41 (v1.9)
    ├── models/
    │   ├── computer_model_test.rb                     ← Session 41 (v1.3)
    │   └── computer_test.rb                           ← Session 41 (v1.7)
    └── services/
        ├── computer_model_export_service_test.rb      ← Session 41 (v1.2)
        ├── computer_model_import_service_test.rb      ← Session 41 (v1.2)
        ├── owner_export_service_test.rb               ← Session 41 (v1.4)
        └── owner_import_service_test.rb               ← Session 41 (v1.5)
```

---

**Key file versions** (updated each session):

    decor/docs/claude/DECOR_PROJECT.md                                                  v2.37 ← Session 42
    decor/docs/claude/SESSION_HANDOVER.md                                               v46.0 ← Session 42
    decor/docs/claude/RAILS_SPECIFICS.md                                                v2.5  ← Session 42
    decor/app/views/admin/data_transfers/show.html.erb                                  v1.2  ← Session 42
    decor/app/controllers/data_transfers_controller.rb                                  v1.5  ← Session 42
    decor/app/views/data_transfers/show.html.erb                                        v1.8  ← Session 42
    decor/app/helpers/computers_helper.rb                                               v1.6  ← Session 42
    decor/app/models/computer.rb                                                        v2.0  ← Session 41
    decor/app/models/computer_model.rb                                                  v1.3  ← Session 41
    decor/app/controllers/computers_controller.rb                                       v1.19 ← Session 41
    decor/app/controllers/owners_controller.rb                                          v1.9  ← Session 41
    decor/app/controllers/admin/computer_models_controller.rb                           v1.4  ← Session 41
    decor/app/controllers/admin/data_transfers_controller.rb                            v1.2  ← Session 41
    decor/app/services/owner_export_service.rb                                          v1.4  ← Session 41
    decor/app/services/owner_import_service.rb                                          v1.5  ← Session 41
    decor/app/views/common/_navigation.html.erb                                         v2.0  ← Session 41
    decor/app/views/layouts/admin.html.erb                                              v2.0  ← Session 41
    decor/app/views/owners/_owner.html.erb                                              v3.5  ← Session 41
    decor/app/views/owners/computers.html.erb                                           v1.3  ← Session 41
    decor/app/views/owners/connections.html.erb                                         v1.1  ← Session 41
    decor/app/views/owners/peripherals.html.erb                                         v1.2  ← Session 41
    decor/app/views/owners/show.html.erb                                                v2.2  ← Session 41
    decor/config/routes.rb                                                              v2.6  ← Session 41
    decor/test/fixtures/computers.yml                                                   v1.9  ← Session 41
    decor/test/fixtures/computer_models.yml                                             v1.3  ← Session 41
    decor/test/models/computer_test.rb                                                  v1.7  ← Session 41
    decor/test/models/computer_model_test.rb                                            v1.3  ← Session 41
    decor/test/controllers/computers_controller_test.rb                                 v1.8  ← Session 41
    decor/test/controllers/owners_controller_test.rb                                    v1.8  ← Session 41
    decor/test/controllers/admin/computer_models_controller_test.rb                     v1.3  ← Session 41
    decor/test/controllers/admin/data_transfers_controller_test.rb                      v1.2  ← Session 41
    decor/test/services/owner_export_service_test.rb                                    v1.4  ← Session 41
    decor/test/services/owner_import_service_test.rb                                    v1.5  ← Session 41
    decor/test/services/computer_model_export_service_test.rb                           v1.2  ← Session 41
    decor/test/services/computer_model_import_service_test.rb                           v1.2  ← Session 41
    decor/test/models/connection_group_test.rb                                          v1.2  ← Session 39
    decor/test/models/connection_member_test.rb                                         v1.1  ← Session 39
    decor/test/controllers/connection_groups_controller_test.rb                         v1.1  ← Session 38
    decor/db/migrate/20260323000000_add_owner_group_id_to_connection_groups.rb         v1.0  ← Session 38
    decor/db/migrate/20260323010000_add_owner_member_id_and_label_to_connection_members.rb v1.0 ← Session 38
    decor/app/models/connection_group.rb                                                v1.2  ← Session 38
    decor/app/models/connection_member.rb                                               v1.1  ← Session 38
    decor/app/controllers/connection_groups_controller.rb                               v1.1  ← Session 38
    decor/app/views/connection_groups/_form.html.erb                                    v1.2  ← Session 38
    decor/app/views/computers/show.html.erb                                             v2.1  ← Session 38
    decor/app/javascript/controllers/connection_members_controller.js                   v1.1  ← Session 38
    decor/test/fixtures/connection_groups.yml                                           v1.1  ← Session 38
    decor/test/fixtures/connection_members.yml                                          v1.1  ← Session 38
    decor/app/services/computer_model_export_service.rb                                 v1.0  ← Session 24
    decor/app/services/computer_model_import_service.rb                                 v1.0  ← Session 24

---

## Data Model Overview

### Owner
- has_many :computers, dependent: :destroy
- has_many :components, dependent: :destroy
- has_many :connection_groups, dependent: :destroy

### Computer
- belongs_to :owner
- belongs_to :computer_model
- belongs_to :computer_condition (optional)
- belongs_to :run_status (optional)
- has_many :components, dependent: :destroy
- has_many :connection_members, dependent: :destroy
- has_many :connection_groups, through: :connection_members
- device_type enum: { computer: 0, peripheral: 2 }, prefix: true
  NOTE: value 1 (appliance) was removed in Session 41; DB migration run manually by user.
  Hash form required to preserve non-contiguous integers (0 and 2).
  Do NOT renumber peripheral to 1 — that would corrupt existing DB records.
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)

### ComputerModel
- device_type enum: { computer: 0, peripheral: 2 }, prefix: true
  Same hash form as Computer; appliance: 1 removed in Session 41.
  NOTE: DB migration for computer_models (device_type 1 → 2) was missed in Session 41
  and applied manually in Session 42. Both computers and computer_models are now clean.
- has_many :computers, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true

### ConnectionType
- has_many :connection_groups, dependent: :restrict_with_error
- Admin-managed

### ConnectionGroup
- belongs_to :owner
- belongs_to :connection_type (optional)
- has_many :connection_members, dependent: :delete_all
- has_many :computers, through: :connection_members
- accepts_nested_attributes_for :connection_members, allow_destroy: true, reject_if: :all_blank
- owner_group_id: integer NOT NULL — owner's own numbering; auto-assigned (max+1) on create
  UNIQUE INDEX (owner_id, owner_group_id)
- Validations: owner_group_id presence/numericality/uniqueness; label max 100;
  minimum 2 active members; all members belong to owner;
  no duplicate computers in same group

### ConnectionMember
- belongs_to :connection_group
- belongs_to :computer
- owner_member_id: integer NOT NULL — per-group port numbering; auto-assigned on create
  UNIQUE INDEX (connection_group_id, owner_member_id)
- label: VARCHAR(100) nullable — optional port label (e.g. "DSSI Node 6")
- Existing index: UNIQUE (connection_group_id, computer_id) — preserved
- Validations: computer_id uniqueness scoped to group; owner_member_id > 0;
  label max 100
- after_destroy: destroys parent group if member count falls below 2

---

## Appliances → Peripherals Merger — FULLY COMPLETE (Sessions 41–42)

### What changed
- `appliance` (device_type=1) removed from enum on `Computer` and `ComputerModel`.
- Both enums now use hash form `{ computer: 0, peripheral: 2 }`.
- DB data migration (device_type=1 → 2) run on `computers` in Session 41 and on
  `computer_models` in Session 42 (the table was missed in Session 41).
- All fixtures, views, routes, controllers, helpers, services, and tests updated.
- Import backward compat: CSV record_type `"appliance"` → mapped to `:peripheral`
  (OwnerImportService v1.5) so CSVs exported before the merger remain importable.
- Admin and owner-facing data transfer views cleaned up (Session 42).
- `ComputersHelper` device type filter updated: Appliance → Peripheral (Session 42).

### Intentional remaining references
- `OwnerImportService` — legacy alias mapping (`"appliance"` → `:peripheral`). Keep.
- `record_type` column in owner-facing data_transfers view — lists `appliance` as
  a valid value with a note. Keep — old exports must remain importable.
- Test names and comments documenting migration history. Keep.

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

### Manual data migrations — check ALL tables (Session 42)
When running a manual data migration for an enum column, verify every table
that uses that column. In Session 42 the device_type migration ran on `computers`
only; `computer_models` was missed and sat at device_type=1 until fixed manually.
Grep `db/schema.rb` for the column name to find all affected tables.

### Never Guess — Read the File or Ask (Session 39)
Claude must never invent a path helper, method name, or behaviour without reading
the actual file. See decor-session-rules skill v1.3 for full detail.

### enum hash form required after non-contiguous gap (Session 41)
`enum :device_type, { computer: 0, peripheral: 2 }, prefix: true`
Do NOT renumber peripheral to 1.

### owner_group_id / owner_member_id — 0.present? is true (Session 38)
Guard must be `return if field.to_i > 0` not `return if field.present?`.

### Remove routes AFTER updating views (Session 41)
Removing routes before views causes cascade test failures — every page render
that calls the removed path helper explodes. Update views first, then remove routes.

### SQLite ALTER TABLE Limitations
Cannot add NOT NULL columns to existing tables — requires full table recreation.
Use `disable_ddl_transaction!` + raw SQL. See RAILS_SPECIFICS.md.

### safe_join for arrays of links — never .map.join.html_safe (Session 35)
### Connections show page — peer filtering uses reject not where.not (Session 34)
### reject_if: :all_blank required on connection_members nested attributes (Session 36)
### CSV::Table#to_a returns plain arrays, not CSV::Row objects (Session 37)
(Full details in RAILS_SPECIFICS.md and earlier Known Issues entries)

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

---

## Quick Reference Commands

```bash
bin/rails server
bin/rails test
bin/rails db:migrate
kamal app exec --reuse "bin/rails db:migrate"
kamal deploy
gh pr merge --merge --delete-branch
git pull
```

---

**End of DECOR_PROJECT.md**
