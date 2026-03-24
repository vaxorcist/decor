# decor/docs/claude/DECOR_PROJECT.md
# version 2.33
# Session 38: Connections enhancement — owner_group_id, owner_member_id, port labels,
#   new connections sub-page at /owners/:id/connections, 5th summary card,
#   multi-row connections table on computer show page, form UI overhaul.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 24, 2026 (Session 38)
**Current Status:** Sessions 1–37 committed and deployed. Session 38 in progress: all files produced and partially tested. Tests for new validations pending (Session 39).

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 37 — Session 38 adds/changes marked below):
```
decor//
├── app/
│   ├── controllers/
│   │   ├── computers_controller.rb                           ← Session 38 updated (v1.18)
│   │   ├── connection_groups_controller.rb                   ← Session 38 updated (v1.1)
│   │   └── owners_controller.rb                             ← Session 38 updated (v1.8)
│   ├── javascript/
│   │   └── controllers/
│   │       └── connection_members_controller.js              ← Session 38 updated (v1.1)
│   ├── models/
│   │   ├── connection_group.rb                               ← Session 38 updated (v1.2)
│   │   └── connection_member.rb                             ← Session 38 updated (v1.1)
│   └── views/
│       ├── connection_groups/
│       │   └── _form.html.erb                               ← Session 38 updated (v1.2)
│       ├── computers/
│       │   └── show.html.erb                                ← Session 38 updated (v2.1)
│       └── owners/
│           ├── computers.html.erb                           ← Session 38 updated (v1.2)
│           ├── connections.html.erb                         ← Session 38 NEW
│           └── show.html.erb                                ← Session 38 updated (v2.1)
├── db/
│   └── migrate/
│       ├── 20260323000000_add_owner_group_id_to_connection_groups.rb   ← Session 38 new
│       └── 20260323010000_add_owner_member_id_and_label_to_connection_members.rb ← Session 38 new
└── test/
    ├── controllers/
    │   └── connection_groups_controller_test.rb             ← Session 38 updated (v1.1)
    └── fixtures/
        ├── connection_groups.yml                            ← Session 38 updated (v1.1)
        └── connection_members.yml                           ← Session 38 updated (v1.1)
```

Note: `appliances.html.erb`, `peripherals.html.erb`, `components.html.erb` each need
one manually added Connections tab line (see Session 38 summary). Routes.rb needs
`get :connections` added to the owners member block.

---

**Key file versions** (updated each session):

    decor/db/migrate/20260323000000_add_owner_group_id_to_connection_groups.rb         v1.0  ← Session 38 new
    decor/db/migrate/20260323010000_add_owner_member_id_and_label_to_connection_members.rb v1.0 ← Session 38 new
    decor/app/models/connection_group.rb                                                v1.2  ← Session 38
    decor/app/models/connection_member.rb                                               v1.1  ← Session 38
    decor/app/controllers/owners_controller.rb                                          v1.8  ← Session 38
    decor/app/controllers/connection_groups_controller.rb                               v1.1  ← Session 38
    decor/app/controllers/computers_controller.rb                                       v1.18 ← Session 38
    decor/app/views/owners/show.html.erb                                                v2.1  ← Session 38
    decor/app/views/owners/connections.html.erb                                         v1.0  ← Session 38 new
    decor/app/views/owners/computers.html.erb                                           v1.2  ← Session 38
    decor/app/views/connection_groups/_form.html.erb                                    v1.2  ← Session 38
    decor/app/views/computers/show.html.erb                                             v2.1  ← Session 38
    decor/app/javascript/controllers/connection_members_controller.js                   v1.1  ← Session 38
    decor/test/controllers/connection_groups_controller_test.rb                         v1.1  ← Session 38
    decor/test/fixtures/connection_groups.yml                                           v1.1  ← Session 38
    decor/test/fixtures/connection_members.yml                                          v1.1  ← Session 38
    decor/app/services/owner_export_service.rb                                          v1.3  ← Session 37
    decor/app/services/owner_import_service.rb                                          v1.4  ← Session 37
    decor/app/controllers/data_transfers_controller.rb                                  v1.4  ← Session 37
    decor/test/services/owner_export_service_test.rb                                    v1.3  ← Session 37
    decor/test/services/owner_import_service_test.rb                                    v1.4  ← Session 37
    decor/test/controllers/data_transfers_controller_test.rb                            v1.2  ← Session 37
    decor/config/routes.rb                                                              v2.4  ← Session 36
    decor/app/views/common/_navigation.html.erb                                         v1.8  ← Session 36
    decor/docs/claude/SESSION_HANDOVER.md                                               v42.0 ← Session 38

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
- device_type enum: 0=computer, 1=appliance, 2=peripheral (prefix: true)
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)

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

## Connections Feature — Status

    Part 1a: Migrations + models + fixtures             DONE (Session 31)
    Part 1b: Model tests                                DONE (Session 32)
    Part 2:  Admin ConnectionTypes CRUD                 DONE (Session 33)
    Part 3:  Owner device show pages — read-only        DONE (Sessions 34–35)
    Part 4:  Owner ConnectionGroup CRUD                 DONE (Session 36)
    Part 5:  owner_group_id / owner_member_id / labels  DONE (Session 38) ← tests pending

---

## Known Issues & Solutions

### owner_group_id / owner_member_id — 0.present? is true (Session 38)
Rails initialises integer columns with the DB DEFAULT (0). `0.present?` returns true
in Ruby, so a guard of `return if field.present?` never auto-assigns. Guard must be
`return if field.to_i > 0` to distinguish "user set a valid value" from "default 0".

### Duplicate computers in same group — DB constraint fires before validation (Session 38)
Rails' per-record uniqueness validator for `computer_id` scoped to `connection_group_id`
only queries the DB — it cannot detect two new in-memory members with the same ID.
The DB unique constraint fires and raises `ActiveRecord::RecordNotUnique`. Fix: add a
group-level `no_duplicate_computers` validator that checks `computer_id` uniqueness
across the in-memory collection before save.

### SQLite ALTER TABLE Limitations
Cannot add NOT NULL columns to existing tables — requires full table recreation.
Use `disable_ddl_transaction!` + raw SQL. See RAILS_SPECIFICS.md.

### Opening separator missing (Session 31)
Both opening and closing `================================================================================` are mandatory on every response.

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
