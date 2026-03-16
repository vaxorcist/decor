# decor/docs/claude/DECOR_PROJECT.md
# version 2.20
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

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 16, 2026 (Session 25)
**Current Status:** Sessions 1–24 committed and deployed. Session 25 complete, ready to commit.

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 25, March 16, 2026):
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
│   ├── brakeman*
│   ├── bundler-audit*
│   ├── ci*
│   ├── dev*
│   ├── docker-entrypoint*
│   ├── importmap*
│   ├── jobs*
│   ├── kamal*
│   ├── rails*
│   ├── rake*
│   ├── rubocop*
│   ├── setup*
│   └── thrust*
├── config/
│   ├── environments/
│   │   ├── development.rb
│   │   ├── production.rb
│   │   └── test.rb
│   ├── initializers/
│   │   ├── assets.rb
│   │   ├── content_security_policy.rb
│   │   ├── filter_parameter_logging.rb
│   │   ├── inflections.rb
│   │   └── require_csv.rb
│   ├── locales/
│   │   └── en.yml
│   ├── application.rb
│   ├── boot.rb
│   ├── brakeman.ignore
│   ├── bundler-audit.yml
│   ├── cable.yml
│   ├── cache.yml
│   ├── ci.rb
│   ├── credentials.yml.enc
│   ├── database.yml
│   ├── deploy.yml
│   ├── environment.rb
│   ├── importmap.rb
│   ├── master.key
│   ├── puma.rb
│   ├── queue.yml
│   ├── recurring.yml
│   ├── routes.rb
│   ├── secrets.yml
│   └── storage.yml
├── db/
│   ├── migrate/
│   │   ├── 20251223133731_create_owners.rb
│   │   ├── 20251223140358_create_computer_models.rb
│   │   ├── 20251223140432_create_computers.rb
│   │   ├── 20251223140517_create_component_types.rb
│   │   ├── 20251223140542_create_components.rb
│   │   ├── 20251223144611_add_password_reset_to_owners.rb
│   │   ├── 20251223145711_add_admin_to_owners.rb
│   │   ├── 20251223173121_create_invites.rb
│   │   ├── 20251229120631_create_conditions.rb
│   │   ├── 20251229120632_create_run_statuses.rb
│   │   ├── 20251229120709_migrate_computer_conditions_and_run_statuses.rb
│   │   ├── 20251231133644_add_history_and_condition_to_components.rb
│   │   ├── 20251231133716_make_condition_and_run_status_optional_in_computers.rb
│   │   ├── 20260212135907_make_serial_number_required.rb
│   │   ├── 20260220093615_rename_description_to_order_number_on_computers.rb
│   │   ├── 20260220140000_add_reminder_sent_at_to_invites.rb
│   │   ├── 20260225120000_component_conditions_and_type_cleanup.rb
│   │   ├── 20260303100000_add_device_type_to_computers.rb
│   │   ├── 20260303100001_add_component_category_to_components.rb
│   │   ├── 20260303110000_add_device_type_to_computer_models.rb
│   │   ├── 20260304120000_add_cascade_delete_components_computer.rb
│   │   ├── 20260306100000_create_site_texts.rb
│   │   ├── 20260308100000_add_last_login_at_to_owners.rb
│   │   ├── 20260309100000_add_barter_status_to_computers.rb
│   │   ├── 20260309100001_add_barter_status_to_components.rb
│   │   └── 20260316100000_add_device_type_check_to_computers.rb
│   ├── cable_schema.rb
│   ├── cache_schema.rb
│   ├── queue_schema.rb
│   ├── schema.rb
│   └── seeds.rb
├── docs/
│   └── claude/
│       ├── COMMON_BEHAVIOR.md
│       ├── DECOR_PROJECT.md
│       ├── PROGRAMMING_GENERAL.md
│       ├── RAILS_SPECIFICS.md
│       └── SESSION_HANDOVER.md
├── public/
│   ├── 400.html
│   ├── 404.html
│   ├── 406-unsupported-browser.html
│   ├── 422.html
│   ├── 500.html
│   ├── icon.png
│   ├── icon.svg
│   └── robots.txt
├── script/
│   └── generate_fixture_passwords.rb
├── test/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── admin_owners_controller_test.rb
│   │   │   ├── component_conditions_controller_test.rb
│   │   │   ├── component_types_controller_test.rb
│   │   │   ├── computer_models_controller_test.rb
│   │   │   ├── conditions_controller_test.rb
│   │   │   ├── data_transfers_controller_test.rb
│   │   │   ├── invites_controller_test.rb
│   │   │   ├── run_statuses_controller_test.rb
│   │   │   └── site_texts_controller_test.rb
│   │   ├── components_controller_test.rb
│   │   ├── computers_controller_test.rb
│   │   ├── data_transfers_controller_test.rb
│   │   ├── owners_controller_destroy_test.rb
│   │   ├── owners_controller_password_test.rb
│   │   ├── owners_controller_test.rb
│   │   ├── password_resets_controller_test.rb
│   │   └── sessions_controller_test.rb
│   ├── fixtures/
│   │   ├── component_conditions.yml
│   │   ├── components.yml
│   │   ├── component_types.yml
│   │   ├── computer_conditions.yml
│   │   ├── computer_models.yml
│   │   ├── computers.yml
│   │   ├── invites.yml
│   │   ├── owners.yml
│   │   └── run_statuses.yml
│   ├── jobs/
│   │   └── invite_reminder_job_test.rb
│   ├── mailers/
│   │   ├── previews/
│   │   │   └── invite_mailer_preview.rb
│   │   ├── invite_mailer_test.rb
│   │   └── password_reset_mailer_test.rb
│   ├── models/
│   │   ├── component_test.rb
│   │   ├── component_type_test.rb
│   │   ├── computer_condition_test.rb
│   │   ├── computer_model_test.rb
│   │   ├── computer_test.rb
│   │   ├── invite_test.rb
│   │   ├── owner_test.rb
│   │   ├── run_status_test.rb
│   │   └── site_text_test.rb
│   ├── services/
│   │   ├── component_type_export_service_test.rb
│   │   ├── component_type_import_service_test.rb
│   │   ├── computer_model_export_service_test.rb
│   │   ├── computer_model_import_service_test.rb
│   │   ├── owner_export_service_test.rb
│   │   └── owner_import_service_test.rb
│   ├── support/
│   │   └── authentication_helper.rb
│   ├── application_system_test_case.rb
│   └── test_helper.rb
├── config.ru
├── Dockerfile
├── Gemfile
├── Procfile.dev
├── Rakefile
├── README.md
└── rich.html

