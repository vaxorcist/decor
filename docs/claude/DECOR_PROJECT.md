# decor/docs/claude/DECOR_PROJECT.md
# version 2.41
# Session 46: Software feature Session D complete.
#   9 files: software_items_controller updated (v1.1), routes.rb updated (v2.9),
#   three new views (new/edit/_form for software_items, v1.0),
#   owners/software.html.erb updated (v1.1),
#   software_items/show.html.erb updated (v1.1),
#   owners/show.html.erb updated (v2.4),
#   software_items_controller_test updated (v1.1).
#   Directory tree needs refresh (upload decor_tree.txt at next session start).

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** April 3, 2026 (Session 46)
**Current Status:** Sessions 1–45 committed and deployed. Session 46 ready to commit.

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 41 — Sessions 43–46 add new files; upload decor_tree.txt to refresh):
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
│   │   │   ├── site_texts_controller.rb
│   │   │   ├── software_conditions_controller.rb       ← Session 44 (v1.0) NEW
│   │   │   └── software_names_controller.rb            ← Session 44 (v1.0) NEW
│   │   ├── concerns/
│   │   │   ├── authentication.rb
│   │   │   └── pagination.rb
│   │   ├── application_controller.rb
│   │   ├── components_controller.rb
│   │   ├── computers_controller.rb                     ← Session 41 (v1.19)
│   │   ├── connection_groups_controller.rb
│   │   ├── data_transfers_controller.rb                ← Session 42 (v1.5)
│   │   ├── home_controller.rb
│   │   ├── owners_controller.rb                        ← Session 45 (v2.0)
│   │   ├── password_resets_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── site_texts_controller.rb
│   │   └── software_items_controller.rb                ← Session 46 (v1.1)
│   ├── helpers/
│   │   └── computers_helper.rb                        ← Session 42 (v1.6)
│   ├── models/
│   │   ├── computer.rb                                 ← Session 43 (v2.1)
│   │   ├── computer_model.rb                          ← Session 41 (v1.3)
│   │   ├── owner.rb                                   ← Session 43 (v1.5)
│   │   ├── software_condition.rb                      ← Session 43 (v1.0) NEW
│   │   ├── software_item.rb                           ← Session 43 (v1.0) NEW
│   │   └── software_name.rb                           ← Session 43 (v1.0) NEW
│   ├── services/
│   │   ├── owner_export_service.rb                     ← Session 41 (v1.4)
│   │   └── owner_import_service.rb                     ← Session 41 (v1.5)
│   └── views/
│       ├── admin/
│       │   ├── data_transfers/
│       │   │   └── show.html.erb                      ← Session 42 (v1.2)
│       │   ├── software_conditions/
│       │   │   ├── _form.html.erb                     ← Session 44 (v1.0) NEW
│       │   │   ├── edit.html.erb                      ← Session 44 (v1.0) NEW
│       │   │   ├── index.html.erb                     ← Session 44 (v1.0) NEW
│       │   │   └── new.html.erb                       ← Session 44 (v1.0) NEW
│       │   └── software_names/
│       │       ├── _form.html.erb                     ← Session 44 (v1.0) NEW
│       │       ├── edit.html.erb                      ← Session 44 (v1.0) NEW
│       │       ├── index.html.erb                     ← Session 44 (v1.0) NEW
│       │       └── new.html.erb                       ← Session 44 (v1.0) NEW
│       ├── common/
│       │   └── _navigation.html.erb                   ← Session 41 (v2.0)
│       ├── data_transfers/
│       │   └── show.html.erb                          ← Session 42 (v1.8)
│       ├── layouts/
│       │   └── admin.html.erb                         ← Session 44 (v2.1)
│       ├── owners/
│       │   ├── _owner.html.erb                        ← Session 41 (v3.5)
│       │   ├── computers.html.erb                     ← Session 45 (v1.4)
│       │   ├── components.html.erb                    ← Session 45 (v1.4)
│       │   ├── connections.html.erb                   ← Session 45 (v1.2)
│       │   ├── peripherals.html.erb                   ← Session 45 (v1.3)
│       │   ├── show.html.erb                          ← Session 46 (v2.4)
│       │   └── software.html.erb                      ← Session 46 (v1.1)
│       └── software_items/
│           ├── _form.html.erb                         ← Session 46 (v1.0) NEW
│           ├── edit.html.erb                          ← Session 46 (v1.0) NEW
│           ├── new.html.erb                           ← Session 46 (v1.0) NEW
│           └── show.html.erb                          ← Session 46 (v1.1)
├── config/
│   └── routes.rb                                      ← Session 46 (v2.9)
├── db/
│   └── migrate/
│       ├── 20260401000000_create_software_names.rb    ← Session 43 (v1.0) NEW
│       ├── 20260401000100_create_software_conditions.rb ← Session 43 (v1.0) NEW
│       └── 20260401000200_create_software_items.rb    ← Session 43 (v1.0) NEW
└── test/
    ├── controllers/
    │   ├── admin/
    │   │   ├── computer_models_controller_test.rb      ← Session 41 (v1.3)
    │   │   ├── data_transfers_controller_test.rb       ← Session 41 (v1.2)
    │   │   ├── software_conditions_controller_test.rb  ← Session 44 (v1.0) NEW
    │   │   └── software_names_controller_test.rb       ← Session 44 (v1.0) NEW
    │   ├── computers_controller_test.rb                ← Session 41 (v1.8)
    │   ├── owners_controller_test.rb                  ← Session 45 (v1.9)
    │   └── software_items_controller_test.rb          ← Session 46 (v1.1)
    ├── fixtures/
    │   ├── computer_models.yml                         ← Session 41 (v1.3)
    │   ├── computers.yml                              ← Session 41 (v1.9)
    │   ├── software_conditions.yml                    ← Session 43 (v1.0) NEW
    │   ├── software_items.yml                         ← Session 43 (v1.0) NEW
    │   └── software_names.yml                         ← Session 43 (v1.0) NEW
    ├── models/
    │   ├── computer_model_test.rb                     ← Session 41 (v1.3)
    │   ├── computer_test.rb                           ← Session 41 (v1.7)
    │   ├── software_condition_test.rb                 ← Session 43 (v1.0) NEW
    │   ├── software_item_test.rb                      ← Session 43 (v1.0) NEW
    │   └── software_name_test.rb                      ← Session 43 (v1.0) NEW
    └── services/
        ├── computer_model_export_service_test.rb      ← Session 41 (v1.2)
        ├── computer_model_import_service_test.rb      ← Session 41 (v1.2)
        ├── owner_export_service_test.rb               ← Session 41 (v1.4)
        └── owner_import_service_test.rb               ← Session 41 (v1.5)
