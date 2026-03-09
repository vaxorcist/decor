# decor/docs/claude/DECOR_PROJECT.md
# version 2.18
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
# Session 21+22: barter_status enum on computers and components (full feature).

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 9, 2026 (Session 22)
**Current Status:** Sessions 1–20 committed and deployed. Sessions 21–22 ready to commit (feature/session-21 branch).

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 22, March 9, 2026):
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
│   │   ├── bulk_upload_service.rb
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
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   ├── _owner.html.erb
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
│   │   └── 20260309100001_add_barter_status_to_components.rb
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

60 directories, 267 files
```

**Key file versions** (updated each session):

    decor/db/migrate/20260309100000_add_barter_status_to_computers.rb  v1.0  ← Session 21 (new)
    decor/db/migrate/20260309100001_add_barter_status_to_components.rb v1.0  ← Session 21 (new)
    decor/app/models/computer.rb                                        v1.6  ← Session 21 (barter_status enum)
    decor/app/models/component.rb                                       v1.4  ← Session 21 (barter_status enum)
    decor/app/controllers/computers_controller.rb                       v1.15 ← Session 21 (barter filter + strong params)
    decor/app/controllers/components_controller.rb                      v1.7  ← Session 21 (barter filter + strong params; component_category fix)
    decor/app/helpers/computers_helper.rb                               v1.5  ← Session 21 (barter filter options + helpers)
    decor/app/helpers/components_helper.rb                              v1.3  ← Session 21 (barter filter options + helpers)
    decor/test/fixtures/computers.yml                                   v1.7  ← Session 21 (barter_status on alice_vax, dec_unibus_router)
    decor/test/fixtures/components.yml                                  v1.4  ← Session 21 (barter_status on spare_disk, charlie_vt100_terminal)
    decor/app/views/computers/_form.html.erb                            v2.5  ← Session 21 (barter_status select; grid-cols-3 on line 2)
    decor/app/views/components/_form.html.erb                           v1.6  ← Session 21 (barter_status select; row 3 added)
    decor/app/views/components/_component.html.erb                      v1.6  ← Session 21 (Trade/Barter td added)
    decor/app/views/computers/_computer.html.erb                        v1.10 ← Session 22 (Type td removed; Barter td added)
    decor/app/views/computers/_filters.html.erb                         v1.4  ← Session 22 (Trade barter filter added)
    decor/app/views/components/_filters.html.erb                        v1.1  ← Session 22 (Trade barter filter added)
    decor/app/views/computers/show.html.erb                             v1.7  ← Session 22 (Trade Status field; dynamic grid-cols)
    decor/app/views/components/show.html.erb                            v1.7  ← Session 22 (Trade Status field)
    decor/app/views/owners/show.html.erb                                v1.8  ← Session 22 (Trade column in all 3 tables)
    decor/app/views/computers/index.html.erb                            v1.9  ← Session 22 (Type th removed; Barter th added)
    decor/app/views/components/index.html.erb                           v1.5  ← Session 22 (Barter th added)
    decor/test/models/computer_test.rb                                  v1.5  ← Session 22 (barter_status enum tests)
    decor/test/models/component_test.rb                                 v1.4  ← Session 22 (barter_status enum tests)
    decor/test/controllers/computers_controller_test.rb                 v1.6  ← Session 22 (barter filter tests)
    decor/test/controllers/components_controller_test.rb                v1.3  ← Session 22 (barter filter tests; nil serial fix)
    decor/docs/claude/SESSION_HANDOVER.md                               v23.0 ← Session 22
    decor/app/helpers/application_helper.rb                             v1.2  ← Session 20 (with_toc_data)
    decor/db/migrate/20260308100000_add_last_login_at_to_owners.rb      v1.0  ← Session 20 (new)
    decor/app/controllers/sessions_controller.rb                        v1.1  ← Session 20 (stamp last_login_at)
    decor/app/views/admin/owners/index.html.erb                         v1.1  ← Session 20 (Last Login column)
    decor/test/controllers/sessions_controller_test.rb                  v1.0  ← Session 20 (new)
    decor/config/routes.rb                                              v1.7  ← Session 20 (news/barter_trade/privacy/delete_confirm)
    decor/app/views/common/_navigation.html.erb                         v1.4  ← Session 20 (Info dropdown)
    decor/app/models/site_text.rb                                       v1.1  ← Session 20 (KNOWN_TEXTS constant)
    decor/app/controllers/admin/site_texts_controller.rb                v1.1  ← Session 20 (generalised; delete_confirm)
    decor/app/views/admin/site_texts/new.html.erb                       v1.1  ← Session 20 (key selector)
    decor/app/views/admin/site_texts/delete_confirm.html.erb            v1.0  ← Session 20 (new)
    decor/app/views/layouts/admin.html.erb                              v1.5  ← Session 20 (Texts dropdown: 2 items)
    decor/test/models/site_text_test.rb                                 v1.0  ← Session 20 (new)
    decor/test/controllers/admin/site_texts_controller_test.rb          v1.0  ← Session 20 (new)
    decor/docs/claude/COMMON_BEHAVIOR.md                                v2.4  ← Session 20 (prefix rule reinforced)
    decor/docs/claude/PROGRAMMING_GENERAL.md                            v1.9  ← Session 20 (test coverage check reinforced)
    decor/app/controllers/components_controller.rb                      v1.6  ← Session 19 (order_asc sort)
    decor/app/helpers/components_helper.rb                              v1.2  ← Session 19 (order_asc option)
    decor/app/views/components/index.html.erb                           v1.3  ← Session 19 (col reorder; Computer-Serial No.)
    decor/app/views/components/_component.html.erb                      v1.5  ← Session 19 (col reorder; Order No. + Serial No.)
    decor/app/models/owner.rb                                           v1.3  ← (password strength)
    decor/app/models/computer.rb                                        v1.5  ← Session 13
    decor/app/models/component.rb                                       v1.3  ← Session 13
    decor/app/services/owner_export_service.rb                          v1.1  ← Session 16
    decor/app/services/owner_import_service.rb                          v1.1  ← Session 16
    decor/test/fixtures/owners.yml                                      v2.1  ← Session 13
    decor/test/fixtures/computers.yml                                   v1.6  ← Session 13
    decor/test/fixtures/components.yml                                  v1.3  ← Session 13


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
- device_type enum: 0 = computer (default), 1 = appliance (placeholder name)
- barter_status enum: 0 = no_barter (default), 1 = offered, 2 = wanted
  prefix: true → barter_status_no_barter?, barter_status_offered?, barter_status_wanted?
- Validations:
  - serial_number: required, VARCHAR(20) + CHECK in DB
  - order_number: max 20 characters, optional, VARCHAR(20) + CHECK in DB

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
was intentionally kept as `:conditions` to avoid a route rename ripple. The
controller uses explicit `url:` and `scope: :condition` in its form partial to
bridge the class name / route name mismatch.

`resources :component_conditions` maps cleanly to `Admin::ComponentConditionsController`
(class `ComponentCondition`) — no url:/scope: workaround needed.

`resource :data_transfer, only: [:show]` with member routes `get :export` and
`post :import` — managed by `DataTransfersController` (Session 10).

`resources :appliances, controller: "computers", only: [:index],
defaults: { device_context: "appliance" }` — shares the computers controller.
The `device_context` default param is read by `set_device_context` before_action,
which locks device_type to "appliance" and sets all context instance variables
(@page_title, @index_path, @turbo_tbody_id, @load_more_id) for the shared views.
Individual record CRUD (show/edit/update/destroy) always routes through computers_*.

`get "readme", to: "site_texts#show", defaults: { key: "readme" }` — public,
no login required. Additional text pages follow the same pattern with a different key.
`resources :site_texts, only: [:new, :create, :destroy], param: :key` under the
admin namespace — managed by Admin::SiteTextsController.

---

## Work Completed - Sessions 1–8

(See SESSION_HANDOVER.md v9.1 for detail on Sessions 1–8)

Key milestones:
- Session 1: Index table layouts, search, serial number required
- Session 2: Rubocop fixes, owners page redesign
- Session 3: Password change functionality
- Session 4: Password strength validation, computers/components UI improvements
- Session 5: Embedded component sub-form on computer edit page
- Session 6: SQLite FK enforcement enabled, gem security updates, docs/claude/ directory
- Session 7: component_conditions table; conditions→computer_conditions rename; type cleanup
- Session 8: Admin UI for component_conditions; Computer Conditions rename in UI;
  model validations; brakeman 8.0.3; owners/show + components/show layout (Steps 1–2)

---

## Work Completed - Session 9 (February 27, 2026)

### 1. Rule Set — RAILS_SPECIFICS.md v1.6
### 2. components/show.html.erb — Step 3 completed (v1.5)
### 3. Stimulus Back Controller — back_controller.js (v1.0)
### 4. Component Edit Page — edit.html.erb (v1.1), _form.html.erb (v1.3)

---

## Work Completed - Session 10 (February 28, 2026)

### 1. Data Transfer Feature
    decor/app/controllers/data_transfers_controller.rb     (v1.0)
    decor/app/services/owner_export_service.rb
    decor/app/services/owner_import_service.rb

### 2. Tests
    decor/test/controllers/data_transfers_controller_test.rb
    decor/test/services/owner_export_service_test.rb
    decor/test/services/owner_import_service_test.rb

### 3. Rule Set Updates — COMMON_BEHAVIOR.md v1.8, PROGRAMMING_GENERAL.md v1.7

---

## Work Completed - Session 11 (March 1, 2026)

### 1. owners/show — Computers and Components tables
    decor/app/views/owners/show.html.erb        (v1.4)
    decor/app/controllers/owners_controller.rb  (v1.4)

### 2. source=owner Redirect Pattern
    decor/app/controllers/computers_controller.rb   (v1.6)
    decor/app/controllers/components_controller.rb  (v1.4)

### 3. Tests — owners_controller_test.rb (v1.3)

---

## Work Completed - Session 12 (March 1, 2026)

### 1. Destroy-redirect tests
    decor/test/controllers/computers_controller_test.rb    (v1.0)
    decor/test/controllers/components_controller_test.rb   (v1.0)

### 2. Computer cascade delete (Rails layer)
    decor/app/models/computer.rb    (v1.4)
    decor/test/models/computer_test.rb    (v1.3)

### 3. computers/show layout + source=computer_show
    decor/app/views/computers/show.html.erb         (v1.5)
    decor/app/controllers/components_controller.rb  (v1.5)
    decor/test/controllers/components_controller_test.rb  (v1.1)

---

## Work Completed - Session 16 (March 4, 2026)

### 1. device_type in Export / Import
    decor/app/services/owner_export_service.rb            (v1.1)
    decor/app/services/owner_import_service.rb            (v1.1)
    decor/app/views/data_transfers/show.html.erb          (v1.5)
    decor/test/services/owner_export_service_test.rb      (v1.1)
    decor/test/services/owner_import_service_test.rb      (v1.1)

### 2. Owners Index — Filter Width and Appliances Column
    decor/app/views/owners/index.html.erb        (v3.3)
    decor/app/views/owners/_owner.html.erb       (v3.3)

### 3. Rule Document Updates
    decor/docs/claude/COMMON_BEHAVIOR.md              (v2.2)
    decor-session-rules skill                         (v1.1)

---

## Work Completed - Session 17 (March 5, 2026)

### 1. device_type Filtering on Computers Index
    decor/app/helpers/computers_helper.rb                    (v1.2)
    decor/app/views/computers/_filters.html.erb              (v1.3)
    decor/app/controllers/computers_controller.rb            (v1.9)

### 2. Appliances Page
    decor/config/routes.rb                                   (v1.4)
    decor/app/views/computers/index.html.erb                 (v1.7)
    decor/app/views/computers/_computer.html.erb             (v1.8)
    decor/app/views/computers/index.turbo_stream.erb         (v1.1)
    decor/app/views/common/_navigation.html.erb              (v1.2)
    decor/app/views/owners/_owner.html.erb                   (v3.4)
    decor/test/controllers/computers_controller_test.rb      (v1.3)

### 3. Edit / Show Pages — device_type-Aware Labels
    decor/app/views/computers/edit.html.erb                  (v1.3)
    decor/app/views/computers/_form.html.erb                 (v2.0)
    decor/app/views/computers/show.html.erb                  (v1.6)

---

## Work Completed - Session 18 (March 6, 2026)

### 1. device_type Selector on New/Edit Form
    decor/app/views/computers/_form.html.erb                 (v2.2)
    decor/app/helpers/computers_helper.rb                    (v1.3)
    decor/app/controllers/computers_controller.rb            (v1.13)
    decor/app/views/computers/new.html.erb                   (v1.4)
    decor/test/controllers/computers_controller_test.rb      (v1.5)

### 2. Owner Show Page — Separate Appliances Table
    decor/app/controllers/owners_controller.rb               (v1.5)
    decor/app/views/owners/show.html.erb                     (v1.6)

### 3. Read Me Page + Site Texts Infrastructure
    decor/Gemfile                                            (redcarpet added)
    decor/db/migrate/20260306100000_create_site_texts.rb     (v1.0)
    decor/app/models/site_text.rb                            (v1.0)
    decor/app/helpers/application_helper.rb                  (v1.1)
    decor/config/routes.rb                                   (v1.5)
    decor/app/controllers/site_texts_controller.rb           (v1.0)
    decor/app/controllers/admin/site_texts_controller.rb     (v1.0)
    decor/app/views/site_texts/show.html.erb                 (v1.0)
    decor/app/views/admin/site_texts/new.html.erb            (v1.0)
    decor/app/views/common/_navigation.html.erb              (v1.3)
    decor/app/views/layouts/admin.html.erb                   (v1.4)

---

## Work Completed - Session 19 (March 7, 2026)

### 1. Component Table Column Reorder + Order No. Added
    decor/app/views/components/index.html.erb                (v1.3)
    decor/app/views/components/_component.html.erb           (v1.5)
    decor/app/views/owners/show.html.erb                     (v1.7)
    decor/app/views/computers/_form.html.erb                 (v2.3)

### 2. "By Order No." Sort on /components
    decor/app/helpers/components_helper.rb                   (v1.2)
    decor/app/controllers/components_controller.rb           (v1.6)

---

## Work Completed - Session 20 (March 8, 2026)

### 1. In-page anchor links for markdown pages
    decor/app/helpers/application_helper.rb                         (v1.1 → v1.2)

### 2. Remove device_type selector from edit form
    decor/app/views/computers/_form.html.erb                        (v2.3 → v2.4)
    decor/app/controllers/computers_controller.rb                   (v1.13 → v1.14)
    decor/app/helpers/computers_helper.rb                           (v1.3 → v1.4)

### 3. Last Login column on admin Manage Owners page
    decor/db/migrate/20260308100000_add_last_login_at_to_owners.rb  (v1.0 — new)
    decor/app/controllers/sessions_controller.rb                    (v1.0 → v1.1)
    decor/app/views/admin/owners/index.html.erb                     (v1.0 → v1.1)
    decor/test/controllers/sessions_controller_test.rb              (v1.0 — new)

### 4. Info dropdown in public navigation
    decor/config/routes.rb                                          (v1.5 → v1.6)
    decor/app/views/common/_navigation.html.erb                     (v1.3 → v1.4)

### 5. Generalised text upload/delete pages
    decor/app/models/site_text.rb                                   (v1.0 → v1.1)
    decor/app/controllers/admin/site_texts_controller.rb            (v1.0 → v1.1)
    decor/app/views/admin/site_texts/new.html.erb                   (v1.0 → v1.1)
    decor/app/views/admin/site_texts/delete_confirm.html.erb        (v1.0 — new)
    decor/config/routes.rb                                          (v1.6 → v1.7)
    decor/app/views/layouts/admin.html.erb                          (v1.4 → v1.5)
    decor/test/models/site_text_test.rb                             (v1.0 — new)
    decor/test/controllers/admin/site_texts_controller_test.rb      (v1.0 — new)

### 6. Rule document updates
    decor/docs/claude/COMMON_BEHAVIOR.md                            (v2.3 → v2.4)
    decor/docs/claude/PROGRAMMING_GENERAL.md                        (v1.8 → v1.9)

---

## Work Completed - Sessions 21–22 (March 9, 2026)

### Feature: barter_status on computers and components (full)

#### Back-end layer (Session 21)
    decor/db/migrate/20260309100000_add_barter_status_to_computers.rb   (v1.0 — new)
    decor/db/migrate/20260309100001_add_barter_status_to_components.rb  (v1.0 — new)
    decor/app/models/computer.rb                                         (v1.5 → v1.6)
    decor/app/models/component.rb                                        (v1.3 → v1.4)
    decor/app/controllers/computers_controller.rb                        (v1.14 → v1.15)
    decor/app/controllers/components_controller.rb                       (v1.6 → v1.7)
    decor/app/helpers/computers_helper.rb                                (v1.4 → v1.5)
    decor/app/helpers/components_helper.rb                               (v1.2 → v1.3)
    decor/test/fixtures/computers.yml                                    (v1.6 → v1.7)
    decor/test/fixtures/components.yml                                   (v1.3 → v1.4)
    decor/app/views/computers/_form.html.erb                             (v2.4 → v2.5)
    decor/app/views/components/_form.html.erb                            (v1.5 → v1.6)
    decor/app/views/components/_component.html.erb                       (v1.5 → v1.6)

Notable fix in components_controller.rb v1.7: `:component_category` was missing
from `component_params` in v1.6 and was silently dropped on form submit.

#### View layer (Session 22)
    decor/app/views/computers/_filters.html.erb                          (v1.3 → v1.4)
    decor/app/views/components/_filters.html.erb                         (v1.0 → v1.1)
    decor/app/views/computers/show.html.erb                              (v1.6 → v1.7)
    decor/app/views/components/show.html.erb                             (v1.6 → v1.7)
    decor/app/views/owners/show.html.erb                                 (v1.7 → v1.8)
    decor/app/views/computers/index.html.erb                             (v1.7 → v1.9)
    decor/app/views/computers/_computer.html.erb                         (v1.8 → v1.10)

Notable changes in index/partial:
  - Type column removed from /computers index (redundant — route already scopes type)
  - Column header label: "Barter" (index tables); "Trade" (filter sidebar, show pages)

#### Tests (Session 22)
    decor/test/models/computer_test.rb                                   (v1.4 → v1.5)
    decor/test/models/component_test.rb                                  (v1.3 → v1.4)
    decor/test/controllers/computers_controller_test.rb                  (v1.5 → v1.6)
    decor/test/controllers/components_controller_test.rb                 (v1.1 → v1.3)

Note on components_controller_test: v1.2 used component.serial_number (nil in all
fixtures) causing TypeError. Fixed in v1.3 by switching to unique description
substrings ("256KB", "RL02", "VT100").

---

## Pending — Next Session

- Commit feature/session-21 branch (covers all Sessions 21+22 work)
- Dependabot PRs — dedicated session
- Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
- System tests: decor/test/system/ still empty
- Account deletion + data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
- BulkUploadService stale model references (low priority)

---

## Current Deployment Status

**Production Version:** Fully up to date through Session 20.
**Sessions 21–22:** Ready to commit (feature/session-21 branch, not yet created).

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

### Layout Pattern (Index pages — Computers/Appliances/Components/Owners)
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

### device_context Pattern (Computers / Appliances shared views)
```
Route:       resources :appliances, controller: "computers", only: [:index],
               defaults: { device_context: "appliance" }
             resources :computers, defaults: { device_context: "computer" }