61 directories, 285 files
```

**Key file versions** (updated each session):

    decor/db/migrate/20260316100000_add_device_type_check_to_computers.rb  v1.0  ← Session 25 (new)
    decor/app/models/computer.rb                                            v1.7  ← Session 25 (peripheral: 2)
    decor/app/models/computer_model.rb                                      v1.2  ← Session 25 (peripheral: 2)
    decor/config/routes.rb                                                  v2.2  ← Session 25
    decor/app/controllers/owners_controller.rb                              v1.7  ← Session 25 (peripherals action)
    decor/app/controllers/computers_controller.rb                           v1.16 ← Session 25 (peripheral context)
    decor/app/controllers/admin/computer_models_controller.rb               v1.3  ← Session 25 (peripheral branch)
    decor/app/views/owners/peripherals.html.erb                             v1.0  ← Session 25 (new)
    decor/app/views/owners/computers.html.erb                               v1.1  ← Session 25 (Peripherals tab)
    decor/app/views/owners/appliances.html.erb                              v1.1  ← Session 25 (Peripherals tab)
    decor/app/views/owners/show.html.erb                                    v2.0  ← Session 25 (Peripherals card)
    decor/app/views/common/_navigation.html.erb                             v1.7  ← Session 25 (Peripherals link)
    decor/app/views/layouts/admin.html.erb                                  v1.8  ← Session 25 (Peripherals dropdown)
    decor/app/views/computers/_filters.html.erb                             v1.5  ← Session 25 (Type filter fix)
    decor/test/fixtures/computers.yml                                       v1.8  ← Session 25 (peripheral fixture)
    decor/test/controllers/owners_controller_test.rb                        v1.4  ← Session 25 (peripherals smoke test)
    decor/docs/claude/SESSION_HANDOVER.md                                   v27.0 ← Session 25
    decor/docs/claude/DECOR_PROJECT.md                                      v2.20 ← Session 25
    decor/app/views/layouts/admin.html.erb                                  v1.7  ← Session 24
    decor/app/controllers/admin/data_transfers_controller.rb                v1.0  ← Session 24 (new)
    decor/app/views/admin/data_transfers/show.html.erb                      v1.0  ← Session 24 (new)
    decor/app/services/computer_model_export_service.rb                     v1.0  ← Session 24 (new)
    decor/app/services/computer_model_import_service.rb                     v1.0  ← Session 24 (new)
    decor/app/services/component_type_export_service.rb                     v1.0  ← Session 24 (new)
    decor/app/services/component_type_import_service.rb                     v1.0  ← Session 24 (new)
    decor/app/services/all_owners_export_service.rb                         v1.0  ← Session 24 (new)
    decor/test/controllers/admin/data_transfers_controller_test.rb          v1.0  ← Session 24 (new)
    decor/test/services/computer_model_export_service_test.rb               v1.0  ← Session 24 (new)
    decor/test/services/computer_model_import_service_test.rb               v1.1  ← Session 24 (new)
    decor/test/services/component_type_export_service_test.rb               v1.0  ← Session 24 (new)
    decor/test/services/component_type_import_service_test.rb               v1.0  ← Session 24 (new)
    decor/app/helpers/application_helper.rb                                 v1.2  ← Session 20
    decor/db/migrate/20260308100000_add_last_login_at_to_owners.rb          v1.0  ← Session 20 (new)
    decor/app/controllers/sessions_controller.rb                            v1.1  ← Session 20
    decor/app/views/admin/owners/index.html.erb                             v1.1  ← Session 20
    decor/test/controllers/sessions_controller_test.rb                      v1.0  ← Session 20 (new)
    decor/app/views/common/_navigation.html.erb                             v1.4  ← Session 20
    decor/app/models/site_text.rb                                           v1.1  ← Session 20
    decor/app/controllers/admin/site_texts_controller.rb                    v1.1  ← Session 20
    decor/app/views/admin/site_texts/new.html.erb                           v1.1  ← Session 20
    decor/app/views/admin/site_texts/delete_confirm.html.erb                v1.0  ← Session 20 (new)
    decor/app/models/owner.rb                                               v1.3  ← (password strength)
    decor/app/models/computer.rb                                            v1.6  ← Session 21
    decor/app/models/component.rb                                           v1.4  ← Session 21
    decor/app/services/owner_export_service.rb                              v1.1  ← Session 16
    decor/app/services/owner_import_service.rb                              v1.1  ← Session 16
    decor/test/fixtures/owners.yml                                          v2.1  ← Session 13


---

## Data Model Overview

### Owner
- has_many computers
- has_many components
- Visibility settings: real_name, email, country (public/members_only/private)
- Authentication via has_secure_password
- Validations:
  - user_name: required, unique, max 15 characters (VARCHAR(15) + CHECK in DB)
  - email: required, unique, valid format
  - country: ISO 3166 code (optional)
  - website: valid HTTP/HTTPS URL (optional)

### Computer
- belongs_to owner
- belongs_to computer_model
- belongs_to computer_condition (optional)
- belongs_to run_status (optional)
- has_many components, dependent: :destroy
- device_type enum: 0 = computer (default), 1 = appliance, 2 = peripheral
  prefix: true → device_type_computer?, device_type_appliance?, device_type_peripheral?
  CHECK(device_type IN (0,1,2)) constraint enforced at DB level (migration 20260316100000).
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted
  prefix: true → barter_status_no_barter?, barter_status_offered?, barter_status_wanted?
- Validations:
  - serial_number: required, VARCHAR(20) + CHECK in DB
  - order_number: max 20 characters, optional, VARCHAR(20) + CHECK in DB

### ComputerModel
- device_type enum: 0 = computer (default), 1 = appliance, 2 = peripheral
  Mirrors Computer#device_type. Used to scope model selects in forms and in
  the admin Computer/Appliance/Peripheral Models pages.
  Note: no CHECK constraint yet on computer_models.device_type — pending migration.
- has_many computers, dependent: :restrict_with_error
- Validations: name presence + uniqueness

### Component
- belongs_to owner
- belongs_to computer (optional)
- belongs_to component_type
- belongs_to component_condition (optional)
- component_category enum: 0 = integral (default), 1 = peripheral
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted
  prefix: true → barter_status_no_barter?, barter_status_offered?, barter_status_wanted?
- Fields: description (TEXT), serial_number VARCHAR(20), order_number VARCHAR(20)

### SiteText
- key VARCHAR(40) UNIQUE NOT NULL — internal identifier ("readme", "about", etc.)
- content TEXT NOT NULL — raw markdown uploaded by admin
- Managed via Admin → Texts dropdown; rendered as HTML on the public /readme route
- Extensible: additional text pages require only a new route + key mapping in the controllers

### ComputerCondition
- Table: computer_conditions
- has_many computers, dependent: :restrict_with_error
- Validations: name presence + uniqueness (case_sensitive: false)
- Managed via admin UI at /admin/conditions
- Examples: Completely original, Modified, Built from parts

### ComponentCondition
- Table: component_conditions
- Column: condition VARCHAR(40) UNIQUE NOT NULL (note: "condition", not "name")
- has_many components, dependent: :restrict_with_error
- Validations: condition presence + uniqueness (case_sensitive: false)
- Managed via admin UI at /admin/component_conditions
- Examples: Working, Defective

---

## Barter Status Feature (Sessions 21–22)

### Design
- `barter_status` integer column on both `computers` and `components` tables
- Enum: `{ no_barter: 0, offered: 1, wanted: 2 }`, prefix: true
- Default: 0 (no_barter) at DB level
- Auth rule: barter data visible to logged-in members ONLY
  - Index filter only applied when `logged_in?`
  - Non-logged-in visitors: no filter (all records visible), NO barter data shown anywhere
  - `<% if logged_in? %>` guards on every `<th>` and `<td>` in index tables and owners/show
  - `<% if logged_in? %>` guards on show page fields
  - No guard on forms (forms always require login)

### Index filter (both controllers)
Default when logged in: "0+1" (no_barter + offered). Wanted items hidden by default.
Filter options: No Trade + Offered / No Trade Only / Offered Only / Wanted Only.
Filter selector absent entirely for non-logged-in visitors.

### Colour coding (consistent across all views)
- offered   → `<span class="text-green-700">Offered</span>`
- wanted    → `<span class="text-amber-600">Wanted</span>`
- no_barter → `<span class="text-stone-400">—</span>`

### Column/field labels
- Index tables: "Barter" (column header)
- Filter sidebar: "Trade" (filter label)
- Show pages: "Trade Status" (field label)
- Form: "Trade Status" (field label)

---

## Route Notes

`resources :conditions` maps to `Admin::ConditionsController` which manages the
`computer_conditions` table (class `ComputerCondition`). The route resource name
was intentionally kept as `:conditions` to avoid a route rename ripple.

`resources :component_conditions` maps cleanly to `Admin::ComponentConditionsController`.

`resource :data_transfer, only: [:show]` with member routes `get :export` and
`post :import` — managed by `DataTransfersController` (Session 10).

`resources :appliances, controller: "computers", only: [:index],
defaults: { device_context: "appliance" }` — shares the computers controller.

`resources :peripherals, controller: "computers", only: [:index],
defaults: { device_context: "peripheral" }` — shares the computers controller.
Introduced Session 25. Individual record CRUD (show/edit/update/destroy) always
routes through computers_*.

`resources :peripheral_models, controller: "computer_models",
defaults: { device_context: "peripheral" }` under namespace :admin — shares
Admin::ComputerModelsController. Introduced Session 25.

`get "readme", to: "site_texts#show", defaults: { key: "readme" }` — public,
no login required.

---

## Work Completed - Sessions 1–24

(See SESSION_HANDOVER.md v26.0 for detail on Sessions 1–24)

---

## Work Completed - Session 25 (March 16, 2026)

### Feature: Peripherals — device_type: 2

#### Database + Model layer
    decor/db/migrate/20260316100000_add_device_type_check_to_computers.rb  v1.0 (new)
    decor/app/models/computer.rb                                            v1.7
    decor/app/models/computer_model.rb                                      v1.2

#### Routes + Controllers
    decor/config/routes.rb                                                  v2.2
    decor/app/controllers/owners_controller.rb                              v1.7
    decor/app/controllers/computers_controller.rb                           v1.16
    decor/app/controllers/admin/computer_models_controller.rb               v1.3

#### Views
    decor/app/views/owners/peripherals.html.erb                             v1.0 (new)
    decor/app/views/owners/computers.html.erb                               v1.1
    decor/app/views/owners/appliances.html.erb                              v1.1
    decor/app/views/owners/show.html.erb                                    v2.0
    decor/app/views/common/_navigation.html.erb                             v1.7
    decor/app/views/layouts/admin.html.erb                                  v1.8
    decor/app/views/computers/_filters.html.erb                             v1.5

#### Tests + Fixtures
    decor/test/fixtures/computers.yml                                       v1.8
    decor/test/controllers/owners_controller_test.rb                        v1.4

#### Bug fixes during session
- Empty Model select on peripheral new/edit form: ComputerModel enum was missing
  peripheral: 2 — added in computer_model.rb v1.2.
- Type filter visible on Peripherals index: `unless @device_context == "appliance"`
  changed to `if @device_context == "computer"` in _filters.html.erb v1.5.
- "My Peripherals" missing from owner nav dropdown — added in _navigation.html.erb v1.6/v1.7.

#### Still pending from Session 25
- `decor/app/views/owners/components.html.erb` — Peripherals tab not yet added
  (file was never uploaded). Needs v1.1 with four-tab strip.
- `decor/test/fixtures/computer_models.yml` — no peripheral model fixture yet.
  Needed before peripheral model export/import tests can be written.
- See SESSION_HANDOVER.md v27.0 for full test coverage notes.

---

## Pending — Next Session

- Commit Session 25 work
- Dependabot PRs — dedicated session
- Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
- System tests: decor/test/system/ still empty
- Account deletion + data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
- BulkUploadService stale model references (low priority)

---

## Current Deployment Status

**Production Version:** Fully up to date through Session 24.
**Session 25:** Ready to commit.

---

## Design Patterns

### Color Scheme — CONSISTENT ACROSS ALL PAGES
- **All clickable values:** `text-indigo-600 hover:text-indigo-900`
- **Action links (Edit):** `text-indigo-600 hover:text-indigo-900`
- **Destructive actions (Delete):** `text-red-600 hover:text-red-900`
- **Non-clickable data:** `text-stone-600`
- **Table headers:** `text-stone-500 uppercase`
- **Barter — offered:** `text-green-700`
- **Barter — wanted:** `text-amber-600`
- **Barter — no_barter:** `text-stone-400` (em-dash)

### Actions Column Pattern
- "View" links are NOT used — the clickable first-column value serves this purpose
- "Edit" shown only to the record's owner
- "Delete" shown only to the record's owner, always with turbo confirm dialog
- Edit and Delete are side by side (flex row) when both appear

### Button Labels
- **Primary action:** descriptive ("Update Computer", "Save Component", etc.)
- **Secondary / exit:** "Done" — never "Cancel" (avoids implying a revert)

### Show Page Layout Pattern (Components — established Session 9)
```
Container:   max-w-5xl mx-auto
Header:      flex justify-between — title+owner left, Edit/Delete right (owner only)
Fields:      <dl class="space-y-4 text-sm mb-6"> — NO outer wrapper div
Line 1:      grid grid-cols-3 gap-4
Line 2:      grid grid-cols-2 gap-4
Line 3:      full width — Description/History with min-height: 4.5rem
Field boxes: flex items-center w-full h-10 p-3 rounded border border-stone-300 bg-white text-sm
             (single-line fields)
             block w-full p-3 rounded border border-stone-300 bg-white text-sm whitespace-pre-wrap
             (multi-line fields — ERB tag MUST be on same line as opening tag)
