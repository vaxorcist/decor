# decor/docs/claude/DECOR_PROJECT.md
# version 2.29
# Session 13: device_type on computers, component_category on components; enum tests.
# Session 14: DRY Computer/Appliance Models admin pages; dropdown nav (admin.html.erb v1.3);
#   device_type on computer_models; routes :appliance_models; dropdown_controller.js.
# Session 16: device_type in export/import — "appliance" as third record_type value.
# Session 17: Appliances page; device_type filtering on Computers index;
#   edit/show pages use device_type for all labels.
# Session 18: device_type selector on new/edit form; owner show page splits computers
#   and appliances; site_texts table + Read Me page; redcarpet gem.
# Session 19: Components table column reorder + Order No. added on all three pages;
#   "By Order No." sort option on /components.
# Session 20: Remove device_type selector from edit form (hidden field); with_toc_data
#   for in-page anchor links; last_login_at on owners; Info dropdown nav; generalised
#   text upload/delete pages; news/barter_trade/privacy routes.
# Session 24: Admin Import/Export feature — Admin::DataTransfersController; five new
#   services (ComputerModel/ComponentType export+import, AllOwnersExport); routes v1.9;
#   admin nav "Imports/Exports" dropdown replaces old "Import/Export".
# Session 25: Peripherals — device_type: 2 on Computer and ComputerModel models;
#   CHECK(device_type IN (0,1,2)) migration; /peripherals index route; owner
#   sub-page /owners/:id/peripherals; admin Peripheral Models page; nav updated.
# Session 27: Sessions 25-26-27 committed and deployed. Peripheral fixture added to computer_models.yml.
# Session 28: Surface 1 of export/import peripherals gap closed. Unique constraints
#   on (owner_id, computer_model_id, serial_number) for computers and
#   (owner_id, component_type_id, serial_number) for components — both DB index
#   and Rails validation. Import duplicate check fixed to scope by model.
#   Flash message split into per-device-type counts. Inline flash removed from
#   data_transfers/show.html.erb (was duplicating layout _flashes partial).
#   492 tests, 0 failures. Surface 2 (Admin) pending.
# Session 29: Surface 2 — Admin Import/Export extended to cover peripheral_models.
#   Added "peripheral_models" data type to admin controller (build_export,
#   process_import, build_success_message). Fixed owner_collection success message
#   (v1.0 silently dropped appliance_count + peripheral_count; now shows all four
#   counts, omitting zeros). Updated admin show.html.erb selectors and CSV format
#   reference. Test files updated accordingly.
# Session 30: Fixed action_text-trix CVE (GHSA-qmpg-8xg6-ph5q) on feature PR.
#   Merged all 8 Dependabot PRs (#20,31,32,33,34,46,47,59) — all CI green.
#   Added CHECK(device_type IN (0,1,2)) constraint to computer_models table
#   (migration 20260318000000 — companion to Session 25 computers constraint).
# Session 31: Connections feature Part 1a — 3 migrations, 3 new models, 2 updated
#   models, 3 new fixture files. Tests deferred to Part 1b (next session).
# Session 32: Connections feature Part 1b — 3 model test files for ConnectionType,
#   ConnectionGroup, ConnectionMember. connection_group_test.rb patched to v1.1
#   (error key fix: :connection_members not :base for minimum_two_members).
#   532 tests, 0 failures. Committed and deployed.
# Session 33: Connections feature Part 2 — Admin ConnectionTypes CRUD.
#   Controller, 4 views, routes v2.3, admin nav v1.9 (Connections dropdown).
#   destroy checks return value; flash[:alert] on restrict_with_error failure.
#   Also fixed local Docker daemon DNS (daemon.json dns: 8.8.8.8) to unblock kamal deploy.
#   Tests pass. Committed and deployed.
# Session 34: Connections feature Part 3 — read-only connections display on device
#   show page. computers_controller.rb show action loads @connection_groups with
#   eager-loading. show.html.erb adds Connections section (Type | Label | Connected to).
#   Tests deferred to next session.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 19, 2026 (Session 34)
**Current Status:** Sessions 1–33 committed and deployed. Session 34 (Part 3) ready to commit. Next: Part 3 tests + commit/deploy, then Part 4 — Owner ConnectionGroup CRUD.

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 34 — no new files added; two files updated):
```
decor//
├── app/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── base_controller.rb
│   │   │   ├── bulk_uploads_controller.rb
│   │   │   ├── component_conditions_controller.rb
│   │   │   ├── component_types_controller.rb
│   │   │   ├── computer_models_controller.rb
│   │   │   ├── conditions_controller.rb
│   │   │   ├── connection_types_controller.rb        ← Session 33 new
│   │   │   ├── data_transfers_controller.rb
│   │   │   ├── invites_controller.rb
│   │   │   ├── owners_controller.rb
│   │   │   ├── run_statuses_controller.rb
│   │   │   └── site_texts_controller.rb
│   │   ├── concerns/
│   │   │   ├── authentication.rb
│   │   │   └── pagination.rb
│   │   ├── application_controller.rb
│   │   ├── components_controller.rb
│   │   ├── computers_controller.rb                   ← Session 34 updated (v1.17)
│   │   ├── data_transfers_controller.rb
│   │   ├── home_controller.rb
│   │   ├── owners_controller.rb
│   │   ├── password_resets_controller.rb
│   │   ├── sessions_controller.rb
│   │   └── site_texts_controller.rb
│   ├── helpers/
│   │   └── (unchanged)
│   ├── javascript/
│   │   └── (unchanged)
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── component_condition.rb
│   │   ├── component.rb
│   │   ├── component_type.rb
│   │   ├── computer_condition.rb
│   │   ├── computer_model.rb
│   │   ├── computer.rb
│   │   ├── connection_group.rb
│   │   ├── connection_member.rb
│   │   ├── connection_type.rb
│   │   ├── current.rb
│   │   ├── invite.rb
│   │   ├── owner.rb
│   │   ├── run_status.rb
│   │   └── site_text.rb
│   ├── services/
│   │   └── (unchanged)
│   └── views/
│       ├── admin/
│       │   ├── connection_types/                     ← Session 33 new directory
│       │   │   ├── _form.html.erb                    ← Session 33 new
│       │   │   ├── edit.html.erb                     ← Session 33 new
│       │   │   ├── index.html.erb                    ← Session 33 new
│       │   │   └── new.html.erb                      ← Session 33 new
│       │   └── (all other admin views unchanged)
│       ├── computers/
│       │   └── show.html.erb                         ← Session 34 updated (v1.8)
│       └── (all other views unchanged)
├── db/
│   ├── migrate/
│   │   ├── (prior migrations unchanged)
│   │   ├── 20260316100000_add_device_type_check_to_computers.rb
│   │   ├── 20260316110000_add_unique_index_to_components_serial_number.rb
│   │   ├── 20260316120000_add_unique_index_to_computers_serial_number.rb
│   │   ├── 20260318000000_add_device_type_check_to_computer_models.rb
│   │   ├── 20260319000000_create_connection_types.rb
│   │   ├── 20260319010000_create_connection_groups.rb
│   │   └── 20260319020000_create_connection_members.rb
│   └── (schema, seeds unchanged)
├── docs/
│   └── claude/
│       ├── COMMON_BEHAVIOR.md
│       ├── DECOR_PROJECT.md
│       ├── PROGRAMMING_GENERAL.md
│       ├── RAILS_SPECIFICS.md
│       └── SESSION_HANDOVER.md
├── config/
│   └── routes.rb                                     ← Session 33 updated (v2.3)
└── test/
    ├── fixtures/
    │   ├── connection_groups.yml
    │   ├── connection_members.yml
    │   ├── connection_types.yml
    │   └── (all others unchanged)
    ├── controllers/
    │   └── admin/
    │       ├── connection_types_controller_test.rb    ← Session 33 new
    │       └── (all others unchanged)
    └── models/
        ├── connection_group_test.rb
        ├── connection_member_test.rb
        ├── connection_type_test.rb
        └── (all others unchanged)
```

