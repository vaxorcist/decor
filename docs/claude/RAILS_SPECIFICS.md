# RAILS_SPECIFICS.md
# version 1.4

**Ruby on Rails Specific Patterns and Best Practices**

**Last Updated:** February 24, 2026 (Added: SQLite FK enforcement — explicit config, pre-enable verification including production; .yml files render in context window)

---

## Rails Version Compatibility - CRITICAL

**ALWAYS verify Rails version compatibility before implementing ANY Rails-specific code.**

### Check Project Rails Version

**Before writing any Rails code:**
1. Check project documentation: `DECOR_PROJECT.md` or equivalent
2. Check `Gemfile.lock` for exact Rails version
3. Verify feature/method exists in that version
4. Check existing project files for established patterns

**Current DECOR project:** Rails 8.1 (from DECOR_PROJECT.md)

### Rails Version-Specific Changes

**Rails 5.0+ (2016):**
- `assigns()` deprecated - don't use in new tests
- Controller tests should check response status, not instance variables
- `assigns(:variable)` → Use `assert_response` and JSON/HTML parsing

**Rails 6.0+ (2019):**
- `assigns()` completely removed - will cause NoMethodError
- Must use response body parsing or status codes
- Integration tests preferred over controller tests

**Rails 7.0+ (2021):**
- `assert_response` patterns are standard
- Hotwire/Turbo introduced
- Modern testing focuses on behavior, not internals

**Rails 8.0+ (2024):**
- No access to controller instance variables in tests
- Use `assert_response :unprocessable_entity` to verify validation failures
- Check response body/JSON for specific error messages if needed
- Stimulus/Turbo patterns standard

### Common Compatibility Issues

**Don't Use (Removed in Rails 6+):**
```ruby
# BAD - Will fail in Rails 6+
test "validation fails" do
  post users_url, params: { user: { name: "" } }
  assert_not assigns(:user).valid?  # NoMethodError: assigns
end
```

**Use Instead (Rails 6+):**
```ruby
# GOOD - Works in all modern Rails
test "validation fails" do
  post users_url, params: { user: { name: "" } }
  assert_response :unprocessable_entity
end
```

### Verification Checklist

Before implementing Rails-specific code:
- [ ] Checked Rails version in project docs
- [ ] Verified feature exists in that version
- [ ] Reviewed existing project test patterns
- [ ] Checked Rails guides for version-specific syntax
- [ ] Tested locally before suggesting

### When Creating Test Helpers

**CRITICAL:** Check existing test files FIRST to see if helper already exists or if pattern is already established.

**Example: assert_record_errors**
```ruby
# DON'T blindly create helpers that use removed features
def assert_record_errors
  assert assigns(:record).errors.any?  # FAILS in Rails 6+
end

# DO check if helper is even needed
# Most tests already use assert_response :unprocessable_entity
# which proves validation failed
```

---

## Rails Testing Patterns

### Centralized Test Helpers

**ALWAYS create support modules for shared test logic.**

**Structure:**
```
test/
├── support/
│   ├── authentication_helper.rb  # Login/auth methods
│   ├── test_constants.rb         # Shared constants
│   └── factory_helpers.rb        # Test data creation
├── test_helper.rb               # Include support modules here
└── ... rest of tests
```

**test/support/authentication_helper.rb:**
```ruby
module AuthenticationHelper
  TEST_PASSWORD_ADMIN = "password12345".freeze
  TEST_PASSWORD_USER = "password45678".freeze

  def login_as(user, password: nil)
    password ||= detect_password(user)
    post session_path, params: {
      user_name: user.user_name,
      password: password
    }
  end

  private

  def detect_password(user)
    # Auto-detect based on fixture
    case user.user_name
    when "admin_user"
      TEST_PASSWORD_ADMIN
    else
      TEST_PASSWORD_USER
    end
  end
end
```

