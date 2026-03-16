# decor/docs/claude/SESSION_HANDOVER.md
# version 28.0

**Date:** March 16, 2026
**Branch:** main (Sessions 1–24 committed and deployed)
**Status:** Sessions 25–26 complete locally. Ready to commit after one remaining file.
           See "Pending Before Committing" below.

---

## !! RELIABILITY NOTICE — READ FIRST !!

The `decor-session-rules` skill (v1.2) is installed. Its description contains
the first mandatory action — read it from the available_skills context before
doing anything else.

**MANDATORY at every session start:**

STEP 0 — Tool sanity check:
```bash
echo "bash_tool OK"
```

STEP 1 — Read ALL five rule documents via bash cat:
```bash
cat /mnt/user-data/uploads/COMMON_BEHAVIOR.md
cat /mnt/user-data/uploads/RAILS_SPECIFICS.md
cat /mnt/user-data/uploads/PROGRAMMING_GENERAL.md
cat /mnt/user-data/uploads/DECOR_PROJECT.md
cat /mnt/user-data/uploads/SESSION_HANDOVER.md
```
After each: log "Read FILENAME — N lines, complete."

---

## !! SEPARATOR / TOKEN ESTIMATE FORMAT !!

Every response must follow this format:

```
================================================================================
(blank line)
**Token Usage...**
```

---

## !! TOKEN BUDGET WARNING !!

Session 26 hit 90% context usage after delivering only 5 files. The fixed
overhead (5 rule documents + system prompt + tool schemas + bash cat outputs)
consumes ~70–80% of the window before any work output is written.

**Practical consequence:** each session has room for roughly one focused task
(one feature, one set of tests, one commit). Do not plan multi-task sessions.

---

## Session 26 Summary

**Focus: Peripherals tab on components page + peripheral test coverage**

1. **`owners/components.html.erb` v1.1** — four-tab strip added.
   Was three tabs (Computers | Appliances | Components).
   Now four tabs (Computers | Appliances | Peripherals | Components).
   All other content unchanged from v1.0.
   This was the final blocker for committing Session 25 work.

2. **`computer_models.yml` v1.2** — `dec_vt278` peripheral fixture added.
   DEC VT278 (ReGIS graphics terminal), device_type: 2.
   Required by peripheral model tests and admin controller tests.

3. **`computer_test.rb` v1.6** — peripheral enum tests added:
   - `device_type can be set to peripheral`
   - `device_type_peripheral? is true for peripheral fixture` (charlie_dec_vt278)
   - `device_type_peripheral scope excludes computers and appliances`

4. **`computer_model_test.rb` v1.3** — peripheral enum tests added:
   - `device_type can be set to peripheral`
   - `device_type_peripheral? returns true for peripheral fixture` (dec_vt278)
   - `device_type_peripheral scope contains only peripheral fixtures`
   - `all three device_type scopes are mutually disjoint`

5. **`computers_controller_test.rb` v1.7** — peripherals route tests added:
   - `GET /peripherals loads successfully` (smoke test)
   - `GET /peripherals shows only peripherals, not computers or appliances`

---

## Work Completed Sessions 25–26 — Complete File List

    decor/db/migrate/20260316100000_add_device_type_check_to_computers.rb  v1.0  <- Session 25 new
    decor/app/models/computer.rb                                            v1.7  <- Session 25
    decor/app/models/computer_model.rb                                      v1.2  <- Session 25
    decor/config/routes.rb                                                  v2.2  <- Session 25
    decor/app/controllers/owners_controller.rb                              v1.7  <- Session 25
    decor/app/controllers/computers_controller.rb                           v1.16 <- Session 25
    decor/app/controllers/admin/computer_models_controller.rb               v1.3  <- Session 25
    decor/app/views/owners/peripherals.html.erb                             v1.0  <- Session 25 new
    decor/app/views/owners/computers.html.erb                               v1.1  <- Session 25
    decor/app/views/owners/appliances.html.erb                              v1.1  <- Session 25
    decor/app/views/owners/show.html.erb                                    v2.0  <- Session 25
    decor/app/views/common/_navigation.html.erb                             v1.7  <- Session 25
    decor/app/views/layouts/admin.html.erb                                  v1.8  <- Session 25
    decor/app/views/computers/_filters.html.erb                             v1.5  <- Session 25
    decor/test/fixtures/computers.yml                                       v1.8  <- Session 25
    decor/test/controllers/owners_controller_test.rb                        v1.4  <- Session 25
    decor/app/views/owners/components.html.erb                              v1.1  <- Session 26
    decor/test/fixtures/computer_models.yml                                 v1.2  <- Session 26
    decor/test/models/computer_test.rb                                      v1.6  <- Session 26
    decor/test/models/computer_model_test.rb                                v1.3  <- Session 26
    decor/test/controllers/computers_controller_test.rb                     v1.7  <- Session 26
    decor/docs/claude/SESSION_HANDOVER.md                                   v28.0 <- Session 26

---