```

---

**Key file versions** (updated each session):

    decor/docs/claude/DECOR_PROJECT.md                                                  v2.41 ← Session 46
    decor/docs/claude/SESSION_HANDOVER.md                                               v49.0 ← Session 45 (update at wrap-up)
    decor/config/routes.rb                                                              v2.9  ← Session 46
    decor/app/controllers/software_items_controller.rb                                  v1.1  ← Session 46
    decor/app/views/software_items/new.html.erb                                         v1.0  ← Session 46 NEW
    decor/app/views/software_items/edit.html.erb                                        v1.0  ← Session 46 NEW
    decor/app/views/software_items/_form.html.erb                                       v1.0  ← Session 46 NEW
    decor/app/views/owners/software.html.erb                                            v1.1  ← Session 46
    decor/app/views/software_items/show.html.erb                                        v1.1  ← Session 46
    decor/app/views/owners/show.html.erb                                                v2.4  ← Session 46
    decor/test/controllers/software_items_controller_test.rb                            v1.1  ← Session 46
    decor/app/controllers/owners_controller.rb                                          v2.0  ← Session 45
    decor/app/views/owners/computers.html.erb                                           v1.4  ← Session 45
    decor/app/views/owners/peripherals.html.erb                                         v1.3  ← Session 45
    decor/app/views/owners/components.html.erb                                          v1.4  ← Session 45
    decor/app/views/owners/connections.html.erb                                         v1.2  ← Session 45
    decor/test/controllers/owners_controller_test.rb                                    v1.9  ← Session 45
    decor/app/controllers/admin/software_names_controller.rb                            v1.0  ← Session 44 NEW
    decor/app/controllers/admin/software_conditions_controller.rb                       v1.0  ← Session 44 NEW
    decor/app/views/admin/software_names/index.html.erb                                 v1.0  ← Session 44 NEW
    decor/app/views/admin/software_names/new.html.erb                                   v1.0  ← Session 44 NEW
    decor/app/views/admin/software_names/edit.html.erb                                  v1.0  ← Session 44 NEW
    decor/app/views/admin/software_names/_form.html.erb                                 v1.0  ← Session 44 NEW
    decor/app/views/admin/software_conditions/index.html.erb                            v1.0  ← Session 44 NEW
    decor/app/views/admin/software_conditions/new.html.erb                              v1.0  ← Session 44 NEW
    decor/app/views/admin/software_conditions/edit.html.erb                             v1.0  ← Session 44 NEW
    decor/app/views/admin/software_conditions/_form.html.erb                            v1.0  ← Session 44 NEW
    decor/app/views/layouts/admin.html.erb                                              v2.1  ← Session 44
    decor/test/controllers/admin/software_names_controller_test.rb                      v1.0  ← Session 44 NEW
    decor/test/controllers/admin/software_conditions_controller_test.rb                 v1.0  ← Session 44 NEW
    decor/db/migrate/20260401000000_create_software_names.rb                            v1.0  ← Session 43 NEW
    decor/db/migrate/20260401000100_create_software_conditions.rb                       v1.0  ← Session 43 NEW
    decor/db/migrate/20260401000200_create_software_items.rb                            v1.0  ← Session 43 NEW
    decor/app/models/software_name.rb                                                   v1.0  ← Session 43 NEW
    decor/app/models/software_condition.rb                                              v1.0  ← Session 43 NEW
    decor/app/models/software_item.rb                                                   v1.0  ← Session 43 NEW
    decor/app/models/owner.rb                                                           v1.5  ← Session 43
    decor/app/models/computer.rb                                                        v2.1  ← Session 43
    decor/test/fixtures/software_names.yml                                              v1.0  ← Session 43 NEW
    decor/test/fixtures/software_conditions.yml                                         v1.0  ← Session 43 NEW
    decor/test/fixtures/software_items.yml                                              v1.0  ← Session 43 NEW
    decor/test/models/software_name_test.rb                                             v1.0  ← Session 43 NEW
    decor/test/models/software_condition_test.rb                                        v1.0  ← Session 43 NEW
    decor/test/models/software_item_test.rb                                             v1.0  ← Session 43 NEW
    decor/docs/claude/RAILS_SPECIFICS.md                                                v2.5  ← Session 42
    decor/app/views/admin/data_transfers/show.html.erb                                  v1.2  ← Session 42
    decor/app/controllers/data_transfers_controller.rb                                  v1.5  ← Session 42
    decor/app/views/data_transfers/show.html.erb                                        v1.8  ← Session 42
    decor/app/helpers/computers_helper.rb                                               v1.6  ← Session 42
    decor/app/models/computer_model.rb                                                  v1.3  ← Session 41
    decor/app/controllers/computers_controller.rb                                       v1.19 ← Session 41
    decor/app/controllers/admin/computer_models_controller.rb                           v1.4  ← Session 41
    decor/app/controllers/admin/data_transfers_controller.rb                            v1.2  ← Session 41
    decor/app/services/owner_export_service.rb                                          v1.4  ← Session 41
    decor/app/services/owner_import_service.rb                                          v1.5  ← Session 41
    decor/app/views/common/_navigation.html.erb                                         v2.0  ← Session 41
    decor/app/views/owners/_owner.html.erb                                              v3.5  ← Session 41
    decor/test/fixtures/computers.yml                                                   v1.9  ← Session 41
    decor/test/fixtures/computer_models.yml                                             v1.3  ← Session 41
    decor/test/models/computer_test.rb                                                  v1.7  ← Session 41
    decor/test/models/computer_model_test.rb                                            v1.3  ← Session 41
    decor/test/controllers/computers_controller_test.rb                                 v1.8  ← Session 41
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
- has_many :software_items, dependent: :destroy        ← Session 43
- has_many :connection_groups, dependent: :destroy

### Computer
- belongs_to :owner
- belongs_to :computer_model
- belongs_to :computer_condition (optional)
- belongs_to :run_status (optional)
- has_many :components, dependent: :destroy
- has_many :software_items, dependent: :destroy        ← Session 43
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
- belongs_to :computer, optional: true    ← "installed on"; covers peripherals too
- belongs_to :software_name
- belongs_to :software_condition, optional: true
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)
- version VARCHAR(20), optional
- description VARCHAR(100), optional
- history VARCHAR(200), optional
- Deleting a computer DESTROYS all software installed on it.
- Deleting an owner destroys all their software items.
- computer_id nullable → software not installed on any hardware is valid.

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
- label: VARCHAR(100) nullable
- Validations: computer_id uniqueness scoped to group; owner_member_id > 0; label max 100
- after_destroy: destroys parent group if member count falls below 2

---

## Software Feature — Session Plan  ← Session 43

Option C (full separation) chosen. Software is NOT a variant of Components.

    Session A  Migrations, models, fixtures, model tests              DONE ✓ (Session 43)
    Session B  Admin CRUD: SoftwareNames + SoftwareConditions         DONE ✓ (Session 44)
    Session C  Owner-facing: Software index + show (read-only)        DONE ✓ (Session 45)
    Session D  Owner-facing: Software create + edit + destroy         DONE ✓ (Session 46)
    Session E  Computer/peripheral show page integration              next
    Session F  Export/Import service updates (deferrable)

---

## Appliances → Peripherals Merger — FULLY COMPLETE (Sessions 41–42)

### What changed
- `appliance` (device_type=1) removed from enum on `Computer` and `ComputerModel`.
- Both enums now use hash form `{ computer: 0, peripheral: 2 }`.
- DB data migration (device_type=1 → 2) run on `computers` in Session 41 and on
  `computer_models` in Session 42 (the table was missed in Session 41).
- All fixtures, views, routes, controllers, helpers, services, and tests updated.
- Import backward compat: CSV record_type `"appliance"` → mapped to `:peripheral`.

### Intentional remaining references
- `OwnerImportService` — legacy alias mapping (`"appliance"` → `:peripheral`). Keep.
- `record_type` column in owner-facing data_transfers view. Keep.
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
that uses that column. Grep `db/schema.rb` for the column name to find all affected tables.

### Never Guess — Read the File or Ask (Session 39)
Claude must never invent a path helper, method name, or behaviour without reading
the actual file. See decor-session-rules skill v1.3 for full detail.

### enum hash form required after non-contiguous gap (Session 41)
`enum :device_type, { computer: 0, peripheral: 2 }, prefix: true`
Do NOT renumber peripheral to 1.

### owner_group_id / owner_member_id — 0.present? is true (Session 38)
Guard must be `return if field.to_i > 0` not `return if field.present?`.

### Remove routes AFTER updating views (Session 41)
Removing routes before views causes cascade test failures.

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