---

**Key file versions** (updated each session):

    decor/app/controllers/computers_controller.rb                            v1.17 ← Session 34
    decor/app/views/computers/show.html.erb                                  v1.8  ← Session 34
    decor/app/controllers/admin/connection_types_controller.rb               v1.0  ← Session 33 new
    decor/app/views/admin/connection_types/index.html.erb                    v1.0  ← Session 33 new
    decor/app/views/admin/connection_types/_form.html.erb                    v1.0  ← Session 33 new
    decor/app/views/admin/connection_types/new.html.erb                      v1.0  ← Session 33 new
    decor/app/views/admin/connection_types/edit.html.erb                     v1.0  ← Session 33 new
    decor/config/routes.rb                                                   v2.3  ← Session 33
    decor/app/views/layouts/admin.html.erb                                   v1.9  ← Session 33
    decor/test/controllers/admin/connection_types_controller_test.rb         v1.0  ← Session 33 new
    decor/test/models/connection_type_test.rb                                v1.0  ← Session 32 new
    decor/test/models/connection_group_test.rb                               v1.1  ← Session 32 (patched: error key fix)
    decor/test/models/connection_member_test.rb                              v1.0  ← Session 32 new
    decor/app/models/connection_type.rb                                      v1.0  ← Session 31 new
    decor/app/models/connection_group.rb                                     v1.0  ← Session 31 new
    decor/app/models/connection_member.rb                                    v1.0  ← Session 31 new
    decor/app/models/computer.rb                                             v1.9  ← Session 31
    decor/app/models/owner.rb                                                v1.4  ← Session 31
    decor/db/migrate/20260319000000_create_connection_types.rb               v1.0  ← Session 31 new
    decor/db/migrate/20260319010000_create_connection_groups.rb              v1.0  ← Session 31 new
    decor/db/migrate/20260319020000_create_connection_members.rb             v1.0  ← Session 31 new
    decor/test/fixtures/connection_types.yml                                 v1.0  ← Session 31 new
    decor/test/fixtures/connection_groups.yml                                v1.0  ← Session 31 new
    decor/test/fixtures/connection_members.yml                               v1.0  ← Session 31 new
    decor/docs/claude/SESSION_HANDOVER.md                                    v37.0 ← Session 34
    decor/docs/claude/DECOR_PROJECT.md                                       v2.29 ← Session 34
    decor/db/migrate/20260318000000_add_device_type_check_to_computer_models.rb  v1.0  ← Session 30 new
    decor/app/controllers/admin/data_transfers_controller.rb                 v1.1  ← Session 29
    decor/app/views/admin/data_transfers/show.html.erb                       v1.1  ← Session 29
    decor/test/controllers/admin/data_transfers_controller_test.rb           v1.1  ← Session 29
    decor/test/services/computer_model_export_service_test.rb                v1.1  ← Session 29
    decor/test/services/computer_model_import_service_test.rb                v1.1  ← Session 29
    decor/db/migrate/20260316120000_add_unique_index_to_computers_serial_number.rb  v1.0  ← Session 28 new
    decor/db/migrate/20260316110000_add_unique_index_to_components_serial_number.rb v1.0  ← Session 28 new
    decor/app/models/component.rb                                            v1.5  ← Session 28
    decor/app/services/owner_export_service.rb                               v1.2  ← Session 28
    decor/app/services/owner_import_service.rb                               v1.3  ← Session 28
    decor/app/controllers/data_transfers_controller.rb                       v1.3  ← Session 28
    decor/app/views/data_transfers/show.html.erb                             v1.7  ← Session 28
    decor/test/models/computer_test.rb                                       v1.6  ← Session 28
    decor/test/models/component_test.rb                                      v1.5  ← Session 28
    decor/test/services/owner_export_service_test.rb                         v1.2  ← Session 28
    decor/test/services/owner_import_service_test.rb                         v1.3  ← Session 28
    decor/test/controllers/owners_controller_destroy_test.rb                 v1.3  ← Session 28
    decor/test/controllers/admin/computer_models_controller_test.rb          v1.2  ← Session 27
    decor/test/fixtures/computer_models.yml                                  v1.2  ← Session 27
    decor/app/controllers/owners_controller.rb                               v1.7  ← Session 25
    decor/test/fixtures/owners.yml                                           v2.1  ← Session 13
    decor/test/fixtures/computers.yml                                        v1.8  ← Session 25

