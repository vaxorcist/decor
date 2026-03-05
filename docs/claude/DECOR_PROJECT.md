# decor/docs/claude/DECOR_PROJECT.md
# version 2.12
# Session 13: device_type on computers, component_category on components; enum tests.
# Session 14: DRY Computer/Appliance Models admin pages; dropdown nav (admin.html.erb v1.3);
#   device_type on computer_models; routes :appliance_models; dropdown_controller.js.
# Session 16: device_type in export/import — "appliance" as third record_type value.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** March 4, 2026 (Session 16: device_type in export/import; "appliance" record_type)
**Current Status:** Session 13 committed; Session 14 in progress

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 14, March 3, 2026):
```
decor//
├── app/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── base_controller.rb
│   │   │   ├── bulk_uploads_controller.rb
│   │   │   ├── component_conditions_controller.rb
│   │   │   ├── component_types_controller.rb
│   │   │   ├── computer_models_controller.rb
│   │   │   ├── conditions_controller.rb
│   │   │   ├── invites_controller.rb
│   │   │   ├── owners_controller.rb
│   │   │   └── run_statuses_controller.rb
│   │   ├── concerns/
│   │   │   ├── authentication.rb
│   │   │   └── pagination.rb
│   │   ├── application_controller.rb
│   │   ├── components_controller.rb
│   │   ├── computers_controller.rb
│   │   ├── data_transfers_controller.rb
│   │   ├── home_controller.rb
│   │   ├── owners_controller.rb
│   │   ├── password_resets_controller.rb
│   │   └── sessions_controller.rb
│   ├── helpers/
│   │   ├── application_helper.rb
│   │   ├── components_helper.rb
│   │   ├── computers_helper.rb
│   │   ├── navigation_helper.rb
│   │   ├── owners_helper.rb
│   │   └── style_helper.rb
│   ├── javascript/
│   │   ├── controllers/
│   │   │   ├── application.js
│   │   │   ├── back_controller.js
│   │   │   ├── computer_select_controller.js
│   │   │   ├── hello_controller.js
│   │   │   ├── index.js
│   │   │   ├── load_more_controller.js
│   │   │   └── password_generator_controller.js
│   │   └── application.js
│   ├── jobs/
│   │   ├── application_job.rb
│   │   └── invite_reminder_job.rb
│   ├── mailers/
│   │   ├── application_mailer.rb
│   │   ├── invite_mailer.rb
│   │   └── password_reset_mailer.rb
│   ├── models/
│   │   ├── decor/
│   │   │   └── routes.rb
│   │   ├── application_record.rb
│   │   ├── component_condition.rb
│   │   ├── component.rb
│   │   ├── component_type.rb
│   │   ├── computer_condition.rb
│   │   ├── computer_model.rb
│   │   ├── computer.rb
│   │   ├── current.rb
│   │   ├── invite.rb
│   │   ├── owner.rb
│   │   └── run_status.rb
│   ├── services/
│   │   ├── bulk_upload_service.rb
│   │   ├── owner_export_service.rb
│   │   └── owner_import_service.rb
│   └── views/
│       ├── admin/
│       │   ├── bulk_uploads/
│       │   │   └── new.html.erb
│       │   ├── component_conditions/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── component_types/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── computer_models/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── conditions/
│       │   │   ├── edit.html.erb
│       │   │   ├── _form.html.erb
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── invites/
│       │   │   ├── index.html.erb
│       │   │   └── new.html.erb
│       │   ├── owners/
│       │   │   ├── edit.html.erb
│       │   │   └── index.html.erb
│       │   └── run_statuses/
│       │       ├── edit.html.erb
│       │       ├── _form.html.erb
│       │       ├── index.html.erb
│       │       └── new.html.erb
│       ├── common/
│       │   ├── _flashes.html.erb
│       │   ├── _footer.html.erb
│       │   ├── _navigation.html.erb
│       │   └── _record_errors.html.erb
│       ├── components/
│       │   ├── _component.html.erb
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── computers/
│       │   ├── _computer_component_form.html.erb
│       │   ├── _computer.html.erb
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── data_transfers/
│       │   └── show.html.erb
│       ├── home/
│       │   └── index.html.erb
│       ├── layouts/
│       │   ├── admin.html.erb
│       │   ├── application.html.erb
│       │   ├── mailer.html.erb
│       │   └── mailer.text.erb
│       ├── mailers/
│       │   ├── invite_mailer/
│       │   │   ├── invite_email.html.erb
│       │   │   ├── invite_email.text.erb
│       │   │   ├── reminder_email.html.erb
│       │   │   └── reminder_email.text.erb
│       │   └── password_reset_mailer/
│       │       ├── invite_email.html.erb
│       │       └── reset_email.html.erb
│       ├── owners/
│       │   ├── edit.html.erb
│       │   ├── _filters.html.erb
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── new.html.erb
│       │   ├── _owner.html.erb
│       │   └── show.html.erb
│       ├── password_resets/
│       │   ├── edit.html.erb
│       │   └── new.html.erb
│       ├── pwa/
│       │   ├── manifest.json.erb
│       │   └── service-worker.js
│       ├── sessions/
│       │   └── new.html.erb
│       └── shared/
│           └── _load_more.html.erb
├── bin/
│   ├── brakeman*
│   ├── bundler-audit*
│   ├── ci*
│   ├── dev*
│   ├── docker-entrypoint*
│   ├── importmap*
│   ├── jobs*
│   ├── kamal*
│   ├── rails*
│   ├── rake*
│   ├── rubocop*
│   ├── setup*
│   └── thrust*
├── config/
│   ├── environments/
│   │   ├── development.rb
│   │   ├── production.rb
│   │   └── test.rb
│   ├── initializers/
│   │   ├── assets.rb
│   │   ├── content_security_policy.rb
│   │   ├── filter_parameter_logging.rb
│   │   ├── inflections.rb
│   │   └── require_csv.rb
│   ├── locales/
│   │   └── en.yml
│   ├── application.rb
│   ├── boot.rb
│   ├── brakeman.ignore
│   ├── bundler-audit.yml
│   ├── cable.yml
│   ├── cache.yml
│   ├── ci.rb
│   ├── credentials.yml.enc
│   ├── database.yml
│   ├── deploy.yml
│   ├── environment.rb
│   ├── importmap.rb
│   ├── master.key
│   ├── puma.rb
│   ├── queue.yml
│   ├── recurring.yml
│   ├── routes.rb
│   ├── secrets.yml
│   └── storage.yml
├── db/
│   ├── migrate/
│   │   ├── 20251223133731_create_owners.rb
│   │   ├── 20251223140358_create_computer_models.rb
│   │   ├── 20251223140432_create_computers.rb
│   │   ├── 20251223140517_create_component_types.rb
│   │   ├── 20251223140542_create_components.rb
│   │   ├── 20251223144611_add_password_reset_to_owners.rb
│   │   ├── 20251223145711_add_admin_to_owners.rb
│   │   ├── 20251223173121_create_invites.rb
│   │   ├── 20251229120631_create_conditions.rb
│   │   ├── 20251229120632_create_run_statuses.rb
│   │   ├── 20251229120709_migrate_computer_conditions_and_run_statuses.rb
│   │   ├── 20251231133644_add_history_and_condition_to_components.rb
│   │   ├── 20251231133716_make_condition_and_run_status_optional_in_computers.rb
│   │   ├── 20260212135907_make_serial_number_required.rb
│   │   ├── 20260220093615_rename_description_to_order_number_on_computers.rb
│   │   ├── 20260220140000_add_reminder_sent_at_to_invites.rb
│   │   ├── 20260225120000_component_conditions_and_type_cleanup.rb
│   │   ├── 20260303100000_add_device_type_to_computers.rb
│   │   └── 20260303100001_add_component_category_to_components.rb
│   ├── cable_schema.rb
│   ├── cache_schema.rb
│   ├── queue_schema.rb
│   ├── schema.rb
│   └── seeds.rb
├── docs/
│   └── claude/
│       ├── COMMON_BEHAVIOR.md
│       ├── DECOR_PROJECT.md
│       ├── PROGRAMMING_GENERAL.md
│       ├── RAILS_SPECIFICS.md
│       └── SESSION_HANDOVER.md
├── public/
│   ├── 400.html
│   ├── 404.html
│   ├── 406-unsupported-browser.html
│   ├── 422.html
│   ├── 500.html
│   ├── icon.png
│   ├── icon.svg
│   └── robots.txt
├── script/
│   └── generate_fixture_passwords.rb
├── test/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── admin_owners_controller_test.rb
│   │   │   ├── component_conditions_controller_test.rb
│   │   │   ├── component_types_controller_test.rb
│   │   │   ├── computer_models_controller_test.rb
│   │   │   ├── conditions_controller_test.rb
│   │   │   ├── invites_controller_test.rb
│   │   │   └── run_statuses_controller_test.rb
│   │   ├── components_controller_test.rb
│   │   ├── computers_controller_test.rb
│   │   ├── data_transfers_controller_test.rb
│   │   ├── owners_controller_destroy_test.rb
│   │   ├── owners_controller_password_test.rb
│   │   ├── owners_controller_test.rb
│   │   └── password_resets_controller_test.rb
│   ├── fixtures/
│   │   ├── component_conditions.yml
│   │   ├── components.yml
│   │   ├── component_types.yml
│   │   ├── computer_conditions.yml
│   │   ├── computer_models.yml
│   │   ├── computers.yml
│   │   ├── invites.yml
│   │   ├── owners.yml
│   │   └── run_statuses.yml
│   ├── jobs/
│   │   └── invite_reminder_job_test.rb
│   ├── mailers/
│   │   ├── previews/
│   │   │   └── invite_mailer_preview.rb
│   │   ├── invite_mailer_test.rb
│   │   └── password_reset_mailer_test.rb
│   ├── models/
│   │   ├── component_test.rb
│   │   ├── component_type_test.rb
│   │   ├── computer_condition_test.rb
│   │   ├── computer_model_test.rb
│   │   ├── computer_test.rb
│   │   ├── invite_test.rb
│   │   ├── owner_test.rb
│   │   └── run_status_test.rb
│   ├── services/
│   │   ├── owner_export_service_test.rb
│   │   └── owner_import_service_test.rb
│   ├── support/
│   │   └── authentication_helper.rb
│   ├── application_system_test_case.rb
│   └── test_helper.rb
├── config.ru
├── Dockerfile
├── Gemfile
├── Procfile.dev
├── Rakefile
├── README.md
└── rich.html

58 directories, 251 files
```