Back button: Stimulus back_controller, history.back() + fallback URL
```

### Edit/New Form Pattern (Computers — Session 18)
```
Container:  max-w-5xl mx-auto
Form:       width: 80%
Line 1:     grid grid-cols-3 gap-4  (model, order_number, serial_number)
Line 2:     grid grid-cols-3 gap-4  (computer_condition, run_status, barter_status)
Line 3:     full width textarea      (history, 3 rows)
```

### Layout Pattern (Index pages — Computers/Appliances/Peripherals/Components/Owners)
```erb
<div class="px-4">
  <h1 class="text-2xl font-semibold mb-4 sticky top-0 bg-white z-10 py-2">Title</h1>
  <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
    <div class="sticky top-16 self-start"><%= render "filters" %></div>
    <div class="col-span-3 self-start">
      <div class="bg-white border border-stone-200 rounded overflow-auto"
           style="max-height: calc(100vh - 8rem);">
        <table class="min-w-full divide-y divide-stone-200">
          <thead class="bg-stone-50 sticky top-0 z-10">...</thead>
          <tbody id="items" class="bg-white divide-y divide-stone-200 text-sm">...</tbody>
        </table>
      </div>
    </div>
  </div>
</div>
```

### Component Table Column Order (established Session 19)
```
/components index:           Computer-Serial No. | Type | Description | Order No. | Serial No. | Owner | [Barter]
/owners/show components:     Computer-Serial No. | Type | Description | Order No. | Serial No. | [Barter]
/computers/edit components:  Type | Description | Order No. | Serial No. | Condition | Trade Status
/computers/show components:  Type | Order No. | Serial No. | Description
```
[Barter] column present only when `logged_in?`.

### device_context Pattern (Computers / Appliances / Peripherals shared views)
```
Routes:      resources :appliances,  controller: "computers", only: [:index],
               defaults: { device_context: "appliance" }
             resources :peripherals, controller: "computers", only: [:index],
               defaults: { device_context: "peripheral" }
             resources :computers, defaults: { device_context: "computer" }