---

## Data Model Overview

### Owner
- has_many :computers, dependent: :destroy            (declared first — ordering matters)
- has_many :components, dependent: :destroy
- has_many :connection_groups, dependent: :destroy    (declared after computers)
- Visibility settings: real_name, email, country (public/members_only/private)
- Authentication via has_secure_password

### Computer
- belongs_to :owner
- belongs_to :computer_model
- belongs_to :computer_condition (optional)
- belongs_to :run_status (optional)
- has_many :components, dependent: :destroy
- has_many :connection_members, dependent: :destroy   (Ruby destroy — callbacks must fire)
- has_many :connection_groups, through: :connection_members
- device_type enum: 0 = computer (default), 1 = appliance, 2 = peripheral
  prefix: true → device_type_computer?, device_type_appliance?, device_type_peripheral?
  CHECK(device_type IN (0,1,2)) on computers table (migration 20260316100000).
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted, prefix: true
- Validations: serial_number presence + uniqueness scoped to (owner_id, computer_model_id)

### ComputerModel
- device_type enum: 0 = computer (default), 1 = appliance, 2 = peripheral
  CHECK(device_type IN (0,1,2)) constraint (migration 20260318000000).
- has_many :computers, dependent: :restrict_with_error
- Validations: name presence + uniqueness