**Key file versions** (updated each session):

    decor/app/controllers/admin/computer_models_controller.rb   v1.1  ← Session 14 (DRY)
    decor/app/models/computer_model.rb                          v1.1  ← Session 14 (device_type enum)
    decor/app/models/computer.rb                                v1.5  ← Session 13
    decor/app/models/component.rb                               v1.3  ← Session 13
    decor/app/services/owner_export_service.rb                  v1.1  ← Session 16 (appliance record_type)
    decor/app/services/owner_import_service.rb                  v1.1  ← Session 16 (appliance record_type)
    decor/app/views/admin/computer_models/index.html.erb        v1.1  ← Session 14
    decor/app/views/admin/computer_models/new.html.erb          v1.1  ← Session 14
    decor/app/views/admin/computer_models/edit.html.erb         v1.1  ← Session 14
    decor/app/views/admin/computer_models/_form.html.erb        v1.1  ← Session 14
    decor/app/views/data_transfers/show.html.erb                v1.5  ← Session 16 (appliance record_type)
    decor/app/views/layouts/admin.html.erb                      v1.3  ← Session 14 (Appliances link active)
    decor/app/javascript/controllers/dropdown_controller.js     v1.0  ← Session 14 (new)
    decor/config/routes.rb                                      v1.3  ← Session 14 (:appliance_models)
    decor/db/migrate/20260303110000_add_device_type_to_computer_models.rb  v1.0  ← Session 14 (new)
    decor/db/migrate/20260304120000_add_cascade_delete_components_computer.rb  v1.1  ← Session 15 (new)
    decor/app/controllers/computers_controller.rb               v1.6  ← Session 11
    decor/app/controllers/components_controller.rb              v1.5  ← Session 12
    decor/app/controllers/owners_controller.rb                  v1.4  ← Session 11
    decor/app/controllers/data_transfers_controller.rb          v1.1  ← Session 10
    decor/app/views/owners/show.html.erb                        v1.4  ← Session 11
    decor/app/views/computers/show.html.erb                     v1.5  ← Session 12
    decor/test/models/computer_test.rb                          v1.4  ← Session 13
    decor/test/models/component_test.rb                         v1.3  ← Session 13
    decor/test/controllers/computers_controller_test.rb         v1.0  ← Session 12
    decor/test/controllers/components_controller_test.rb        v1.1  ← Session 12
    decor/test/controllers/owners_controller_test.rb            v1.3  ← Session 11
    decor/test/services/owner_export_service_test.rb            v1.1  ← Session 16 (appliance tests)
    decor/test/services/owner_import_service_test.rb            v1.1  ← Session 16 (appliance tests)
    decor/test/fixtures/owners.yml                              v2.1  ← Session 13
    decor/test/fixtures/computers.yml                           v1.6  ← Session 13
    decor/test/fixtures/components.yml                          v1.3  ← Session 13


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
- has_many components, dependent: :nullify
- Validations:
  - serial_number: required, VARCHAR(20) + CHECK in DB
  - order_number: max 20 characters, optional, VARCHAR(20) + CHECK in DB

