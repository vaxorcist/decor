# RAILS_SPECIFICS.md
# version 1.6
# Added: Rails-specific Pre-Implementation Verification section (moved from COMMON_BEHAVIOR.md)
# Added: Association rename grep sweep rule (lesson from Session 7)
# Added: VARCHAR/TEXT cross-reference note for SQLite CHECK constraint requirement
# Added: ERB + whitespace-pre-wrap literal whitespace gotcha (lesson from Session 9)

**Ruby on Rails Specific Patterns and Best Practices**

**Last Updated:** February 25, 2026 (v1.5: Rails pre-implementation verification moved here from COMMON_BEHAVIOR.md; grep sweep rule; VARCHAR/TEXT note)

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

**Rails 6.0+ (2019):**
- `assigns()` completely removed - will cause NoMethodError
- Must use response body parsing or status codes

**Rails 7.0+ (2021):**
- Hotwire/Turbo introduced
- Modern testing focuses on behavior, not internals

**Rails 8.0+ (2024):**
- No access to controller instance variables in tests
- Use `assert_response :unprocessable_entity` to verify validation failures
- Stimulus/Turbo patterns standard

### Common Compatibility Issues

**Don't Use (Removed in Rails 6+):**
```ruby
# BAD - Will fail in Rails 6+
assert_not assigns(:user).valid?  # NoMethodError: assigns
```

**Use Instead (Rails 6+):**
```ruby
# GOOD - Works in all modern Rails
assert_response :unprocessable_entity
```

---

## Pre-Implementation Verification — Rails (MANDATORY)

This section elaborates on the generic checklist in COMMON_BEHAVIOR.md with
Rails-specific requirements. Follow these BEFORE writing any code.

### For Writing Tests:
- [ ] **Request and review all relevant fixture files**
      Never assume fixture labels or data values.
      Request: `test/fixtures/[model]s.yml` for ALL referenced models.
- [ ] **Verify exact fixture references**
      Example: `computer_models(:pdp11_70)` not guessed `(:pdp11)`
      Example: verify Bob has 2 computers, not assumed 0
- [ ] **Review existing test patterns**
      Check similar test files for established patterns.
      Use centralized test helpers (authentication, constants).
- [ ] **Check for existing test files that will be affected**
      A rename or refactor may break test files you haven't seen yet.
      Always ask: "Are there test files for this model/controller?"

### For Implementing Features:
- [ ] **Have all controller, model, view, helper, and partial files involved**
      Not just the primary file — also related concerns, helpers, and partials.
- [ ] **Have seen similar working examples in this codebase**
      Don't invent patterns — follow established ones.
      Check existing code for styling, structure, naming.
- [ ] **Understand the project's naming and styling conventions**
      Naming conventions, CSS classes, button styles, auth patterns.
- [ ] **Run a grep sweep for ALL affected accessors/methods BEFORE writing files**
      See "Association Rename Grep Sweep" section below.

### Why This Matters — Real Examples:

**Fixture assumption failure (prior session):**
- ❌ Assumed fixture name `computer_models(:pdp11)` → Should be `(:pdp11_70)`
- ❌ Assumed `bob.computers.count = 0` → Actually = 2
- ❌ Caused 5 test failures that were 100% preventable

**Missing test file failure (Session 7):**
- ❌ Renamed `Condition` → `ComputerCondition` without knowing `condition_test.rb`
  and `conditions_controller_test.rb` existed
- ❌ Caused 24 test errors that were 100% preventable
- ✅ Fix: always ask "Are there test files for this model/controller?"

---

## Association Rename Grep Sweep — MANDATORY

**When renaming a model, table, or association, BEFORE writing any files:**

Run a grep across the ENTIRE project for the old name in all contexts:

```bash
# Old association accessor in views, helpers, controllers
grep -rn "\.old_name" decor/app/

# Old class name in Ruby files
grep -rn "OldClassName" decor/app/ decor/test/

# Old fixture helper in tests
grep -rn "old_names(:" decor/test/

# Old column name in params, where clauses, strong params
grep -rn "old_name_id" decor/app/
```