**test/test_helper.rb:**
```ruby
# Load all support modules
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

module ActiveSupport
  class TestCase
    include AuthenticationHelper
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
```

### Never Duplicate Login Methods

**Bad (Duplicated across 10 files):**
```ruby
# admin/users_controller_test.rb
def log_in_as(user, password: "password123")
  post session_url, params: { ... }
end

# admin/posts_controller_test.rb
def log_in_as(user, password: "password123")  # DUPLICATE
  post session_url, params: { ... }
end
```

**Good (Centralized):**
```ruby
# test/support/authentication_helper.rb - ONE place
# All tests inherit this method
```

### Test Data Constants

**Bad (Scattered):**
```ruby
# Multiple files with:
password: "password123"
password: "validpass12"
password: "testpass123"
```

**Good (Centralized):**
```ruby
# test/support/test_constants.rb
module TestConstants
  TEST_PASSWORD_VALID = "password12345".freeze
  TEST_EMAIL_VALID = "test@example.com".freeze
  TEST_USERNAME_VALID = "testuser".freeze
end

# All tests use:
password: TEST_PASSWORD_VALID
```

---

## Ruby Code Style

### String Literals
- ✅ **Always use double quotes** unless single quotes needed to avoid escaping
- ❌ WRONG: `'Makes serial_number required'`
- ✅ RIGHT: `"Makes serial_number required"`
- This is Rubocop standard

### Whitespace
- ✅ No trailing whitespace
- ✅ Consistent indentation (2 spaces for Ruby)
- ✅ Blank line at end of file

---

## Rails File Naming Conventions

### CRITICAL: Use Exact Rails File Names

**Views:**
- ✅ `index.html.erb` NOT `computers_index.html.erb`
- ✅ `_computer.html.erb` NOT `_computers.html.erb`
- ✅ `index.turbo_stream.erb` for turbo stream responses

**Models/Controllers:**
- ✅ Singular for model: `computer.rb`
- ✅ Plural for controller: `computers_controller.rb`

---

## Geared Pagination Pattern

### Controller
```ruby
def index
  # Build query
  items = Model.includes(:associations).where(...)

  # Use paginate - provided by geared_pagination gem
  paginate items
end
```

### Views Access Data via @page.records
```erb
<% @page.records.each do |item| %>
  <%= render "item", item: item %>
<% end %>
```

**NOT** `@items` or `@scope` - always `@page.records`

---

## Turbo Stream Pagination Pattern

### CRITICAL: ID Must Be on <tbody>

**Problem:** When turbo_stream appends rows, they must go into `<tbody>`, not outer div.

**Correct Pattern:**

**index.html.erb:**
```erb
<table>
  <thead>...</thead>
  <tbody id="items" class="...">
    <% @page.records.each do |item| %>
      <%= render "item", item: item %>
    <% end %>
  </tbody>
</table>
```

**index.turbo_stream.erb:**
```erb
<%= turbo_stream.append :items do %>
  <% @page.records.each do |item| %>
    <%= render "item", item: item %>
  <% end %>
<% end %>
```

**Why:** Appending to outer div causes border/styling issues. The `id` must be on `<tbody>` so new rows are properly inserted as table rows.

---

## Safe Navigation for Optional Associations

### The Problem
```ruby
belongs_to :condition, optional: true
```

If `condition` is nil, calling `.condition.name` causes NoMethodError.

### The Solution
```erb
<!-- WRONG -->
<%= computer.condition.name %>

<!-- RIGHT -->
<%= computer.condition&.name || "—" %>
```

**Pattern:** When a field is optional, ALWAYS use safe navigation (`&.`) or nil checks in ALL views.

---

## Rails Validation vs Database Constraints

### Model Validation (Application Layer)
```ruby
class Computer < ApplicationRecord
  validates :serial_number, presence: true, length: { maximum: 15 }
end
```

**Pros:**
- User-friendly error messages
- Catches errors early
- Easy to implement