### Component
- belongs_to owner
- belongs_to computer (optional)
- belongs_to component_type
- belongs_to component_condition (optional)
- Fields: description (TEXT), serial_number VARCHAR(20), order_number VARCHAR(20)

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
Added "ERB + whitespace-pre-wrap — Literal Whitespace Gotcha".

### 2. components/show.html.erb — Step 3 completed

    decor/app/views/components/show.html.erb    (v1.5)

- Line 1: 3-col — Computer | Type | Condition
- Line 2: 2-col — Order Number | Serial Number
- Line 3: full — Description (whitespace-pre-wrap, min-height 4.5rem)

### 3. Stimulus Back Controller

    decor/app/javascript/controllers/back_controller.js    (v1.0)

Reusable controller: `history.back()` primary; falls back to
`data-back-fallback-url-value` when `history.length === 1`.

### 4. Component Edit Page — aligned with show layout

    decor/app/views/components/edit.html.erb      (v1.1)
    decor/app/views/components/_form.html.erb     (v1.3)

- edit.html.erb: max-w-2xl → max-w-5xl; Stimulus Back button added
- _form.html.erb: fields reordered; "Cancel" → "Done"

---

## Work Completed - Session 10 (February 28, 2026)

### 1. Data Transfer Feature

    decor/app/controllers/data_transfers_controller.rb     (v1.0)
    decor/app/services/owner_export_service.rb
    decor/app/services/owner_import_service.rb

