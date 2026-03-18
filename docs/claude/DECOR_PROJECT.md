# decor/docs/claude/DECOR_PROJECT.md
# version 2.23
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
# Session 27: Sessions 25-26-27 committed. Peripheral fixture added to computer_models.yml.
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

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 17, 2026 (Session 29)
**Current Status:** Sessions 1–28 committed and deployed. Session 29 ready to commit.

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 27, March 16, 2026 — unchanged from Session 25):
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
│   │   ├── computers_controller.rb
│   │   ├── data_transfers_controller.rb
│   │   ├── home_controller.rb
│   │   ├── owners_controller.rb
│   │   ├── password_resets_controller.rb
│   │   ├── sessions_controller.rb
│   │   └── site_texts_controller.rb
│   ├── helpers/
│   │   ├── application_helper.rb
│   │   ├── components_helper.rb
│   │   ├── computers_helper.rb
│   │   ├── navigation_helper.rb
│   │   ├── owners_helper.rb
│   │   └── style_helper.rb
│   ├── javascript/
│   │   ├── controllers/
│   │   │   ├── application.js
│   │   │   ├── back_controller.js
│   │   │   ├── computer_select_controller.js
│   │   │   ├── dropdown_controller.js
│   │   │   ├── hello_controller.js
│   │   │   ├── index.js
│   │   │   ├── load_more_controller.js
│   │   │   └── password_generator_controller.js
│   │   └── application.js
│   ├── jobs/
│   │   ├── application_job.rb
│   │   └── invite_reminder_job.rb
│   ├── mailers/
│   │   ├── application_mailer.rb
│   │   ├── invite_mailer.rb
│   │   └── password_reset_mailer.rb
│   ├── models/
│   │   ├── decor/
│   │   │   └── routes.rb
│   │   ├── application_record.rb
│   │   ├── component_condition.rb
│   │   ├── component.rb
│   │   ├── component_type.rb
│   │   ├── computer_condition.rb
│   │   ├── computer_model.rb
│   │   ├── computer.rb
│   │   ├── current.rb
│   │   ├── invite.rb
│   │   ├── owner.rb
│   │   ├── run_status.rb
│   │   └── site_text.rb
│   ├── services/
│   │   ├── all_owners_export_service.rb
│   │   ├── bulk_upload_service.rb
│   │   ├── component_type_export_service.rb
│   │   ├── component_type_import_service.rb
│   │   ├── computer_model_export_service.rb
│   │   ├── computer_model_import_service.rb
│   │   ├── owner_export_service.rb
│   │   └── owner_import_service.rb
│   └── views/
│       ├── admin/
│       │   ├── bulk_uploads/
│       │   │   └── new.html.erb
│       │   ├── component_conditions/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── component_types/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── computer_models/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── conditions/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── data_transfers/
│       │   │   └── show.html.erb
│       │   ├── invites/
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── owners/
│       │   │   ├── edit.html.erb
│       │   │   └── index.html.erb
│       │   ├── run_statuses/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   └── site_texts/
│       │       ├── delete_confirm.html.erb
│       │       └── new.html.erb
│       ├── common/
│       │   ├── _flashes.html.erb
│       │   ├── _footer.html.erb
│       │   ├── _navigation.html.erb
│       │   └── _record_errors.html.erb
│       ├── components/
│       │   ├── _component.html.erb
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── computers/
│       │   ├── _computer_component_form.html.erb
│       │   ├── _computer.html.erb
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── data_transfers/
│       │   └── show.html.erb
│       ├── home/
│       │   └── index.html.erb
│       ├── layouts/
│       │   ├── admin.html.erb
│       │   ├── application.html.erb
│       │   ├── mailer.html.erb
│       │   └── mailer.text.erb
│       ├── mailers/
│       │   ├── invite_mailer/
│       │   │   ├── invite_email.html.erb
│       │   │   ├── invite_email.text.erb
│       │   │   ├── reminder_email.html.erb
│       │   │   └── reminder_email.text.erb
│       │   └── password_reset_mailer/
│       │       ├── invite_email.html.erb
│       │       └── reset_email.html.erb
│       ├── owners/
│       │   ├── appliances.html.erb
│       │   ├── components.html.erb
│       │   ├── computers.html.erb
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   ├── _owner.html.erb
│       │   ├── peripherals.html.erb
│       │   ├── _profile.html.erb
│       │   └── show.html.erb
│       ├── password_resets/
│       │   ├── edit.html.erb
│       │   └── new.html.erb
│       ├── pwa/
│       │   ├── manifest.json.erb
│       │   └── service-worker.js
│       ├── sessions/
│       │   └── new.html.erb
│       ├── shared/
│       │   └── _load_more.html.erb
│       └── site_texts/
│           └── show.html.erb
├── bin/
│   └── (unchanged)
├── config/
│   └── (unchanged)
├── db/
│   ├── migrate/
│   │   ├── (prior migrations unchanged)
│   │   ├── 20260316100000_add_device_type_check_to_computers.rb
│   │   ├── 20260316110000_add_unique_index_to_components_serial_number.rb
│   │   └── 20260316120000_add_unique_index_to_computers_serial_number.rb
│   └── (schema, seeds unchanged)
├── docs/
│   └── claude/
│       ├── COMMON_BEHAVIOR.md
│       ├── DECOR_PROJECT.md
│       ├── PROGRAMMING_GENERAL.md
│       ├── RAILS_SPECIFICS.md
│       └── SESSION_HANDOVER.md
└── test/
    └── (see key versions table)