**Cons:**
- Can be bypassed (bulk imports, raw SQL, console with `.update_column`)

### Database Constraint (Database Layer)
```ruby
class AddConstraint < ActiveRecord::Migration[8.1]
  def change
    # PostgreSQL/MySQL
    change_column_null :computers, :serial_number, false
  end
end
```

**Pros:**
- Cannot be bypassed
- Enforces data integrity at lowest level

**Cons:**
- Less friendly error messages
- SQLite has severe limitations

### Best Practice: Use Both (Defense-in-Depth)
- Database constraint prevents bypass
- Model validation provides good UX
- Together = robust data integrity

---

## SQLite Limitations

### ALTER TABLE Constraints

**Problem:** SQLite cannot add named CHECK constraints to existing tables.

**This FAILS on SQLite:**
```ruby
execute <<-SQL
  ALTER TABLE owners
  ADD CONSTRAINT check_name_length
  CHECK (LENGTH(name) <= 15)
SQL
```

**Error:** `near "CONSTRAINT": syntax error`

**What SQLite DOES support without table recreation:**

    ADD COLUMN                    Nullable column or column with default value
    RENAME TABLE                  Rename entire table
    RENAME COLUMN                 Rename a column (SQLite 3.25+, 2018)
    DROP COLUMN                   Remove a column (SQLite 3.35+, 2021)
    CREATE / DROP INDEX           Add or remove indexes
    CREATE / DROP VIEW            Add or remove views

**What requires full table recreation:**

    Change column type             e.g. INTEGER → TEXT
    Change column constraints      e.g. add NOT NULL, add UNIQUE
    Add named CHECK constraints    e.g. CHECK (LENGTH(name) <= 15)
    Add FOREIGN KEY constraints    to an existing table
    Remove a column constraint     e.g. drop NOT NULL from existing column
    Reorder columns                not possible at all

**Solutions for unsupported changes:**
1. **Use validation only** (recommended for SQLite projects)
2. **Recreate table** (Rails handles with change_table — slow on large datasets)
3. **Migrate to PostgreSQL** (best long-term solution)

### When Using SQLite
- ✅ Check database type BEFORE creating constraint migrations
- ✅ Consider validation-only approach
- ✅ Document this limitation
- ✅ Plan migration to PostgreSQL/MySQL if constraints are critical

---

## SQLite Migration Backup Pattern

### Problem
Destructive migrations (table recreation) involve copying all data to a new table.
If hardware failure or corruption occurs, data may be lost.
SQLite's transaction journaling handles clean process interruptions (crash, exception) —
the database rolls back to its pre-migration state. But journaling does NOT protect
against hardware failure or disk corruption.

### Solution: Backup in Migration

```ruby
# decor/db/migrate/YYYYMMDDHHMMSS_descriptive_name.rb - version 1.0
# Backs up SQLite database before destructive table recreation

class DescriptiveName < ActiveRecord::Migration[8.1]
  def up
    # Step 1: Backup database file before any structural changes
    db_path = ActiveRecord::Base.connection.pool.db_config.database
    backup_path = "#{db_path}.backup-#{Time.now.strftime("%Y%m%d%H%M%S")}"
    FileUtils.cp(db_path, backup_path)
    Rails.logger.info "Database backed up to #{backup_path}"

    # Step 2: Proceed with migration
    change_table :table_name, bulk: true do |t|
      # your changes here
    end
  end

  def down
    # rollback logic
  end
end
```

**When to use this pattern:**
- ✅ Any migration that requires table recreation (unsupported ALTER TABLE operations)
- ✅ Any migration adding NOT NULL constraints to populated tables
- ✅ Any migration you are uncertain about in production

**When NOT needed:**
- Adding a nullable column (ADD COLUMN — safe, no recreation)
- Adding an index (safe, reversible)
- Renaming a table or column (safe, reversible)

