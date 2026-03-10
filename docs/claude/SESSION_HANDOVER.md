# decor/docs/claude/SESSION_HANDOVER.md
# version 25.0

**Date:** March 10, 2026
**Branch:** main (all Sessions 1–23 committed and deployed)
**Status:** Session 23 complete. Tree verified clean (271 files). Ready for next session.

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

## Session 23 Summary

1. **gh pr merge transient error** — resolved by retrying (GitHub-side API fault).

2. **Nav font size fix** — removed `text-sm` from the "Info" dropdown button
   (was visually smaller than other nav items rendered by `navigation_link_to`).

3. **Owner page split into sub-pages** — monolithic `/owners/:id` replaced with:
   - `/owners/:id` — compact summary card view (counts + View/Add links)
   - `/owners/:id/computers`, `/owners/:id/appliances`, `/owners/:id/components`
   Each sub-page: shared `_profile` partial + three-tab strip + single table.
   Logged-in username in nav bar became a dropdown (My Computers / My Appliances /
   My Components / Profile).

4. **Component description column** — truncated to 20 chars on owner components page.

5. **Brakeman XSS warning** — `_profile.html.erb` website `link_to`. `sanitize()`
   tried but does not satisfy Brakeman's taint tracking. Suppressed via
   `brakeman.ignore` (fingerprint `95b1e056...`).

6. **Admin nav "Invite Owner" link restored** — lost when dropdown layout was
   introduced in v1.3; re-added to Owners dropdown.

7. **Owner sub-page smoke tests** — three tests added to `owners_controller_test.rb`
   (computers / appliances / components -> 200 when logged in).

---

## Work Completed Session 23 — Complete File List

    decor/config/routes.rb                               v1.7 -> v1.8
    decor/app/controllers/owners_controller.rb           v1.5 -> v1.6
    decor/app/views/owners/show.html.erb                 v1.8 -> v1.9
    decor/app/views/owners/_profile.html.erb             v1.0 -> v1.1   <- new in session
    decor/app/views/owners/computers.html.erb            v1.0           <- new
    decor/app/views/owners/appliances.html.erb           v1.0           <- new
    decor/app/views/owners/components.html.erb           v1.0           <- new
    decor/app/views/common/_navigation.html.erb          v1.4 -> v1.5
    decor/app/views/layouts/admin.html.erb               v1.5 -> v1.6
    decor/config/brakeman.ignore                         (entries: 9023fba7, 95b1e056)
    decor/test/controllers/owners_controller_test.rb     v1.2 -> v1.3

---

## Git State

All work through Session 23 committed and deployed.
Tree verified: 271 files, consistent with all session deliveries.

---

## Priority 1 — Next Session: Admin Import/Export Feature

### Overview

Replace the existing admin nav "Import/Export" dropdown entry with a restructured
"Imports/Exports" dropdown containing two sub-items: "Imports" and "Exports".
Each links to a page where the admin selects what to import or export.

### Target data types (both Import and Export)

  1. Computer models       — fields: name, device_type
  2. Appliance models      — fields: name, device_type (always "appliance")
  3. Component types       — fields: name
  4. Owner collection data — all owners, OR admin picks one owner from a dropdown

### File format: CSV throughout

### Design decisions settled

- Computer models and Appliance models share the same ComputerModel AR model
  (device_type column distinguishes them). Their import/export can share one
  service class with a device_type parameter, or have separate service classes.
  Decide after reading the existing export/import service pattern.
- "Owner collection data" for a selected owner re-uses the existing
  OwnerExportService / OwnerImportService (already used by DataTransfersController).
  Admin version adds the ability to pick any owner, not just Current.owner.
- "All owners" export: strategy (concatenate per-owner exports or new service)
  to be decided after reading OwnerExportService at session start.

### Files that will need to be created or modified

New controller (admin namespace, inherits Admin::BaseController):
  decor/app/controllers/admin/data_transfers_controller.rb    <- new
    actions: show (landing/selector page), export, import

New services:
  decor/app/services/computer_model_export_service.rb         <- new
  decor/app/services/computer_model_import_service.rb         <- new
  decor/app/services/component_type_export_service.rb         <- new
  decor/app/services/component_type_import_service.rb         <- new
  (Owner collection re-uses existing OwnerExportService / OwnerImportService)

New views:
  decor/app/views/admin/data_transfers/show.html.erb          <- new
    Import: data type selector + owner dropdown (for owner data) + file upload
    Export: data type selector + owner dropdown (for owner data) + download button

