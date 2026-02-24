# DECOR_PROJECT.md
# version 2.3

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** February 22, 2026 (Session 5: Duplicate View links removed; Computer edit page redesigned; component sub-form embedded)
**Current Status:** Production-ready; session 5 changes pending commit/deploy

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

**Test Passwords** (centralized in `test/support/authentication_helper.rb`):
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
│   │   └── home_controller.rb
│   ├── helpers/
│   │   └── components_helper.rb
│   ├── models/
│   │   ├── owner.rb
│   │   ├── computer.rb
│   │   └── component.rb
│   └── views/
│       ├── home/
│       │   └── index.html.erb
│       ├── owners/
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── _owner.html.erb
│       │   └── _filters.html.erb
│       ├── computers/
│       │   ├── index.html.erb
│       │   ├── index.turbo_stream.erb
│       │   ├── _computer.html.erb
│       │   ├── _form.html.erb
│       │   ├── _computer_component_form.html.erb  ← NEW (session 5)
│       │   ├── edit.html.erb
│       │   ├── new.html.erb
│       │   ├── show.html.erb
│       │   └── _filters.html.erb
│       └── components/
│           ├── index.html.erb
│           ├── index.turbo_stream.erb
│           ├── _component.html.erb
│           └── _filters.html.erb
├── config/
│   ├── deploy.yml (Kamal configuration)
│   ├── routes.rb
│   └── master.key (NEVER commit!)
├── db/
│   └── migrate/
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
  - user_name: required, unique, max 15 characters
  - email: required, unique, valid format
  - country: ISO 3166 code (optional)
  - website: valid HTTP/HTTPS URL (optional)

### Computer
- belongs_to owner
- belongs_to computer_model
- belongs_to condition (optional)
- belongs_to run_status (optional)
- has_many components, dependent: :nullify
- Validations:
  - serial_number: required, NOT NULL in DB
  - order_number: max 20 characters, optional

### Component
- belongs_to owner
- belongs_to computer (optional)
- belongs_to component_type
- belongs_to condition (optional)

---

## Work Completed - Session 1

### 1. Converted Index Pages from Grid to Table Layout
### 2. Implemented Search Functionality
### 3. Made Serial Number Required for Computers
### 4. Fixed Nil Errors for Optional Fields

---

## Work Completed - Session 2

### 1. Rubocop Fixes
### 2. Test Failures Fixed
### 3. Fixed Production Deployment
### 4. Updated Owners Page (layout, validations, filtering)

---

## Work Completed - Session 3

### Password Change Functionality
- Added "Change Password" section to Edit Profile page
- Current password required; 7 controller tests, manual testing complete

---

## Work Completed - Session 4

### 1. Merged Password Strength Validation (from Session 3 branch)
### 2. Computers Page — UI Improvements
### 3. Components Page — UI Improvements + Sort Options
### 4. README.md Corrected
### 5. Renamed computers.description → order_number

---

## Work Completed - Session 5

### 1. Removed Duplicate "View" Links from Index Pages

Each index page had a redundant "View" link alongside the clickable first-column
value that already linked to the same show page. Removed from all three partials.

**Files modified:**

    decor/app/views/owners/_owner.html.erb (v3.2)
    decor/app/views/computers/_computer.html.erb
    decor/app/views/components/_component.html.erb

### 2. Computer Edit/New Page — Redesigned Form

**Layout changes:**
- Line 1: Model | Order Number | Serial Number (3-column grid)
- Line 2: Condition | Run Status (2-column grid)
- Line 3: History (3 rows, min-height 4.5rem)
- Width: form at 80%, container widened from max-w-2xl to max-w-5xl
- Asterisks moved inline into labels for vertical alignment
- Descriptive hint texts added under Model, Order Number, Serial Number
- "Cancel" renamed to "Done" (no implication of reverting prior actions)

**Files modified:**

    decor/app/views/computers/_form.html.erb (v1.7)
    decor/app/views/computers/edit.html.erb (v1.1)
    decor/app/views/computers/new.html.erb (v1.2)