**Recovery:** If migration fails after backup, restore with:
```bash
cp storage/development.sqlite3.backup-YYYYMMDDHHMMSS storage/development.sqlite3
```

---

## Rails Migration Best Practices

### Migration Template
```ruby
# project/db/migrate/YYYYMMDDHHMMSS_descriptive_name.rb - version 1.0
# Description of what this migration does and why

class DescriptiveName < ActiveRecord::Migration[8.1]
  def change
    # Migration code
  end
end
```

### Reversible Migrations
```ruby
def change
  reversible do |dir|
    dir.up do
      # Forward migration
    end

    dir.down do
      # Rollback migration
    end
  end
end
```

### Production Migration Workflow

**For projects using Kamal:**
```bash
# 1. After PR merge, run migration in production FIRST
kamal app exec --reuse "bin/rails db:migrate"

# 2. THEN deploy the code
kamal deploy
```

**Why `--reuse`:**
- Uses existing running container (has secrets/env vars)
- Creating new container often fails with missing secrets

---

## Rails Testing Patterns

### Fixtures
**Location:** `test/fixtures/model_name.yml`

**When field becomes required, update ALL fixtures:**
```yaml
# test/fixtures/computers.yml
computer_one:
  model: pdp11
  serial_number: "SN-001"  # Don't forget this!
  owner: owner_one
```

**Add comment linking to test constants:**
```yaml
# Test passwords defined in test/support/authentication_helper.rb
# Admin user: TEST_PASSWORD_ADMIN
# Regular user: TEST_PASSWORD_USER
```

### Model Tests
**Location:** `test/models/model_name_test.rb`

**Use centralized constants:**
```ruby
require "test_helper"

class ModelTest < ActiveSupport::TestCase
  def valid_attributes
    {
      user_name: "testuser",
      email: "test@example.com",
      password: TEST_PASSWORD_VALID,  # From AuthenticationHelper
      password_confirmation: TEST_PASSWORD_VALID
    }
  end

  test "field must be present" do
    model = Model.new(valid_attributes.merge(field: nil))
    assert_not model.valid?
    assert_includes model.errors[:field], "can't be blank"
  end
end
```

### Test Update Checklist for Required Fields
1. ✅ Update fixtures with valid values
2. ✅ Search for `Model.new` - add field to all instances
3. ✅ Search for `Model.create` - add field to all instances
4. ✅ Add validation tests
5. ✅ Run full test suite

### Integration Test Authentication Pattern

**Use centralized helper:**

```ruby
# test/controllers/feature_test.rb
class FeatureTest < ActionDispatch::IntegrationTest
  # AuthenticationHelper is included automatically

  test "authenticated action" do
    login_as(users(:admin))  # Auto-detects password
    # Test authenticated action
  end
end
```

**Don't duplicate login logic in each test file.**

### CRITICAL: Integration Tests vs System Tests - Know the Difference

**Lesson learned:** Integration tests cannot catch browser/UI bugs. Several bugs
required manual testing to find that system tests would have caught automatically.

**What Integration Tests CAN catch:**
- ✅ Controller logic (authentication, authorization)
- ✅ Database changes (record created/deleted)
- ✅ Redirect behavior (assert_redirected_to)
- ✅ Flash values in Ruby (flash[:alert])
- ✅ Response status codes

**What Integration Tests CANNOT catch:**
- ❌ HTML form structure issues (e.g. nested forms)
- ❌ JavaScript/Turbo behavior (e.g. form not submitting)
- ❌ Flash messages actually rendered in HTML
- ❌ Navigation/layout elements (e.g. admin badge showing to all)
- ❌ Confirmation dialog behavior

**What System Tests (Capybara) additionally catch:**
- ✅ Form submission through real browser
- ✅ JavaScript interactions and Turbo behavior
- ✅ Flash messages actually rendered on screen
- ✅ Navigation elements visible to user
- ✅ Full user workflows end-to-end