### Component
- belongs_to :owner
- belongs_to :computer (optional)
- belongs_to :component_type
- belongs_to :component_condition (optional)
- component_category enum: 0 = integral (default), 1 = peripheral
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted, prefix: true
- serial_number: uniqueness scoped to (owner_id, component_type_id), allow_blank: true

### ConnectionType
- has_many :connection_groups, dependent: :restrict_with_error
- Admin-managed (same pattern as ComponentType, RunStatus)
- Validations: name presence + uniqueness; label max 100 chars

### ConnectionGroup
- belongs_to :owner
- belongs_to :connection_type (optional)
- has_many :connection_members, dependent: :delete_all
- has_many :computers, through: :connection_members
- accepts_nested_attributes_for :connection_members, allow_destroy: true
- Validations: minimum 2 active members; all members must belong to group's owner

### ConnectionMember
- belongs_to :connection_group
- belongs_to :computer
- Validation: computer_id uniqueness scoped to connection_group_id
- after_destroy: destroys parent group if member count falls below 2

---

## Connections Feature — Planned Parts

    Part 1a: Migrations + models + fixtures             DONE (Session 31)
    Part 1b: Model tests                                DONE (Session 32)
    Part 2:  Admin ConnectionTypes CRUD                 DONE (Session 33)
    Part 3:  Owner device show pages — read-only        DONE (Session 34) — tests deferred
    Part 4:  Owner ConnectionGroup CRUD                 NEXT

---

## Export / Import Status (Session 29, unchanged)

### Surface 1 — Owner Export / Import  (/data_transfer) — COMPLETE
### Surface 2 — Admin Imports / Exports  (/admin/data_transfer) — COMPLETE (Session 29)

---

## Known Issues & Solutions