Updated files:
  decor/config/routes.rb                                      v1.8 -> v1.9
  decor/app/views/layouts/admin.html.erb                      v1.6 -> v1.7

New tests:
  decor/test/controllers/admin/data_transfers_controller_test.rb   <- new
  decor/test/services/computer_model_export_service_test.rb        <- new
  decor/test/services/computer_model_import_service_test.rb        <- new
  decor/test/services/component_type_export_service_test.rb        <- new
  decor/test/services/component_type_import_service_test.rb        <- new

### Files to read at session start (before writing any code)

```bash
cat decor/app/controllers/data_transfers_controller.rb
cat decor/app/services/owner_export_service.rb
cat decor/app/services/owner_import_service.rb
cat decor/app/views/data_transfers/show.html.erb
cat decor/app/controllers/admin/base_controller.rb
cat decor/config/routes.rb
cat decor/app/views/layouts/admin.html.erb
cat decor/test/controllers/data_transfers_controller_test.rb
cat decor/test/services/owner_export_service_test.rb
cat decor/test/fixtures/owners.yml
cat decor/test/fixtures/computer_models.yml
cat decor/test/fixtures/component_types.yml
```

### CSV format conventions

The existing OwnerExportService / OwnerImportService establish the CSV pattern.
Read them before implementing the new services to follow the same header and
quoting conventions.

---

## Priority 2 — Dependabot PRs (dedicated session)

---

## Priority 3 — Other candidates (unchanged)

1. Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
2. System tests: decor/test/system/ still empty
3. Account deletion + data export (GDPR)
4. Spam / Postmark DNS fix (awaiting Rob's dashboard findings)
5. BulkUploadService stale model references (low priority):
     decor/app/services/bulk_upload_service.rb
     - Condition -> ComputerCondition
     - computer.condition -> computer.computer_condition
     - component.history field does not exist on Component model
     - component.condition -> component.component_condition

---

## Owner Sub-Pages — Design Reference (Session 23)

### Routes (routes.rb v1.8)
```ruby
resources :owners do
  member do
    get :computers   # /owners/:id/computers  -> computers_owner_path
    get :appliances  # /owners/:id/appliances -> appliances_owner_path
    get :components  # /owners/:id/components -> components_owner_path
  end
end
```

### Controller (owners_controller.rb v1.6)
- show       -> loads @computer_count, @appliance_count, @component_count only
- computers  -> @computers  (device_type: computer, eager_load, ordered by model name)
- appliances -> @appliances (device_type: appliance, eager_load, ordered by model name)
- components -> @components (eager_load, ordered by model/serial/type, NULLS LAST)

### Views
- owners/_profile.html.erb v1.1 — shared partial: header + info panel
  - website uses sanitize() as href + rel: "noopener noreferrer"
  - XSS warning suppressed in brakeman.ignore (model validates http/https-only)
- owners/show.html.erb v1.9 — three summary cards (count + View -> + Add links)
- owners/computers.html.erb v1.0 — tab strip (Computers active) + computers table
- owners/appliances.html.erb v1.0 — tab strip (Appliances active) + appliances table
- owners/components.html.erb v1.0 — tab strip (Components active) + components table
  - Description truncated to 20 characters

### Navigation (_navigation.html.erb v1.5)
- Info button: text-sm removed (matches other nav items)
- Username: dropdown with My Computers / My Appliances / My Components / Profile
  - right-aligned (right-0) to stay within viewport

---

## Barter Feature — Design Reference (Sessions 21–22)

### Enum definition (same on both models)
```ruby
enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true
# Predicates: barter_status_no_barter?, barter_status_offered?, barter_status_wanted?
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

### Auth rule
- Barter data visible to logged-in members ONLY
- if logged_in? guards on every th/td in index tables, owners/show, show pages

### Colour coding
- offered   -> <span class="text-green-700">Offered</span>
- wanted    -> <span class="text-amber-600">Wanted</span>
- no_barter -> <span class="text-stone-400">--</span>

### Fixture values
  Computers:
    computers(:alice_vax)          barter_status: 2 (wanted)
    computers(:dec_unibus_router)  barter_status: 1 (offered)
    all others                     barter_status: 0 (no_barter)
  Components:
    components(:spare_disk)             barter_status: 2 (wanted)
    components(:charlie_vt100_terminal) barter_status: 1 (offered)
    all others                          barter_status: 0 (no_barter)

---

## Documents Updated This Session

    decor/docs/claude/SESSION_HANDOVER.md     v25.0  <- this file

No rule document updates required this session — no new failure patterns encountered.

---

**End of SESSION_HANDOVER.md**