**Real examples from DECOR that only manual testing caught:**
- Nested form caused delete button to trigger update action instead
- Turbo blocked form submission completely and silently
- `flash[:alert]` set in controller but never rendered in view
- Admin badge shown to ALL logged-in users (not just admins)

**Rule: For any feature involving forms, JavaScript, or visual feedback:**
Write BOTH integration tests AND system tests.

```ruby
# Integration test - controller behavior
# test/controllers/owners_controller_destroy_test.rb
test "should delete own account with correct password" do
  login_as(@alice)
  assert_difference("Owner.count", -1) do
    delete owner_path(@alice), params: { password: TEST_PASSWORD_ALICE }
  end
  assert_redirected_to root_path
end

# System test - full browser behavior (TO BE ADDED next session)
# test/system/account_deletion_test.rb
test "delete with wrong password shows error message on screen" do
  # Fills form in browser, clicks button, checks visible error message
  # Catches flash rendering bugs that integration tests miss
end
```

**DECOR Project:** Capybara + Selenium already configured.
System tests live in `test/system/` (currently empty - to be populated).

**When to write system tests:**
- ✅ New forms with submit actions
- ✅ Features using JavaScript or Turbo
- ✅ Navigation/layout changes
- ✅ Any feature where visual feedback matters to the user

---

## Sort Queries with Joined Tables

### CRITICAL: Use joins() not includes() for ORDER BY on associated tables

**Problem:** When sorting by a column on an associated table, `includes()` does not
guarantee a SQL JOIN — Rails may use a separate query (eager loading). The ORDER BY
then fails silently or sorts incorrectly.

**Wrong:**
```ruby
# includes() alone does NOT reliably support ORDER BY on joined table
components.includes(:owner).order("owners.user_name asc")
```

**Correct:**
```ruby
# joins() forces the SQL JOIN needed for ORDER BY
components.joins(:owner).order("owners.user_name asc")
```

**Note:** If you need both the join for sorting AND eager loading for performance,
combine both:
```ruby
components.includes(:owner).joins(:owner).order("owners.user_name asc")
```

**Real example from DECOR (Session 4):**
```ruby
when "owner_asc" then components.joins(:owner).order("owners.user_name asc")
when "type_asc"  then components.joins(:component_type).order("component_types.name asc")
```

---

## Common Rails Patterns in This User's Projects

### Controller Filtering Pattern
```ruby
def index
  items = Model.includes(:associations).search(params[:query])

  # Apply filters
  items = items.where(field: params[:filter]) if params[:filter].present?

  # Apply sorting
  items = case params[:sort]
  when "asc" then items.order(field: :asc)
  when "desc" then items.order(field: :desc)
  else items.order(created_at: :desc)
  end

  paginate items
end
```

### View Link Pattern for Filtering
```erb
<%= link_to count, path(filter_param: value), class: "text-indigo-600 hover:text-indigo-900" %>
```

---

## Rails File Structure Reminders

```
project/
├── app/
│   ├── controllers/
│   │   └── model_controller.rb
│   ├── models/
│   │   └── model.rb
│   └── views/
│       └── models/
│           ├── index.html.erb
│           ├── index.turbo_stream.erb
│           ├── _model.html.erb
│           └── _filters.html.erb
├── db/
│   └── migrate/
│       └── YYYYMMDDHHMMSS_migration_name.rb
└── test/
    ├── support/              # ← Centralized helpers
    │   ├── authentication_helper.rb
    │   └── test_constants.rb
    ├── fixtures/
    │   └── models.yml
    ├── models/
    │   └── model_test.rb
    └── controllers/
        └── models_controller_test.rb
```

---

## Rails Test Class — Required Inclusions

Different test base classes include different helpers automatically. Missing inclusions
cause `NoMethodError` at runtime, not at load time — easy to miss until the test runs.

**Known inclusions NOT automatic — must be added explicitly:**