Fix ALL occurrences found before running the test suite.

**Real example (Session 7, February 25, 2026):**
- Renamed `computer.condition` → `computer.computer_condition` in models and primary views
- Did not grep `decor/app/views/` for remaining `.condition` occurrences
- Result: 3 separate runtime errors in `_computer.html.erb`, `owners/show.html.erb`,
  and `computers/show.html.erb` — each requiring a separate upload-fix-test cycle
- Fix: one `grep -rn "\.condition" decor/app/views/` before starting would have
  revealed all occurrences at once

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
end
```

**test/test_helper.rb:**
```ruby
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

### Test Data Constants

**Centralized:**
```ruby
# test/support/test_constants.rb
module TestConstants
  TEST_PASSWORD_VALID = "password12345".freeze
  TEST_EMAIL_VALID = "test@example.com".freeze
end
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
  items = Model.includes(:associations).where(...)
  paginate items
end
```

### Views Access Data via @page.records
```erb
<% @page.records.each do |item| %>
  <%= render "item", item: item %>
<% end %>
```

---

## Turbo Stream Pagination Pattern

### CRITICAL: ID Must Be on <tbody>

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

---

## Rails Git Workflow Commands

Steps 4–6 of the general git workflow (PROGRAMMING_GENERAL.md) for Rails projects:

```
Step 4: Run full test suite      bin/rails test

Step 5: Run lint (auto-fix)      bundle exec rubocop -A
        Verify clean             bundle exec rubocop

Step 6: Run security scan        bin/brakeman --no-pager
```

**Additional Rails rules:**
- ❌ NEVER run rubocop on `.erb` files — it cannot parse them
- ❌ NEVER check only changed files — CI checks entire project
- Use `bundle exec rubocop -f github` only when debugging CI failures

---

## SQLite — VARCHAR Length Enforcement

**VARCHAR length in SQLite is cosmetic only.** SQLite does not enforce VARCHAR(n)
at runtime. To actually restrict column length, a CHECK constraint is required
alongside the VARCHAR declaration:

```sql
user_name VARCHAR(15) CHECK(length(user_name) <= 15)
```

**In Rails migrations using raw SQL (required for SQLite table recreation):**
```ruby
execute <<~SQL
  CREATE TABLE owners_new (
    user_name VARCHAR(15),
    CHECK(length(user_name) <= 15)
  )
SQL
```

**Cross-reference:** The general rule (always use VARCHAR with length; ask before TEXT)
is in PROGRAMMING_GENERAL.md — Database Column Types section. This SQLite note
explains the implementation detail that makes the rule meaningful on this stack.

**Real example (Session 7, February 25, 2026):** All type-cleanup columns used
`VARCHAR(n) + CHECK(length(col) <= n)` to ensure actual enforcement, not just
documentation.

---

## SQLite Foreign Key Enforcement — MANDATORY for New Projects

### Why SQLite Does NOT Enforce FKs by Default

SQLite defines FK constraints in the schema but silently ignores them at runtime
unless explicitly enabled per connection.

**Rails 8.1 with the SQLite3 adapter does NOT enable FK enforcement automatically.**

### How to Enable FK Enforcement

Add `foreign_keys: true` to the `default:` section of `config/database.yml`.

```yaml
default: &default
  adapter: sqlite3
  foreign_keys: true        # ← Enables PRAGMA foreign_keys = ON per connection
```

### Pre-Enable Verification — CRITICAL

**Before enabling on an existing project**, verify no orphaned records exist:

```bash
sqlite3 storage/development.sqlite3 << 'EOF'
SELECT 'table_a → table_b' AS check_name, COUNT(*) AS orphaned_rows
FROM table_a WHERE fk_id IS NOT NULL
  AND fk_id NOT IN (SELECT id FROM table_b);
EOF
```

All counts must be 0. Verify production BEFORE deploying — not after.

