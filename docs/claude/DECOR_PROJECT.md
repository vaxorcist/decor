# DECOR_PROJECT.md
# version 2.5

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** February 25, 2026 (Session 7: component_conditions table; conditions→computer_conditions rename; type cleanup; new component fields; rule set updates)
**Current Status:** Production-ready; session 7 changes fully committed and deployed

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

**Framework:** Ruby on Rails 8.1
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
│   │       ├── conditions_controller.rb    ← manages computer_conditions table
│   │       ├── component_types_controller.rb
│   │       ├── computer_models_controller.rb
│   │       └── run_statuses_controller.rb
│   ├── helpers/
│   │   ├── computers_helper.rb
│   │   └── components_helper.rb
│   ├── models/
│   │   ├── owner.rb
│   │   ├── computer.rb
│   │   ├── component.rb
│   │   ├── computer_condition.rb           ← renamed from condition.rb
│   │   └── component_condition.rb          ← new (Session 7)
│   └── views/
│       ├── home/
│       ├── owners/
│       ├── computers/
│       ├── components/
│       └── admin/
│           └── conditions/                 ← manages computer_conditions
├── config/
│   ├── deploy.yml
│   ├── routes.rb
│   └── master.key (NEVER commit!)
├── db/
│   └── migrate/
├── docs/
│   └── claude/                             ← rule set and session handover docs
└── test/
    ├── fixtures/
    └── models/
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
- belongs_to computer_condition (optional) ← renamed from condition
- belongs_to run_status (optional)
- has_many components, dependent: :nullify
- Validations:
  - serial_number: required, VARCHAR(20) + CHECK in DB
  - order_number: max 20 characters, optional, VARCHAR(20) + CHECK in DB

### Component
- belongs_to owner
- belongs_to computer (optional)
- belongs_to component_type
- belongs_to component_condition (optional) ← new (replaces old condition association)
- Fields: description (TEXT), serial_number VARCHAR(20), order_number VARCHAR(20)

### ComputerCondition (formerly Condition)
- Table: computer_conditions
- has_many computers, dependent: :restrict_with_error
- Managed via admin UI at /admin/conditions
- Examples: Completely original, Modified, Built from parts

### ComponentCondition (new)
- Table: component_conditions
- Column: condition VARCHAR(40) UNIQUE NOT NULL (note: "condition", not "name")
- has_many components, dependent: :restrict_with_error
- Managed via admin UI (to be built in a future session)
- Examples: Working, Defective

---

## Route Notes

`resources :conditions` in `decor/config/routes.rb` maps to `Admin::ConditionsController`
which manages the `computer_conditions` table (class `ComputerCondition`). The route
resource name was intentionally kept as `:conditions` to avoid a route rename ripple.
The controller uses explicit `url:` and `scope: :condition` in its form partial to
bridge the class name / route name mismatch.

---

## Work Completed - Sessions 1–6

(See SESSION_HANDOVER.md v7.0 for detail on Sessions 1–6)

Key milestones:
- Session 1: Index table layouts, search, serial number required
- Session 2: Rubocop fixes, owners page redesign
- Session 3: Password change functionality
- Session 4: Password strength validation, computers/components UI improvements
- Session 5: Embedded component sub-form on computer edit page
- Session 6: SQLite FK enforcement enabled, gem security updates, docs/claude/ directory

---

## Work Completed - Session 7 (February 25, 2026)

### 1. Database Restructuring (Branch 1)

Migration `20260225120000_component_conditions_and_type_cleanup.rb`:
- Renamed `conditions` → `computer_conditions`
- Created `component_conditions` table
- Renamed `computers.condition_id` → `computers.computer_condition_id`
- Added `components.component_condition_id`, `serial_number`, `order_number`
- Type cleanup: 11 columns across 6 tables tightened to VARCHAR(n) + CHECK

### 2. Application-Level Changes (Branch 2)

All models, controllers, helpers, and views updated to use the new schema.
New fields (`serial_number`, `order_number`, `component_condition`) added to
component forms, embedded sub-form, and show page.

### 3. Rule Set Updates

See SESSION_HANDOVER.md v8.0 for details.

---

## Pending — Next Session

No specific items required. Candidates:
- Admin UI for `component_conditions` table
- Legal/Compliance: Impressum, Privacy Policy, GDPR, Cookie Consent, TOS
- Dependabot PR #10: minitest 5.27.0 → 6.0.1
- System tests: `decor/test/system/` still empty
- Account deletion (GDPR), data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)

---

## Current Deployment Status

**Production Version:** Fully up to date through Session 7
**Pending:** Nothing — choose next topic at start of next session

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

### Layout Pattern (Computers/Components/Owners)
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

### Edit/New Form Pattern (Computers)
```
Container:  max-w-5xl mx-auto
Form:       width: 80%
Line 1:     grid grid-cols-3 gap-4  (model, order_number, serial_number)
Line 2:     grid grid-cols-2 gap-4  (computer_condition, run_status)
Line 3:     full width textarea      (history, 3 rows)
```

### Table Styling
- Dividers: `divide-y divide-stone-200`
- Sticky headers: `sticky top-0 z-10`
- Hover: `hover:bg-stone-50`
- Cell padding: `px-4 py-3`

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
- Admin UI for component_conditions table
- System tests: `decor/test/system/` still empty
- Dependabot PR #10: minitest 5.27.0 → 6.0.1
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