### SQLite ALTER TABLE Limitations
Cannot add named CHECK constraints to existing tables — requires full table recreation.
Use `disable_ddl_transaction!` + raw SQL in migrations. See RAILS_SPECIFICS.md.

### SQLite FK Enforcement
Must be explicitly enabled via `foreign_keys: true` in `decor/config/database.yml`.
Enabled as of Session 6.

### SQLite VARCHAR Enforcement
VARCHAR(n) is cosmetic in SQLite — CHECK constraints required for actual enforcement.

### form_with Class Name / Route Name Mismatch
Use both `url:` and `scope:` on `form_with`.

### restrict_with_error — Destroy Failure Handling
Always check the return value of destroy and redirect with `flash[:alert]`.

### ERB + whitespace-pre-wrap Renders Leading Whitespace Literally
Put the ERB tag on the same line as the opening tag.

### f.submit Label Does Not Respect Model Enum Values
Pass an explicit string label.

### Squash Merge Git Divergence
Use `gh pr merge --merge` (not `--squash`).

### Multi-table ORDER BY Requires Arel.sql()
Wrap in `Arel.sql()` for ORDER BY strings with dots or SQL keywords.

### build(device_type: nil) Overrides Enum Default
Build without the key, then assign conditionally.

### _filters.html.erb Type filter — show only on Computers page
Use `if @device_context == "computer"`, NOT `unless @device_context == "appliance"`.

### Fixture File vs Handover Summary — Trust the File, Not the Summary
Always upload fixture files at end of session they are modified. (Session 27.)

### Import duplicate check must scope by model, not just serial
`@owner.computers.exists?(serial_number:)` alone blocks different-model devices
with the same serial. Always scope by `computer_model:` as well. (Session 28.)

### ConnectionGroup dependent: :delete_all vs ConnectionMember dependent: :destroy
ConnectionGroup uses delete_all on its members (no callbacks needed when the group
is the source of deletion). Computer uses destroy on its members (callbacks MUST fire
to trigger the group auto-cleanup). Mixing these up breaks the cascade logic.

### Opening separator missing (Session 31)
Every response requires BOTH the opening and closing `================================================================================`
separator lines. The closing separator with token estimate was present; the opening
was omitted. Both are mandatory on every response without exception.

### Local Docker daemon DNS — kamal deploy DNS failure
Docker buildx containers use the daemon's DNS config, not the host's systemd-resolved.
If kamal deploy fails with "lookup registry-1.docker.io on [::1]:53: connection refused",
add `"dns": ["8.8.8.8", "8.8.4.4"]` to `/etc/docker/daemon.json` on the build machine
and restart Docker. (Session 33.)

### Connections show page — peer filtering uses reject not where.not
`group.computers.reject { |c| c.id == @computer.id }` uses the preloaded cache.
`group.computers.where.not(id: @computer.id)` would fire a new DB query per row,
defeating the eager-load. Always use in-memory reject when iterating preloaded
has_many :through associations on a show page. (Session 34.)

---

## Design Patterns

### Color Scheme
- All clickable values: `text-indigo-600 hover:text-indigo-900`
- Destructive actions: `text-red-600 hover:text-red-900`
- Non-clickable data: `text-stone-600`
- Table headers: `text-stone-500 uppercase`
- Barter — offered: `text-green-700`
- Barter — wanted: `text-amber-600`
- Barter — no_barter: `text-stone-400` (em-dash)

### Button Labels
- Primary: descriptive ("Update Computer", "Save Component")
- Secondary: "Done" — never "Cancel"

---

## Quick Reference Commands

```bash
bin/rails server                                   # Start server
bin/rails test                                     # Run all tests
bin/rails db:migrate                               # Run migrations
kamal app exec --reuse "bin/rails db:migrate"      # Production migration
kamal deploy                                       # Deploy
gh pr merge --merge --delete-branch                # Merge PR (use --merge, not --squash)
git pull                                           # Sync after merge
```

---

**End of DECOR_PROJECT.md**