### disable_ddl_transaction! Required for PRAGMA in Migrations

`PRAGMA foreign_keys = OFF/ON` is a no-op inside a transaction. Rails wraps
migrations in transactions by default. Use `disable_ddl_transaction!` in any
migration that needs to temporarily suspend FK enforcement:

```ruby
class MyMigration < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "PRAGMA foreign_keys = OFF"
    # ... table operations ...
    execute "PRAGMA foreign_keys = ON"
  end
end
```

---

## SQLite ALTER TABLE Limitations

Cannot add named CHECK constraints to existing columns — requires full table
recreation. Rails handles recreation automatically via raw SQL in migrations.
Use backup-in-migration pattern for safety.

**Migration pattern for SQLite table recreation:**
1. `PRAGMA foreign_keys = OFF`
2. `CREATE TABLE new_name (...)`
3. `INSERT INTO new_name SELECT ... FROM old_name`
4. `DROP TABLE old_name`
5. `ALTER TABLE new_name RENAME TO old_name`
6. Recreate all indexes
7. `PRAGMA foreign_keys = ON`

---

## Rails Test Class — Required Inclusions

`ActionMailer::TestHelper` (provides `assert_emails`, `assert_no_emails`):
- ✅ Included automatically in: `ActionMailer::TestCase`
- ❌ NOT included in: `ActiveJob::TestCase`, `ActiveSupport::TestCase`, `ActionDispatch::IntegrationTest`
- Fix: `include ActionMailer::TestHelper` at the top of the test class

---

## Rails Test Helper — save! vs create! with Callbacks

**`save!(validate: false)` skips `before_validation` callbacks entirely.**

**Wrong — skips ALL before_validation callbacks:**
```ruby
record = Model.new(email: "x@example.com")
record.save!(validate: false)  # before_validation never runs
```

**Correct — use create! then override with update_columns:**
```ruby
record = Model.create!(email: "x@example.com")  # all callbacks run normally
record.update_columns(sent_at: 21.days.ago)      # override timestamp directly in DB
```

---

## Which File Types Appear in the Context Window

Only these file types render as readable text when uploaded:
- `.md`, `.txt`, `.html`, `.csv` (as text)
- `.yml`, `.yaml` (as text — these DO render in context window)
- `.png` (as image)
- `.pdf` (as image)

### ERB and other code files — ALWAYS use the view tool

**ERB files (`.erb`) do NOT appear in the context window**, even when uploaded.
The same applies to `.rb`, `.js`, and all other code file types.

**RULE: When a user uploads any `.erb`, `.rb`, or other non-Markdown, non-YAML file,
ALWAYS use the `view` tool immediately — do NOT assume the content is visible.**

---

## ERB + whitespace-pre-wrap — Literal Whitespace Gotcha

`whitespace-pre-wrap` (and CSS `white-space: pre-wrap`) renders ALL whitespace
literally — including the newline and indentation that ERB templating adds
between a tag and its `<%= %>` content block.

**Symptom:** text appears indented from the left even though no alignment
CSS is set. Adding `text-align: left` has no effect because the cause is
rendered whitespace, not CSS alignment.

**Wrong (indentation rendered as visible leading space):**
```erb
<dd class="whitespace-pre-wrap">
  <%= record.description %>
</dd>
```

**Correct (no whitespace between tag and content):**
```erb
<dd class="whitespace-pre-wrap"><%= record.description %></dd>
```

**Rule:** whenever `whitespace-pre-wrap` is used on an element whose content
comes from an ERB tag, the `<%= %>` tag MUST be on the same line as the
opening HTML tag — no newline, no leading spaces between them.

**Real example (Session 9, February 27, 2026):**
`components/show.html.erb` Description box — two iterations spent adding
`text-align: left` and `vertical-align: top` inline styles with no effect.
Root cause was the newline + indentation between `<dd>` and `<%= %>` being
rendered literally by `whitespace-pre-wrap`. Fixed by collapsing to one line.

---

**End of RAILS_SPECIFICS.md**