## Pending Before Committing

1. **`admin/computer_models_controller_test.rb` — peripheral_models CRUD tests missing.**
   The file was never uploaded in Session 26 — session hit 90% before it could be done.
   Upload the current file at the start of next session and deliver the updated version
   before committing.

   Tests needed (index, create, destroy for the peripheral context):
   - `GET /admin/peripheral_models returns 200`
   - `POST /admin/peripheral_models creates a peripheral model`
   - `DELETE /admin/peripheral_models/:id destroys a peripheral model`
   These mirror the existing appliance_models tests in the same file.
   The `dec_vt278` fixture in `computer_models.yml` v1.2 provides the peripheral
   model record needed for the destroy test.

---

## Serial Number Assertion Note

`computers_controller_test.rb` v1.7 asserts `computers(:charlie_dec_vt278).serial_number`
is present in the GET /peripherals response. If this serial_number is nil in the
fixture (see Known Issues in DECOR_PROJECT.md), the assertion must be changed to
use a description substring instead. Verify when tests are run.

---

## Git State

Sessions 1–24 committed and deployed.
Sessions 25–26 work complete locally — not yet committed (pending admin controller test above).

---

## Priority 1 — Next Session

1. Upload `decor/test/controllers/admin/computer_models_controller_test.rb`.
2. Deliver updated version with peripheral_models CRUD tests.
3. Commit Sessions 25–26 work (bin/rails test → rubocop → brakeman → commit).
4. Dependabot PRs — dedicated session (do not mix with above).

---

## Priority 2 — Other candidates (unchanged)

1. Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
2. System tests: decor/test/system/ still empty
3. Account deletion + data export (GDPR)
4. Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
5. CHECK(device_type IN (0,1,2)) constraint on computer_models table (pending migration)
6. BulkUploadService stale model references (low priority):
     decor/app/services/bulk_upload_service.rb
     - Condition -> ComputerCondition
     - computer.condition -> computer.computer_condition
     - component.history field does not exist on Component model
     - component.condition -> component.component_condition

---

## Peripherals Feature — Design Reference (Session 25, unchanged)

### device_type enum (both Computer and ComputerModel)
```ruby
enum :device_type, { computer: 0, appliance: 1, peripheral: 2 }, prefix: true
```
CHECK(device_type IN (0,1,2)) constraint on computers table (migration 20260316100000).
No CHECK constraint yet on computer_models table — pending future migration.

### Routes added (routes.rb v2.2)
```ruby
# Public index
resources :peripherals, controller: "computers", only: [:index],
                        defaults: { device_context: "peripheral" }

# Owner sub-page
resources :owners do
  member do
    get :peripherals  # /owners/:id/peripherals → owners#peripherals
  end
end

# Admin models page
namespace :admin do
  resources :peripheral_models, only: %i[index new create edit update destroy],
                                controller: "computer_models",
                                defaults: { device_context: "peripheral" }
end
```
Route helpers: `peripherals_path`, `peripherals_owner_path`, `admin_peripheral_models_path`

### set_device_context — case/when pattern (computers_controller.rb v1.16)
```ruby
case params[:device_context]
when "appliance"
  @device_context = "appliance"; @page_title = "Appliances"
  @index_path = appliances_path; @turbo_tbody_id = "appliances"
  @load_more_id = :load_more_appliances
when "peripheral"
  @device_context = "peripheral"; @page_title = "Peripherals"
  @index_path = peripherals_path; @turbo_tbody_id = "peripherals"
  @load_more_id = :load_more_peripherals
else
  @device_context = "computer"; @page_title = "Computers"
  @index_path = computers_path; @turbo_tbody_id = "computers"
  @load_more_id = :load_more_computers
end
```
Same case/when pattern used in Admin::ComputerModelsController v1.3.

### Tab strip order (all four owner sub-page views)
Computers | Appliances | Peripherals | Components

### Summary card grid
`owners/show.html.erb` v2.0: `grid-cols-4` — Computers | Appliances | Peripherals | Components.

---

## Barter Feature — Design Reference (Sessions 21–22, unchanged)

### Enum definition (same on both models)
```ruby
enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true
```

### Filter logic (both controllers, index action)
```ruby
if logged_in?
  barter_filter = params[:barter_status].presence || "0+1"
  records = case barter_filter
            when "0"   then records.where(barter_status: 0)
            when "1"   then records.where(barter_status: 1)
            when "2"   then records.where(barter_status: 2)
            else            records.where(barter_status: [0, 1])
            end
end
```

### Colour coding
- offered   -> <span class="text-green-700">Offered</span>
- wanted    -> <span class="text-amber-600">Wanted</span>
- no_barter -> <span class="text-stone-400">--</span>

---

## Documents Updated This Session

    decor/docs/claude/SESSION_HANDOVER.md     v28.0  <- this file

No DECOR_PROJECT.md update required this session — the Key file versions table
and pending sections will be updated in the commit session alongside the full
test run.

---

**End of SESSION_HANDOVER.md**