```

---

**Key file versions** (updated each session):

    decor/app/controllers/admin/data_transfers_controller.rb                         v1.1  ← Session 29
    decor/app/views/admin/data_transfers/show.html.erb                               v1.1  ← Session 29
    decor/test/controllers/admin/data_transfers_controller_test.rb                   v1.1  ← Session 29
    decor/test/services/computer_model_export_service_test.rb                        v1.1  ← Session 29
    decor/test/services/computer_model_import_service_test.rb                        v1.1  ← Session 29
    decor/db/migrate/20260316120000_add_unique_index_to_computers_serial_number.rb   v1.0  ← Session 28 new
    decor/db/migrate/20260316110000_add_unique_index_to_components_serial_number.rb  v1.0  ← Session 28 new
    decor/app/models/computer.rb                                                     v1.8  ← Session 28
    decor/app/models/component.rb                                                    v1.5  ← Session 28
    decor/app/services/owner_export_service.rb                                       v1.2  ← Session 28
    decor/app/services/owner_import_service.rb                                       v1.3  ← Session 28
    decor/app/controllers/data_transfers_controller.rb                               v1.3  ← Session 28
    decor/app/views/data_transfers/show.html.erb                                     v1.7  ← Session 28
    decor/test/models/computer_test.rb                                               v1.6  ← Session 28
    decor/test/models/component_test.rb                                              v1.5  ← Session 28
    decor/test/services/owner_export_service_test.rb                                 v1.2  ← Session 28
    decor/test/services/owner_import_service_test.rb                                 v1.3  ← Session 28
    decor/test/controllers/owners_controller_destroy_test.rb                         v1.3  ← Session 28
    decor/test/controllers/admin/computer_models_controller_test.rb                  v1.2  ← Session 27
    decor/test/fixtures/computer_models.yml                                          v1.2  ← Session 27
    decor/docs/claude/SESSION_HANDOVER.md                                            v31.0 ← Session 29
    decor/docs/claude/DECOR_PROJECT.md                                               v2.23 ← Session 29
    decor/db/migrate/20260316100000_add_device_type_check_to_computers.rb            v1.0  ← Session 25 new
    decor/app/models/computer_model.rb                                               v1.2  ← Session 25
    decor/config/routes.rb                                                           v2.2  ← Session 25
    decor/app/controllers/owners_controller.rb                                       v1.7  ← Session 25
    decor/app/controllers/computers_controller.rb                                    v1.16 ← Session 25
    decor/app/controllers/admin/computer_models_controller.rb                        v1.3  ← Session 25
    decor/app/views/owners/peripherals.html.erb                                      v1.0  ← Session 25 new
    decor/app/views/owners/computers.html.erb                                        v1.1  ← Session 25
    decor/app/views/owners/appliances.html.erb                                       v1.1  ← Session 25
    decor/app/views/owners/show.html.erb                                             v2.0  ← Session 25
    decor/app/views/common/_navigation.html.erb                                      v1.7  ← Session 25
    decor/app/views/layouts/admin.html.erb                                           v1.8  ← Session 25
    decor/app/views/computers/_filters.html.erb                                      v1.5  ← Session 25
    decor/test/fixtures/computers.yml                                                v1.8  ← Session 25
    decor/test/controllers/owners_controller_test.rb                                 v1.4  ← Session 25
    decor/app/views/owners/components.html.erb                                       v1.1  ← Session 26
    decor/test/controllers/computers_controller_test.rb                              v1.7  ← Session 26
    decor/app/services/computer_model_export_service.rb                              v1.0  ← Session 24 new
    decor/app/services/computer_model_import_service.rb                              v1.0  ← Session 24 new
    decor/app/services/component_type_export_service.rb                              v1.0  ← Session 24 new
    decor/app/services/component_type_import_service.rb                              v1.0  ← Session 24 new
    decor/app/services/all_owners_export_service.rb                                  v1.0  ← Session 24 new
    decor/test/services/component_type_export_service_test.rb                        v1.0  ← Session 24 new
    decor/test/services/component_type_import_service_test.rb                        v1.0  ← Session 24 new
    decor/test/fixtures/owners.yml                                                   v2.1  ← Session 13

---

## Data Model Overview

### Owner
- has_many computers
- has_many components
- Visibility settings: real_name, email, country (public/members_only/private)
- Authentication via has_secure_password

### Computer
- belongs_to owner
- belongs_to computer_model
- belongs_to computer_condition (optional)
- belongs_to run_status (optional)
- has_many components, dependent: :destroy
- device_type enum: 0 = computer (default), 1 = appliance, 2 = peripheral
  prefix: true → device_type_computer?, device_type_appliance?, device_type_peripheral?
  CHECK(device_type IN (0,1,2)) constraint on computers table (migration 20260316100000).
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted, prefix: true
- Validations:
  - serial_number: presence: true
  - serial_number: uniqueness scoped to (owner_id, computer_model_id)
    DB index: index_computers_on_owner_model_and_serial_number (migration 20260316120000)
  - order_number: max 20 characters, optional

### ComputerModel
- device_type enum: 0 = computer (default), 1 = appliance, 2 = peripheral
  No CHECK constraint yet on computer_models.device_type — pending future migration.
- has_many computers, dependent: :restrict_with_error
- Validations: name presence + uniqueness

### Component
- belongs_to owner
- belongs_to computer (optional)
- belongs_to component_type
- belongs_to component_condition (optional)
- component_category enum: 0 = integral (default), 1 = peripheral
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted, prefix: true
- Validations:
  - serial_number: uniqueness scoped to (owner_id, component_type_id), allow_blank: true
    DB index: index_components_on_owner_type_and_serial_number (migration 20260316110000)

---

## Export / Import Status (Session 29)

### Surface 1 — Owner Export / Import  (/data_transfer) — COMPLETE
All three device types (computer, appliance, peripheral) export and import correctly.
Duplicate checks scope by (owner, model, serial) for devices and (owner, type, serial) for components.

### Surface 2 — Admin Imports / Exports  (/admin/data_transfer) — COMPLETE (Session 29)
All three ComputerModel device types (computer, appliance, peripheral) now supported in
both export and import. Owner collection success message shows all four device-type counts.

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

### Admin controller owner_collection success message missing appliance/peripheral counts
Fixed Session 29. v1.0 only read `computer_count` + `component_count` from result;
OwnerImportService v1.3 (Session 28) returns four separate keys. Admin controller
`build_success_message` now reads all four, omitting zero counts.

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