Controller:  before_action :set_device_context — case/when on params[:device_context]:
             "appliance"  → @device_context="appliance",  @page_title="Appliances",
                            @index_path=appliances_path,  @turbo_tbody_id="appliances",
                            @load_more_id=:load_more_appliances
             "peripheral" → @device_context="peripheral", @page_title="Peripherals",
                            @index_path=peripherals_path, @turbo_tbody_id="peripherals",
                            @load_more_id=:load_more_peripherals
             else          → @device_context="computer",  @page_title="Computers",
                            @index_path=computers_path,   @turbo_tbody_id="computers",
                            @load_more_id=:load_more_computers

Index filter: appliance/peripheral routes lock device_type to their value.
              computers route defaults to "computer" when no param present.

Views:       all context-specific values come from instance variables.
             Type filter in _filters.html.erb only shown when
             @device_context == "computer" (the only page where it is meaningful).

Admin:       Admin::ComputerModelsController uses same case/when pattern in
             set_device_context for computer/appliance/peripheral model pages.
```

### Site Text Pattern (Read Me and future text pages)
```
Model:       SiteText — key VARCHAR(40), content TEXT
Route:       get "readme", to: "site_texts#show", defaults: { key: "readme" }
             admin: resources :site_texts, only: [:new, :create, :destroy], param: :key