- `DataTransfersController`: show (landing page), export (CSV download),
  import (CSV upload). Protected by `require_login`.
- `OwnerExportService`: generates a CSV of the owner's computers and
  components. Handles FK references (model name, condition, run status,
  component type) and spare components (no computer attached).
- `OwnerImportService`: two-pass import (computers first, then components).
  Matches existing records by serial number; creates new records otherwise.
  Atomic — wraps entire import in a transaction; rolls back on any error.

### 2. Tests

    decor/test/controllers/data_transfers_controller_test.rb
    decor/test/services/owner_export_service_test.rb
    decor/test/services/owner_import_service_test.rb

Coverage: show/export/import actions (auth guard, happy path, error paths);
export CSV headers, row content, FK references, spare handling;
import two-pass logic, duplicates, atomicity.

### 3. Rule Set Updates

    decor/docs/claude/COMMON_BEHAVIOR.md          v1.8
    decor/docs/claude/PROGRAMMING_GENERAL.md      v1.7

COMMON_BEHAVIOR v1.8: Token Usage Reporting section rewritten (UI is ground
truth; Claude estimates structurally unreliable); download file naming rule
(bare filename; `#` separator only when same filename appears twice).

PROGRAMMING_GENERAL v1.7: Mandatory end-of-task test coverage check added —
after every implementation Claude must explicitly ask whether tests are needed.

---

## Work Completed - Session 11 (March 1, 2026)

### 1. owners/show — Computers table

    decor/app/views/owners/show.html.erb        (v1.4)
    decor/app/controllers/owners_controller.rb  (v1.4)

- Computers ordered by model name ASC (`eager_load` + `Arel.sql`)
- Order Number column added between Model and Serial
- Delete button added next to Edit (owner only); `params: { source: "owner" }`

### 2. owners/show — Components table

    decor/app/views/owners/show.html.erb        (v1.4)  (same file)
    decor/app/controllers/owners_controller.rb  (v1.4)  (same file)

- Components ordered by computer model name / serial number / component type
  (`eager_load(:component_type, computer: :computer_model)` + `Arel.sql`
  with `NULLS LAST` so spares sort after computer-attached components)
- Column order: Computer | Type | Order No. | Serial No. | Description
- Computer cell: "Model – Serial" as link to computer, or "Spare" for unattached
- Order No. and Serial No. columns added (show "—" when blank)
- Delete button added next to Edit (owner only); `params: { source: "owner" }`

### 3. source=owner Redirect Pattern

    decor/app/controllers/computers_controller.rb   (v1.6)
    decor/app/controllers/components_controller.rb  (v1.4)