### 3. Embedded Component Sub-Form on Computer Edit Page

Components can now be added, edited, and deleted directly from the computer
edit page without navigating away.

**Design decisions:**
- Add/Edit sub-form appears ABOVE the components list
- Heading changes to "Edit Computer's Component" when editing an existing one
- "Done" button on sub-form clears edit state, stays on edit page
- Computer field not shown — pre-set via hidden field
- Edit and Delete actions side by side in component list
- Delete requires turbo confirm dialog
- `source=computer` hidden param causes components_controller to redirect
  back to edit_computer_path after create/update/destroy
- Nested forms avoided — component section is after the computer form_with end tag
- After "Create Computer", user is redirected to edit page (not show page)
  so components can be added immediately

**Files modified/created:**

    decor/app/views/computers/_form.html.erb (v1.7)           Component section added
    decor/app/views/computers/_computer_component_form.html.erb (v1.1, NEW)
    decor/app/controllers/computers_controller.rb (v1.4)       edit sets @new_component/@edit_component; create redirects to edit
    decor/app/controllers/components_controller.rb (v1.2)      source=computer redirect handling

**Deployed:** Session 5 changes pending commit/deploy (see below)

---

## Pending — Ready to Commit (Start of Next Session)

```bash
bin/rails test
bundle exec rubocop -A && bundle exec rubocop
git add -A
git commit -m "Computer edit page: redesigned form, embedded component sub-form

- Reorder fields: Model/OrderNumber/SerialNumber, Condition/RunStatus, History
- Widen form to 80% / max-w-5xl; add hint texts; inline asterisks for alignment
- Remove duplicate View links from all three index page partials
- Embed Add/Edit/Delete component sub-form on computer edit page
- Redirect to edit page after Create Computer (skip intermediate show page)
- Rename Cancel to Done on computer and component sub-forms"

git push
gh pr create --title "Computer edit page: redesigned form and embedded component sub-form"
gh pr checks
gh pr merge --merge --delete-branch
git pull
kamal deploy
```

---

## Current Deployment Status

**Production Version:** Up to date through Session 5 part 1 (View link removal)
**Pending commit:** Session 5 parts 2 and 3 (form redesign + component sub-form)
**All Tests:** Expected passing — run to confirm before commit

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
Line 2:     grid grid-cols-2 gap-4  (condition, run_status)
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
Cannot add named CHECK constraints. Use model validation only.

### Squash Merge Git Divergence
Use `gh pr merge --merge` (not `--squash`).
Recovery: `git fetch origin && git reset --hard origin/main`

### Turbo Stream Pagination Borders
Place `id="items"` on `<tbody>`, not outer div.

### Kamal Missing Secrets
Use `kamal app exec --reuse` (not `kamal app exec`).

### Nested Forms
Rails/HTML does not allow a form inside a form. When embedding a component
sub-form on the computer edit page, the component section must be placed AFTER
the computer `form_with` end tag, not inside it. `button_to` (which renders its
own mini-form) must also be outside the main form.

### source=computer Redirect Pattern
When a component is created/updated/deleted from the computer edit page,
a hidden `source=computer` param is passed. `components_controller` checks
this param and redirects to `edit_computer_path` instead of the default path.
This keeps the user on the computer edit page throughout.

---

## Future Considerations

### Legal/Compliance (Pending)
- Impressum (German law), Privacy Policy (GDPR), Cookie Consent, Terms of Service

### Technical Improvements (Optional)
- System tests: `test/system/` still empty — priority: account deletion, password change
- Dependabot PR #10: minitest 5.27.0 → 6.0.1
- Image upload (if added: AWS Rekognition for moderation)
- Migrate SQLite → PostgreSQL (better constraint support)
- Account deletion (GDPR), data export (GDPR)
- Spam / Postmark DNS fix (awaiting Rob's dashboard findings)

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