Controller:  before_action :set_device_context sets:
               @device_context  — "computer" or "appliance"
               @page_title      — "Computers" or "Appliances"
               @index_path      — computers_path or appliances_path
               @turbo_tbody_id  — "computers" or "appliances"
               @load_more_id    — :load_more_computers or :load_more_appliances

Index filter: appliances route locks device_type to "appliance"
              computers route defaults to "computer" when no param present

Views:       all context-specific values come from instance variables
             Type column removed — route already scopes the type
```

### Site Text Pattern (Read Me and future text pages)
```
Model:       SiteText — key VARCHAR(40), content TEXT
Route:       get "readme", to: "site_texts#show", defaults: { key: "readme" }
             admin: resources :site_texts, only: [:new, :create, :destroy], param: :key
Public ctrl: SiteTextsController#show — no login required
Admin ctrl:  Admin::SiteTextsController — new/create (upsert), destroy
Rendering:   render_markdown(content) helper — redcarpet gem
             Markdown links work: [text](/path) internal, [text](https://...) external
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
See RAILS_SPECIFICS.md and PROGRAMMING_GENERAL.md for rules.

### form_with Class Name / Route Name Mismatch
When a model class name does not match the Rails route resource name, use both
`url:` (fixes routing) and `scope:` (fixes param naming) on `form_with`.

### restrict_with_error — Destroy Failure Handling
`dependent: :restrict_with_error` causes `destroy` to return false (not raise)
when dependent records exist. Always check the return value and redirect with
`flash[:alert]` using `errors.full_messages.to_sentence`.

### ERB + whitespace-pre-wrap Renders Leading Whitespace Literally
Put the ERB tag on the same line as the opening tag.
See RAILS_SPECIFICS.md.

### f.submit Label Does Not Respect Model Enum Values
Rails generates "Create/Update [ModelClass]" regardless of enum values.
Pass an explicit string label when device_type must be reflected:
`f.submit "#{computer.persisted? ? "Update" : "Create"} #{computer.device_type.capitalize}"`

### Squash Merge Git Divergence
Use `gh pr merge --merge` (not `--squash`).

### Multi-table ORDER BY Requires Arel.sql()
Rails raises `ActiveRecord::UnknownAttributeReference` for `.order()` strings
containing dots or SQL keywords. Wrap in `Arel.sql()`.
See RAILS_SPECIFICS.md.

### build(device_type: nil) Overrides Enum Default
`Computer.build(device_type: nil)` explicitly sets device_type to nil, bypassing
the enum default (computer: 0). Calling `.capitalize` on nil then raises NoMethodError.
Fix: build without the key, then assign conditionally:
  @computer = Current.owner.computers.build
  @computer.device_type = params[:device_type] if params[:device_type].present?

### New Gem Requires Server Restart
Adding a gem to Gemfile and running `bundle install` is not enough for a running
Rails server. The server process must be restarted to load the new gem.

### Fixture serial_number May Be Nil
Component fixtures do not all have serial_number set. Using `component.serial_number`
in `assert_includes response.body, ...` raises TypeError when the value is nil.
Use a unique substring of `description` instead (e.g. "256KB", "RL02", "VT100").

---

## Future Considerations

### Legal/Compliance (Pending)
- Impressum (German law), Privacy Policy (GDPR), Cookie Consent, Terms of Service

### Technical Improvements (Optional)
- Dependabot PRs — dedicated session
- System tests: `decor/test/system/` still empty
- Account deletion (GDPR), data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
- Image upload (if added: AWS Rekognition for moderation)
- Migrate SQLite → PostgreSQL (better constraint support)

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