`ActionMailer::TestHelper` (provides `assert_emails`, `assert_no_emails`):
- ✅ Included automatically in: `ActionMailer::TestCase`
- ❌ NOT included in: `ActiveJob::TestCase`, `ActiveSupport::TestCase`, `ActionDispatch::IntegrationTest`
- Fix: `include ActionMailer::TestHelper` at the top of the test class

**Rule: When writing a job test that sends emails, always add:**
```ruby
class MyJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
end
```

**Real example from Session 5 (February 20, 2026):**
- `InviteReminderJobTest < ActiveJob::TestCase` used `assert_emails`
- 3 tests failed with `NoMethodError: undefined method 'assert_emails'`
- Fix: one line — `include ActionMailer::TestHelper`

---

## Rails Test Helper — save! vs create! with Callbacks

**`save!(validate: false)` skips `before_validation` callbacks entirely.**

This is a common trap when trying to bypass validations while still wanting
callbacks (e.g. token generation, timestamp setting) to run.

**Wrong — skips ALL before_validation callbacks:**
```ruby
record = Model.new(email: "x@example.com")
record.save!(validate: false)  # before_validation never runs
# Result: NOT NULL constraint fails if callback was supposed to set a required field
```

**Correct — use create! then override with update_columns:**
```ruby
record = Model.create!(email: "x@example.com")  # all callbacks run normally
record.update_columns(sent_at: 21.days.ago)      # override timestamp directly in DB
```

`update_columns` writes directly to the DB, bypassing callbacks and validations —
useful for backdating timestamps in tests without triggering business logic.

**Real example from Session 5 (February 20, 2026):**
- `Invite.save!(validate: false)` meant `set_sent_at` callback never ran
- SQLite raised `NOT NULL constraint failed: invites.sent_at`
- All 12 tests in `InviteReminderJobTest` failed immediately
- Fix: switch to `create!` then `update_columns`



### Which file types appear in the context window automatically
Only these file types are rendered as readable text when uploaded:
- .md, .txt, .html, .csv (as text)
- .yml, .yaml (as text — these DO render in context window)
- .png (as image)
- .pdf (as image)

### ERB and other code files — ALWAYS use the view tool

**ERB files (.erb) do NOT appear in the context window**, even when uploaded.
The same applies to .rb, .js, and all other code file types.

**.yml/.yaml files DO appear in the context window** — no view tool needed.
Never ask the user to re-upload a .yml file; read it directly from the context.

**RULE: When a user uploads any .erb, .rb, or other non-Markdown, non-YAML file,
ALWAYS use the `view` tool immediately — do NOT assume the content is visible.
Never ask the user to re-upload a file that was already uploaded. The file is
on the filesystem at `/mnt/user-data/uploads/` — just read it.**

**Correct behaviour:**
```
User uploads: index_html.erb
Claude: [immediately calls view tool on /mnt/user-data/uploads/index_html.erb]
```

**Wrong behaviour:**
```
"The file wasn't recognized — could you upload it again?"
← The file was there all along. Claude simply didn't read it.
```

**Real example from Session 5 (February 20, 2026):**
- User uploaded `index_html.erb` twice
- Claude failed to read it both times, asking the user to re-upload
- Root cause: ERB files are only on the filesystem, not in context window
- Fix: use the `view` tool proactively for every non-Markdown upload
- Cost: wasted user time and tokens, avoidable frustration

---

## SQLite Foreign Key Enforcement — MANDATORY for New Projects

### Why SQLite Does NOT Enforce FKs by Default

SQLite defines FK constraints in the schema (visible in `.schema` output), but
silently ignores them at runtime unless explicitly enabled per connection.
This means invalid FK values can be written to the database with no error —
defeating the entire purpose of FK constraints.

**Rails 8.1 with the SQLite3 adapter does NOT enable FK enforcement automatically.**
It must be configured explicitly in `database.yml`.

### How to Enable FK Enforcement

