# decor/docs/claude/DECOR_PROJECT.md
# version 2.7
# Session 9: components/show redesign (Step 3); back_controller.js; components/edit+form
# aligned with show layout; RAILS_SPECIFICS whitespace-pre-wrap rule added.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** February 27, 2026 (Session 9: component layout branch completed;
Stimulus Back controller added; computers/show redesign pending)
**Current Status:** Production-ready; session 9 changes fully committed and deployed

---

## Project Overview

**Name:** DEC Owner's Registry (DECOR)
**Purpose:** Community-driven registry of Digital Equipment Corporation (DEC) computers and their owners
**URL:** https://decorweb.net/
**Project Directory:** `decor/`
**Database:** SQLite (development and production)

**Operators:**
- English operator (holds domain, primary)
- German partner (website development)

**Status:**
- Non-commercial
- Hobbyist/community use
- Privacy-conscious (visibility controls)

---

## Technology Stack

**Framework:** Ruby on Rails 8.1.2
**Ruby Version:** 3.4
**CSS Framework:** Tailwind CSS
**JavaScript:** Turbo/Hotwire, Stimulus
**Pagination:** geared_pagination gem
**Deployment:** Kamal (Docker-based)
**Authentication:** has_secure_password (BCrypt)
**Server:** Ubuntu 24 Linux (46.224.178.173)

**Key Gems:**
- geared_pagination
- tailwindcss-rails
- turbo-rails
- stimulus-rails
- bcrypt
- zxcvbn-ruby (password strength validation)
- kamal
- brakeman 8.0.3

---

## Security & Authentication

### Authentication Method
**System:** `has_secure_password` with BCrypt
**Password Storage:** BCrypt digests with cost factor 12
**Session Management:** Rails session cookies

### Password Requirements

**Length:** Minimum 12 characters
**Strength:** Minimum zxcvbn score of 3 (strong/very strong)

**Test Passwords** (centralized in `decor/test/support/authentication_helper.rb`):
```ruby
TEST_PASSWORD_ALICE = "DecorAdmin2026!".freeze   # Admin user
TEST_PASSWORD_BOB   = "DecorUser2026!".freeze    # Regular user
TEST_PASSWORD_VALID = "ValidTest2026!".freeze    # Generic valid
```

### User Features
- Password reset via email (2-hour token expiry)
- Password change with current password verification
- Account self-deletion with password confirmation
- Password generator in UI (16-char secure passwords)

---

## File Structure

```
decor/
├── app/
│   ├── controllers/
│   │   ├── computers_controller.rb
│   │   ├── components_controller.rb
│   │   ├── owners_controller.rb
│   │   ├── home_controller.rb
│   │   └── admin/
│   │       ├── base_controller.rb
│   │       ├── conditions_controller.rb
│   │       ├── component_conditions_controller.rb
│   │       ├── component_types_controller.rb
│   │       ├── computer_models_controller.rb
│   │       └── run_statuses_controller.rb
│   ├── helpers/
│   │   ├── application_helper.rb
│   │   ├── style_helper.rb                      ← field_classes, button_classes
│   │   ├── computers_helper.rb
│   │   └── components_helper.rb
│   ├── javascript/
│   │   └── controllers/
│   │       └── back_controller.js               ← new (Session 9)
│   ├── models/
│   │   ├── owner.rb
│   │   ├── computer.rb
│   │   ├── component.rb
│   │   ├── computer_condition.rb
│   │   └── component_condition.rb
│   └── views/
│       ├── home/
│       ├── owners/
│       ├── computers/
│       ├── components/
│       └── admin/
│           ├── conditions/
│           └── component_conditions/
├── config/
│   ├── deploy.yml
│   ├── routes.rb
│   └── master.key (NEVER commit!)
├── db/
│   └── migrate/
├── docs/
│   └── claude/
└── test/
    ├── fixtures/
    └── controllers/
        └── admin/
```

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
Added "ERB + whitespace-pre-wrap — Literal Whitespace Gotcha": `whitespace-pre-wrap`
renders the newline + indentation between an opening tag and its `<%= %>` content
literally. Fix: put ERB tag on the same line as the opening HTML tag.

### 2. components/show.html.erb — Step 3 completed

    decor/app/views/components/show.html.erb    (v1.5)

- Line 1: 3-col — Computer | Type | Condition
- Line 2: 2-col — Order Number | Serial Number
- All values in styled display boxes (matching field_classes appearance)
- Description: styled box, min-height 4.5rem, ERB on same line (whitespace-pre-wrap fix)
- Outer bg-white border wrapper removed
- "← Back to owner" → Stimulus Back button

### 3. Stimulus Back Controller — new

    decor/app/javascript/controllers/back_controller.js    (v1.0)

Reusable controller: `history.back()` primary; falls back to
`data-back-fallback-url-value` when `history.length === 1`.
Auto-registered by stimulus-rails — no index.js edit needed.

### 4. Component Edit Page — aligned with show layout

    decor/app/views/components/edit.html.erb      (v1.1)
    decor/app/views/components/_form.html.erb     (v1.3)

- edit.html.erb: max-w-2xl → max-w-5xl; Stimulus Back button added
- _form.html.erb: fields reordered (Computer | Type | Condition / Order | Serial /
  Description); min-height on description; "Cancel" → "Done"

---

## Pending — Next Session

### Priority: computers/show.html.erb redesign

Redesign to match components/show layout:
- max-w-7xl → max-w-5xl; remove outer wrapper
- Line 1 (3-col): Order Number | Serial Number | Condition
- Line 2 (half-width): Run Status (left col of 2-col grid)
- Line 3 (full): History (whitespace-pre-wrap, min-height 4.5rem, ERB same line)
- Components table: Type → indigo link; "View" removed; "Edit" owner/admin only
- Stimulus Back button; fallback: owner_path(@computer.owner)
- **Open question:** confirm Run Status alone on left half of 2-col row

### Other Candidates
- Dependabot PRs — dedicated session
- Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
- System tests: decor/test/system/ still empty
- Account deletion + data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)

---

## Current Deployment Status

**Production Version:** Fully up to date through Session 9
**Pending:** computers/show.html.erb redesign

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
See RAILS_SPECIFICS.md v1.6.

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

### source=computer Redirect Pattern
When a component is created/updated/deleted from the computer edit page,
`source=computer` param causes `components_controller` to redirect back to
`edit_computer_path` instead of the default path.

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