Public ctrl: SiteTextsController#show — no login required
Admin ctrl:  Admin::SiteTextsController — new/create (upsert), destroy
Rendering:   render_markdown(content) helper — redcarpet gem
Empty state: displays "== Empty ==" when no record uploaded yet
```

### Table Styling
- Dividers: `divide-y divide-stone-200`
- Sticky headers: `sticky top-0 z-10`
- Hover: `hover:bg-stone-50`
- Cell padding: `px-4 py-3`

### Stimulus Back Controller
```
File:     decor/app/javascript/controllers/back_controller.js (v1.0)
Usage:    <a href="#"
             data-controller="back"
             data-back-fallback-url-value="<%= some_path %>"
             data-action="click->back#go"
             class="text-sm text-stone-700 hover:text-stone-900">← Back</a>
Logic:    history.back() if window.history.length > 1; else navigate to fallback URL
```

### source= Redirect Pattern (Destroy Actions)
- `source=owner`         → `owner_path(owner)` — used from owners/show
- `source=computer_show` → `computer_path(computer)` — used from computers/show
- `source=computer`      → `edit_computer_path(computer)` — used from computers/edit
- no source              → default index path

---

## Known Issues & Solutions

### SQLite ALTER TABLE Limitations
Cannot add named CHECK constraints to existing tables — requires full table
recreation. Use `disable_ddl_transaction!` + raw SQL in migrations.
See RAILS_SPECIFICS.md for full pattern.

### SQLite FK Enforcement
Must be explicitly enabled via `foreign_keys: true` in `decor/config/database.yml`.
Enabled as of Session 6 (February 24, 2026).

### SQLite VARCHAR Enforcement
VARCHAR(n) is cosmetic in SQLite — CHECK constraints required for actual enforcement.

### form_with Class Name / Route Name Mismatch
When a model class name does not match the Rails route resource name, use both
`url:` (fixes routing) and `scope:` (fixes param naming) on `form_with`.

### restrict_with_error — Destroy Failure Handling
`dependent: :restrict_with_error` causes `destroy` to return false (not raise)
when dependent records exist. Always check the return value and redirect with
`flash[:alert]` using `errors.full_messages.to_sentence`.

### ERB + whitespace-pre-wrap Renders Leading Whitespace Literally
Put the ERB tag on the same line as the opening tag.

### f.submit Label Does Not Respect Model Enum Values
Pass an explicit string label when device_type must be reflected:
`f.submit "#{computer.persisted? ? "Update" : "Create"} #{computer.device_type.capitalize}"`

### Squash Merge Git Divergence
Use `gh pr merge --merge` (not `--squash`).

### Multi-table ORDER BY Requires Arel.sql()
Rails raises `ActiveRecord::UnknownAttributeReference` for `.order()` strings
containing dots or SQL keywords. Wrap in `Arel.sql()`.

### build(device_type: nil) Overrides Enum Default
`Computer.build(device_type: nil)` explicitly sets device_type to nil, bypassing
the enum default. Fix: build without the key, then assign conditionally.

### ComputerModel.where(device_type:) requires matching enum values
If Computer and ComputerModel enums diverge, the model select on new/edit forms
returns empty results for the unrecognised device_type string. Both enums must
always be kept in sync. Introduced as a bug in Session 25 when peripheral: 2
was added to Computer but not ComputerModel; fixed in computer_model.rb v1.2.

### _filters.html.erb Type filter — show only on Computers page
The Type filter is only meaningful on /computers (where the user can switch
between Computer and Appliance types). On /appliances and /peripherals the
device_type is locked by the controller — the selector would have no effect.
Use `if @device_context == "computer"`, NOT `unless @device_context == "appliance"`.
The negative form breaks silently whenever a new locked-type context is added.

### New Gem Requires Server Restart
Adding a gem to Gemfile and running `bundle install` is not enough for a running
Rails server. The server process must be restarted to load the new gem.

### Fixture serial_number May Be Nil
Use a unique substring of `description` instead of `serial_number` in assertions.

---

## Future Considerations

### Legal/Compliance (Pending)
- Impressum (German law), Privacy Policy (GDPR), Cookie Consent, Terms of Service

### Technical Improvements (Optional)
- Dependabot PRs — dedicated session
- System tests: `decor/test/system/` still empty
- Account deletion (GDPR), data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
- CHECK(device_type IN (0,1,2)) constraint on computer_models table (pending migration)

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