Add `foreign_keys: true` to the `default:` section of `config/database.yml`.
This applies to all environments (development, test, production) via YAML anchor.

```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  foreign_keys: true        # ← Enables PRAGMA foreign_keys = ON per connection
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

**This is required for every SQLite-based Rails project.**

### Pre-Enable Verification — CRITICAL

**Before enabling FK enforcement on an existing project**, verify no orphaned
records exist. Enabling FK enforcement on dirty data will cause runtime errors.

**Step 1: Identify all FK relationships from `.schema` output**

**Step 2: Run verification queries for each FK:**
```bash
sqlite3 storage/development.sqlite3 << 'EOF'
-- Example for a project with components and computers tables.
-- Adapt to your actual schema.
SELECT 'table_a → table_b' AS check_name, COUNT(*) AS orphaned_rows
FROM table_a WHERE fk_id IS NOT NULL
  AND fk_id NOT IN (SELECT id FROM table_b)
UNION ALL
SELECT 'table_a → table_c (required)',
  COUNT(*) FROM table_a WHERE required_fk_id NOT IN (SELECT id FROM table_c);
EOF
```

**Step 3: All counts must be 0 before enabling.**
If any are non-zero, fix the data first (update or delete orphaned records).

**Step 4: Verify production data BEFORE deploying — CRITICAL.**
Development and production are independent databases. A clean development DB
does not guarantee a clean production DB. Run the equivalent check against
production BEFORE running `kamal deploy`:

```bash
kamal app exec --reuse "bin/rails runner \"
# Adapt to your actual models and FK relationships
puts 'components → conditions: ' + Component.where.not(condition_id: nil).where.not(condition_id: Condition.select(:id)).count.to_s
puts 'computers → owners: ' + Computer.where.not(owner_id: Owner.select(:id)).count.to_s
# ... add all FK relationships
\""
```

All counts must be 0. If any are non-zero, fix production data before deploying.

**Step 5: Enable FK enforcement, then immediately run full test suite:**
```bash
bin/rails test
```

**Step 6: Deploy only after steps 1–5 are all clean.**

A clean test run confirms no test was relying on invalid FK values being silently accepted.

**Correct deployment order:**
1. Verify development data clean
2. Run full test suite
3. Verify production data clean  ← MUST happen before deploy
4. Deploy (`kamal deploy`)
5. Confirm post-deploy (app running, no errors)

**Real example (DECOR, February 24, 2026):** Production verification was done
AFTER deployment — wrong order. Fortunately data was clean, but this was luck,
not process. Always verify production before deploying.

### FK Enforcement Cleanup as a Standalone PR

When adding FK enforcement to an existing project mid-development:
- ✅ Do it as a dedicated, isolated PR — not bundled with feature work
- ✅ Verify data clean in ALL environments (dev, test, prod separately)
- ✅ Run full test suite before and after
- ✅ Commit only `database.yml` in this PR — nothing else
- Reason: clean, auditable, easy to revert if an issue is found

### Model-Level FK Validation

`foreign_keys: true` in `database.yml` enforces at the DB level.
Complement it with Rails model validations for user-friendly error messages:

```ruby
# For optional FK:
belongs_to :component_condition, optional: true

# For required FK:
belongs_to :component_type  # optional: false is the default
```

Rails `belongs_to` with `optional: false` ensures the field is not nil.
The DB FK constraint ensures the referenced record actually exists.
Both layers together = full defense-in-depth.

### Real Example (DECOR Project, February 24, 2026)

- Schema had FK constraints defined on `components` and `computers` tables
- `PRAGMA foreign_keys` was never set → constraints were decorative only
- `grep` confirmed no `foreign_keys:` setting anywhere in config/
- Pre-enable verification: all 8 FK relationships had 0 orphaned records
- Added `foreign_keys: true` to `database.yml` default section
- Ran 232 tests → all passed
- Committed as standalone PR before continuing feature work

---

**End of RAILS_SPECIFICS.md**