Both destroy actions now check `params[:source]`:
- `source=owner`    → redirect to `owner_path(owner)`
- `source=computer` → redirect to `edit_computer_path(computer)` (components only)
- default           → redirect to `computers_path` / `components_path`

Consistent with the pre-existing `source=computer` convention.

### 4. Tests

    decor/test/controllers/owners_controller_test.rb    (v1.3)

12 new tests: show page loads (owner/other/guest), computer ordering,
Order column, component ordering (NULLS LAST for spares), Computer column
labels, Order No./Serial No. headers, Edit+Delete visibility.

### 5. Rule Set Update

    decor/docs/claude/RAILS_SPECIFICS.md    (v1.8)

Added: multi-table ORDER BY must be wrapped in `Arel.sql()`. Rails raises
`ActiveRecord::UnknownAttributeReference` for raw strings containing dots
or SQL keywords. Only wrap hardcoded developer strings — never user input.

---

## Work Completed - Session 12 (March 1, 2026)

### 1. Destroy-redirect tests — standalone test files created

    decor/test/controllers/computers_controller_test.rb    (v1.0)
    decor/test/controllers/components_controller_test.rb   (v1.0)

Pending additions files from Session 11 converted to proper standalone test
files (no pre-existing controller test files existed for these controllers).
Stale `_additions.rb` stub files deleted.

### 2. Computer cascade delete (Rails layer)

    decor/app/models/computer.rb    (v1.4)
    decor/test/models/computer_test.rb    (v1.3)

`has_many :components, dependent: :nullify` → `dependent: :destroy`.
Deleting a computer now cascades and destroys all its components at the
Rails layer. Database-level ON DELETE CASCADE to be added in a later migration.
New test: "destroying a computer destroys its components".

### 3. computers/show layout update

    decor/app/views/computers/show.html.erb    (v1.5)

- `max-w-5xl` → `max-w-7xl` (matches owners/show container width)
- Components table: Order No. and Serial No. columns added
- Components table: Delete button added next to Edit (owner/admin only)
- Components table column order: Type | Order No. | Serial No. | Description | Actions
- Delete uses `source=computer_show` → stays on computer show page after deletion

### 4. source=computer_show redirect

    decor/app/controllers/components_controller.rb    (v1.5)
    decor/test/controllers/components_controller_test.rb    (v1.1)

New `source=computer_show` branch in `destroy` redirects to `computer_path`
(show page) rather than `edit_computer_path`. Used when deleting from
`computers/show` so the user stays on the show page.
New test added; existing source tests retained as regression guards.

### 5. Rule set updates

    decor/docs/claude/COMMON_BEHAVIOR.md    (v1.9)
    decor/docs/claude/DECOR_PROJECT.md      (v2.10)

COMMON_BEHAVIOR v1.9: Upload file naming rule added — same-named files from
different directories must be uploaded in separate answers (one per message),
not together. The browser overwrites the first with the second silently.

---

## Work Completed - Session 16 (March 4, 2026)

### 1. device_type in Export / Import

    decor/app/services/owner_export_service.rb            (v1.1)
    decor/app/services/owner_import_service.rb            (v1.1)
    decor/app/views/data_transfers/show.html.erb          (v1.5)
    decor/test/services/owner_export_service_test.rb      (v1.1)
    decor/test/services/owner_import_service_test.rb      (v1.1)

`"appliance"` added as a third valid `record_type` value alongside `"computer"`
and `"component"`. No new CSV column — `record_type` encodes `device_type` directly:
`"computer"` → `device_type: 0`, `"appliance"` → `device_type: 1`.

Export: `device_type_appliance?` predicate selects the emitted string.
Import: `"appliance"` routes into the existing `computer_rows` bucket with a
`:appliance` tag; `process_computer_row` receives `device_type` as a third
argument and passes it to `build`.

UI (`show.html.erb`): `record_type` column description updated; example CSV
gains an appliance row.

### 2. Rule Document Updates

    decor/docs/claude/COMMON_BEHAVIOR.md              (v2.2)
    decor-session-rules skill                         (v1.1)

Two new rules added this session:
- "Skill and Rule Document Changes": must propose before modifying; present
  result as downloadable file; never modify silently.
- "Tool Availability — Never Infer, Always Test": run `echo "bash_tool OK"`
  as step 0 at every session start; never infer tool availability from
  environment context strings.

---

## Pending — Next Session

### Priority candidates
- BulkUploadService stale model references (low priority, carried over):
  `decor/app/services/bulk_upload_service.rb`
  - `Condition` → `ComputerCondition`
  - `computer.condition` → `computer.computer_condition`
  - `component.history` field does not exist on Component model
  - `component.condition` → `component.component_condition`
- Database-level ON DELETE CASCADE for computer → components
  (Rails-layer dependent: :destroy added Session 12; DB migration still needed)
- Dependabot PRs — dedicated session
- Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
- System tests: decor/test/system/ still empty
- Account deletion + data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)

---

## Current Deployment Status

**Production Version:** Fully up to date through Session 11
**Session 12:** Test + model + view + controller changes — deploy after full suite passes

---

## Design Patterns

### Color Scheme — CONSISTENT ACROSS ALL PAGES
- **All clickable values:** `text-indigo-600 hover:text-indigo-900`
- **Action links (Edit):** `text-indigo-600 hover:text-indigo-900`
- **Destructive actions (Delete):** `text-red-600 hover:text-red-900`
- **Non-clickable data:** `text-stone-600`
- **Table headers:** `text-stone-500 uppercase`

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

### Edit Form Pattern (Components — established Session 9)
```
Container:   max-w-5xl mx-auto
Form width:  full (no 80% constraint — matches show page width)
Row 1:       grid grid-cols-3 gap-4 (Computer | Type | Condition)
Row 2:       grid grid-cols-2 gap-4 (Order Number | Serial Number)
Row 3:       full width textarea with min-height: 4.5rem (Description/History)
Back button: Stimulus back_controller below the form
```

### Edit/New Form Pattern (Computers — unchanged)
```
Container:  max-w-5xl mx-auto
Form:       width: 80%
Line 1:     grid grid-cols-3 gap-4  (model, order_number, serial_number)
Line 2:     grid grid-cols-2 gap-4  (computer_condition, run_status)
Line 3:     full width textarea      (history, 3 rows)
```

### Layout Pattern (Index pages — Computers/Components/Owners)
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
When a record is deleted from a page other than its own index, a `source`
param controls where the user lands after deletion:

- `source=owner`         → `owner_path(owner)` — used from owners/show
- `source=computer_show` → `computer_path(computer)` — used from computers/show
- `source=computer`      → `edit_computer_path(computer)` — used from computers/edit
                           (components only)
- no source              → default index path (`computers_path` / `components_path`)

Implemented in: `computers_controller.rb` (v1.6), `components_controller.rb` (v1.5).
Owner/computer captured in a `before_action` before the record is destroyed.

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
Example: `ComputerCondition` model on `resources :conditions` route.

### restrict_with_error — Destroy Failure Handling
`dependent: :restrict_with_error` causes `destroy` to return false (not raise)
when dependent records exist. Always check the return value and redirect with
`flash[:alert]` using `errors.full_messages.to_sentence`.

### Missing Model Validations Cause Raw DB Exceptions
Without presence/uniqueness validations, blank or duplicate values raise
`SQLite3::ConstraintException` instead of clean validation errors. Always add
model-level validations alongside DB constraints (defense-in-depth).

### ERB + whitespace-pre-wrap Renders Leading Whitespace Literally
`whitespace-pre-wrap` preserves the newline + indentation between an opening
HTML tag and its `<%= %>` content tag, making text appear indented from the left.
`text-align: left` does not fix it. Fix: put the ERB tag on the same line as
the opening tag — `<dd class="whitespace-pre-wrap"><%= content %></dd>`.
See RAILS_SPECIFICS.md v1.8.

### Squash Merge Git Divergence
Use `gh pr merge --merge` (not `--squash`).
Recovery: `git fetch origin && git reset --hard origin/main`

### Turbo Stream Pagination Borders
Place `id="items"` on `<tbody>`, not outer div.

### Kamal Missing Secrets
Use `kamal app exec --reuse` (not `kamal app exec`).

### Nested Forms
Rails/HTML does not allow a form inside a form. Component sub-form on computer
edit page must be placed AFTER the computer `form_with` end tag.

### Multi-table ORDER BY Requires Arel.sql()
Rails raises `ActiveRecord::UnknownAttributeReference` for `.order()` strings
containing dots (`table.column`) or SQL keywords (`NULLS LAST`). Wrap in
`Arel.sql()`. Only use for hardcoded developer strings — never user input.
See RAILS_SPECIFICS.md v1.8.

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
- computers/show.html.erb redesign (deprioritised Session 11)

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
