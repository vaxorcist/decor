# RAILS_SPECIFICS.md
# version 2.4
# Session 37: Added "CSV::Table — Never Use #to_a When You Need Row Indexing" section.
#   CSV::Table#to_a returns plain arrays; iterating with map/each yields CSV::Row objects
#   that support string-key indexing. Real example: OwnerExportServiceTest Session 37.
#   Without this option, blank form rows (user adds a member row but leaves it
#   empty) attempt to build child records with missing required attributes,
#   producing confusing validation errors before the parent-level validator runs.
# decor/docs/claude/RAILS_SPECIFICS.md
# Added (Session 13): Fixture Ownership section — derive counts from data;
#   use a neutral owner for test-support fixtures to avoid breaking hardcoded
#   count assertions in unrelated test files.
# Session 19: Task-type file checklists added — five task types with file lists
#   and reasoning prompts to eliminate incremental file-requesting.
# Added (Session 15): SQLite table recreation — always use explicit column names
#   in INSERT/SELECT, never SELECT *. Positional copy fails silently when
#   schema.rb column order differs from SQLite storage order.

**Ruby on Rails Specific Patterns and Best Practices**

**Last Updated:** March 4, 2026 (v2.1: explicit column names rule in SQLite table recreation; Session 15)

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
- [ ] **Verify the correct authentication before_action for every new controller**
      Check what auth guard other controllers use and apply the same.
      In DECOR: `before_action :require_login` for any owner-facing controller,
      `before_action :require_admin` for admin controllers.
      Omitting this leaves all actions publicly accessible — a security hole.
      Real example (Session 10): DataTransfersController shipped without
      `require_login`; all three actions were reachable without login.
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

## Fixture Ownership — Derive Counts from Data; Use Neutral Owners for Support Fixtures

### General Rule

**Never hardcode a count assertion on fixture-owned records.**
The general principle is in PROGRAMMING_GENERAL.md — Derive Test Assertions from
Data, Not Constants. This section covers the Rails/fixture-specific consequence.

When a hardcoded count assertion exists anywhere in the test suite, adding any
new fixture to that owner breaks the count — often in a completely unrelated test
file, with no obvious connection to the new fixture.

**Bad:**
```ruby
assert_equal 2, @bob.computers.count   # breaks the moment a 3rd fixture is added to bob
```

**Good:**
```ruby
bob_computer_ids = @bob.computers.pluck(:id)
assert bob_computer_ids.any?, "Bob must have at least one computer for this test"
# ... perform action ...
bob_computer_ids.each do |id|
  assert_nil Computer.find_by(id: id), "Computer #{id} should have been deleted"
end
```

### Neutral Owner Pattern

When hardcoded counts exist in the test suite and cannot be immediately removed,
use a **dedicated neutral owner** for any new test-support fixtures — an owner
whose record counts no test ever asserts.

In decor: `owners(:three)` / charlie is this neutral owner.

- ✅ Assign all new test-support fixtures (enum test records, edge case records,
  etc.) to the neutral owner
- ✅ Document the intent clearly in `owners.yml`
- ❌ Never add hardcoded count assertions for the neutral owner

**Grep check before assigning a fixture to an existing owner:**
```bash
# Verify no hardcoded count assertions target this owner before adding a fixture
grep -rn "\.count" decor/test/ | grep -i "alice\|bob\|owners(:one)\|owners(:two)"
```

If any hardcoded counts exist → use the neutral owner instead.

**Real example (Session 13, March 3, 2026):**
`dec_unibus_router` (appliance enum fixture) was first assigned to alice (owners(:one))
→ broke `OwnerExportServiceTest` (computer count 3 ≠ 2). Moved to bob (owners(:two))
→ broke `OwnersControllerDestroyTest` (computer count 3 ≠ 2). Both alice and bob had
independent hardcoded count assertions in different test files. Fix: added
`three` (charlie) as a neutral owner. Longer-term fix: replace all hardcoded count
assertions with data-derived assertions (see PROGRAMMING_GENERAL.md).

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

Use `paginate` helper from geared_pagination gem.
See existing controllers (computers, components, owners) for the established pattern.

---

## Rails Commands Reference

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
3. `INSERT INTO new_name (col1, col2, ...) SELECT col1, col2, ... FROM old_name`
   — ALWAYS use explicit column names on both sides; never `SELECT *`
     (see "SQLite Table Recreation — Always Use Explicit Column Names" below)
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

## File Uploads in Integration Tests — Use Rack::Test::UploadedFile

**When writing integration tests that upload files via `post params:`:**

Use `Rack::Test::UploadedFile`, NOT `ActionDispatch::Http::UploadedFile`.

**Wrong — ActionDispatch::Http::UploadedFile gets stringified in the HTTP layer:**
```ruby
# This causes NoMethodError: undefined method 'content_type' for an instance of String
upload = ActionDispatch::Http::UploadedFile.new(
  tempfile:  tempfile,
  filename:  "file.csv",
  type:      "text/csv"
)
post path, params: { file: upload }  # upload arrives as a String in the controller
```

**Correct — Rack::Test::UploadedFile survives the integration test HTTP layer:**
```ruby
tempfile = Tempfile.new(["prefix", ".csv"])
tempfile.write(csv_content)
tempfile.rewind
tempfile.close

upload = Rack::Test::UploadedFile.new(tempfile.path, "text/csv", false,
                                       original_filename: "file.csv")
post path, params: { file: upload }  # controller receives a proper UploadedFile
```

**Why the difference:**
Integration tests encode params through the full Rack/HTTP stack. `ActionDispatch::Http::UploadedFile`
is not designed to survive that encoding and gets collapsed to its string representation.
`Rack::Test::UploadedFile` is designed for exactly this context and maintains its interface
(`.path`, `.content_type`, `.original_filename`, `.size`) through the test request.

**Note:** This does NOT affect unit/service tests that call service objects directly —
those pass the object without HTTP encoding, so either class works. The issue is
specific to `ActionDispatch::IntegrationTest` using `post`/`patch` etc.

**Real example (Session 10, February 28, 2026):**
`DataTransfersControllerTest` — three import tests failed with
`NoMethodError: undefined method 'content_type' for an instance of String`
because `ActionDispatch::Http::UploadedFile` was used. Switching to
`Rack::Test::UploadedFile.new(path, content_type)` fixed all three.

---

## multi-table ORDER BY — Wrap in Arel.sql()

**Rails rejects raw ORDER BY strings that reference joined table columns.**

Any `.order()` argument containing a dot (`table.column`), a SQL keyword
(`NULLS LAST`, `ASC`, `DESC` with spaces), or anything that is not a simple
attribute name will raise `ActiveRecord::UnknownAttributeReference` with:

> Dangerous query method called with non-attribute argument(s): "..."

**Wrong — bare string causes UnknownAttributeReference:**
```ruby
.order("computer_models.name ASC NULLS LAST, computers.serial_number ASC")
```

**Correct — wrap in Arel.sql() to declare the string as developer-controlled:**
```ruby
.order(Arel.sql("computer_models.name ASC NULLS LAST, computers.serial_number ASC"))
```

**When Arel.sql() is required:**
- Multi-table references: `"joined_table.column_name"`
- `NULLS LAST` / `NULLS FIRST`
- Any expression that is not a bare column symbol (`:created_at`) or hash (`created_at: :asc`)

**When it is NOT required:**
- `.order(:column_name)` — symbol form, always safe
- `.order(column_name: :asc)` — hash form, always safe

**Safety note:** `Arel.sql()` is an explicit whitelist declaration.
Only wrap strings that are fully hardcoded in the application — NEVER wrap
user-supplied input (request params, model attributes) in `Arel.sql()`.

**Real example (Session 11, March 1, 2026):**
`OwnersController#show` raised `UnknownAttributeReference` on the component
ordering query. Fixed by wrapping both ORDER BY strings in `Arel.sql()`.


---

## Directory Tree Maintenance — MANDATORY

The `## Directory Tree` section in `DECOR_PROJECT.md` is the authoritative
record of the project's file structure. It must be kept current.

### When to update

Update `DECOR_PROJECT.md` (Directory Tree + Key file versions table) whenever:
- A new file is created (migration, controller, view, helper, JS controller, test, etc.)
- A file is deleted
- A file's version number changes

### How to update

1. Claude updates the **Key file versions** table in `DECOR_PROJECT.md` inline
   (adding new rows, bumping version numbers) after every file change.
2. The full tree block is replaced only when the user re-runs the tree command
   and uploads a fresh `decor_tree.txt`. This happens:
   - At the start of each new session (recommended)
   - After any session that adds or removes files

### Tree command (run from parent of decor/)

```bash
tree decor/ \
  -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" \
  --dirsfirst -F --prune -L 6 \
  > decor_tree.txt
```

Upload `decor_tree.txt` and Claude will replace the tree block in
`DECOR_PROJECT.md` and present the updated file for download.

### What Claude must NOT do

- ❌ Ask for files that Claude itself created or modified in the current session
- ❌ Leave the Key file versions table stale after creating/modifying files
- ❌ Omit new files from the versions table

**Real example (Session 14, March 3, 2026):**
The tree command and upload procedure was established this session. From Session 15
onwards, the user will upload a fresh `decor_tree.txt` at session start; Claude
will replace the tree block and update the versions table in `DECOR_PROJECT.md`.


---

## Enum Assertions in Tests — Use String or Predicate, Not Integer

**Rails enum accessors always return the mapped string label, never the raw integer.**
This applies to ALL access methods: `.device_type`, `read_attribute(:device_type)`,
and `model[:device_type]` — all return `"computer"` or `"appliance"`, not `0` or `1`.

**Wrong — all three forms return the string, not the integer:**
```ruby
assert_equal 0, model.read_attribute(:device_type)   # returns "computer"
assert_equal 0, model[:device_type]                  # returns "computer"
assert_equal 0, model.device_type                    # returns "computer"
```

**Correct — two acceptable forms:**
```ruby
# Form 1: assert against the string label (explicit, readable)
assert_equal "computer", model.device_type
assert_equal "appliance", created.device_type

# Form 2: use the generated predicate (most idiomatic)
assert model.device_type_computer?
assert_not model.device_type_appliance?
```

**When to use which form:**
- Predicate form (`device_type_computer?`) — preferred for boolean pass/fail assertions
- String form (`assert_equal "computer", model.device_type`) — preferred when the
  test is specifically verifying that the correct value was stamped (e.g. create action)

**To read the raw integer (rare — only if you genuinely need the DB value):**
```ruby
model.read_attribute_before_type_cast(:device_type)   # returns 0 or 1
```

**Real example (Session 14, March 3, 2026):**
`computer_model_test.rb` and `computer_models_controller_test.rb` both used
`read_attribute(:device_type)` and `model[:device_type]` expecting integers.
Both returned strings. Three test failures across two rounds of fixes.
The correct pattern was already present in `computer_test.rb` v1.4 (Session 13) —
reading that file before writing the parallel test would have prevented all failures.

---

## SQLite Table Recreation — Always Use Explicit Column Names

**RULE: Never use `SELECT *` in the INSERT step of a SQLite table recreation
migration. Always name every column explicitly on both sides.**

SQLite stores columns in the order they were added by successive migrations.
`schema.rb` lists columns alphabetically. These two orderings frequently differ.
`SELECT *` returns columns in storage order; if the new table definition uses a
different order, data lands in the wrong columns — silently, with no warning
unless a NOT NULL or type constraint happens to catch it.

**Wrong — positional copy, order mismatch causes silent data corruption:**
```ruby
execute "INSERT INTO components_new SELECT * FROM components"
```

**Correct — name-based copy, immune to column order differences:**
```ruby
COLUMNS = %w[id component_category component_condition_id component_type_id
             computer_id created_at description history order_number
             owner_id serial_number updated_at].freeze

col_list = COLUMNS.join(", ")
execute "INSERT INTO components_new (#{col_list}) SELECT #{col_list} FROM components"
```

The COLUMNS constant also serves as self-documentation of the table's structure
at migration time, and makes the `down` method a straightforward copy of `up`.

**Real example (Session 15, March 4, 2026):**
`AddCascadeDeleteComponentsComputer` (v1.0) used `SELECT *`. The INSERT failed
with `NOT NULL constraint failed: components_new.component_type_id` even though
the source data had no NULL values — the data was correct but landed in the wrong
column due to storage-order vs. schema.rb-order mismatch. Fixed in v1.1 by using
explicit column names on both sides.

---


---

## Nested Attributes — Always Use reject_if: :all_blank

**When using `accepts_nested_attributes_for` with a form that lets the user add
rows dynamically, always include `reject_if: :all_blank`.**

Without it, a blank row submitted by the user (e.g. an "Add member" dropdown
left unselected) attempts to build a child record with all attributes missing.
This fails the child model's `belongs_to` presence validation before the
parent-level validator (e.g. `minimum_two_members`) even runs — producing a
confusing error message that points at the wrong thing.

**Wrong — blank rows cause misleading belongs_to presence errors:**
```ruby
accepts_nested_attributes_for :connection_members, allow_destroy: true
```

**Correct — blank rows are silently discarded before validation:**
```ruby
accepts_nested_attributes_for :connection_members,
                               allow_destroy: true,
                               reject_if:     :all_blank
```

**What `:all_blank` does:** Rails calls the check on each nested-attributes hash
before building the child object. If every value in the hash is blank (empty
string, nil, or "0" for `_destroy`), the hash is discarded entirely — no child
record is built, no validation runs.

**When `:all_blank` is NOT appropriate:**
- When every attribute on the child is optional and a fully-blank record is
  intentionally valid. This is rare — if a child record can be blank, question
  whether it should exist at all.
- When you need finer-grained rejection logic — use a proc instead:
  `reject_if: ->(attrs) { attrs[:computer_id].blank? }`

**Real example (Session 36, March 19, 2026):**
`ConnectionGroup` accepted nested `connection_members`. Without `reject_if: :all_blank`,
a blank dropdown row submitted the hash `{ computer_id: "" }`, which tried to build
a `ConnectionMember` with no `computer_id`, failing `belongs_to :computer` presence
validation. The error shown was "Computer must exist" — not "minimum 2 members" —
which was confusing because the blank row was not intentional. Adding
`reject_if: :all_blank` silently discarded the empty row before any validation ran.

---

## Task-Type File Checklists

These checklists answer "which files do I need before starting?" for the most
common task types in this project. They encode the reasoning that should happen
before any file is requested — not a full dependency map, but the key chains
that are easy to miss.

### Table Column Changes (reorder / add / remove columns)

A column change touches header + row in lock-step. Sub-tables on other pages
must be found by asking "where else is this model displayed as a table?"

```
Always need:
  [ ] The index view                    app/views/MODEL/index.html.erb
  [ ] The row partial                   app/views/MODEL/_MODEL.html.erb
  [ ] Turbo stream (check: does it      app/views/MODEL/index.turbo_stream.erb
      render the partial? usually no
      header change needed)

Ask: "Is this model also shown as a sub-table on another page?"
  Components appear in:
    [ ] app/views/owners/show.html.erb          (Components section)
    [ ] app/views/computers/_form.html.erb       (Computer's Components section)
  Computers appear in:
    [ ] app/views/owners/show.html.erb          (Computers + Appliances sections)

Ask: "Does edit.html.erb render _form.html.erb?"
  If yes → _form.html.erb contains the sub-table, NOT edit.html.erb itself.
  Always get _form.html.erb, not edit.html.erb, for sub-table changes.
```

### Sort / Filter Changes (add or modify sort options or filter selectors)

Sort and filter options span exactly three files in this project — no exceptions.

```
Always need (all three):
  [ ] app/views/MODEL/_filters.html.erb    — the filter/sort UI selector
  [ ] app/helpers/MODEL_helper.rb          — sort/filter option constants + helpers
  [ ] app/controllers/MODEL_controller.rb  — the case/when sort logic

Key patterns to check in the controller:
  - Does the new sort reference a joined table?  → need .joins(:assoc)
  - Does ORDER BY contain a dot or SQL keyword?  → need Arel.sql()
  - Does it reference the model's own column?    → no join; Arel.sql() only if NULLS LAST
```

### Controller Action Changes (new action, redirect logic, flash messages, params)

```
Always need:
  [ ] app/controllers/MODEL_controller.rb
  [ ] test/controllers/MODEL_controller_test.rb  (existing tests to avoid breaking)
  [ ] test/fixtures/MODELs.yml                   (to know available test data)

If the action renders a view:
  [ ] app/views/MODEL/ACTION.html.erb

If the action involves a form (create/update):
  [ ] app/views/MODEL/_form.html.erb             (strong params must match form fields)

If auth behaviour is changing:
  [ ] app/controllers/concerns/authentication.rb (check before_action names)
```

### Model / Association Changes (new field, rename, validation, enum)

```
Always need:
  [ ] app/models/MODEL.rb
  [ ] test/models/MODEL_test.rb                  (existing tests to avoid breaking)
  [ ] test/fixtures/MODELs.yml                   (values must satisfy new validations)

Run grep sweep BEFORE writing any files:
  grep -rn ".OLD_NAME"         app/        (accessor used in views/helpers/controllers)
  grep -rn "OldClassName"      app/ test/  (class name references)
  grep -rn ":OLD_NAME"         app/ test/  (symbol form in params, scopes, fixtures)
  grep -rn "old_name_id"       app/        (FK column references)

If adding a migration:
  [ ] db/schema.rb (read after migration to verify result)
  [ ] Check for SQLite limitations (ALTER TABLE, CHECK constraints, explicit column
      names in INSERT/SELECT) — see SQLite sections in this file.
```

### New Page / Route (new controller action + view + navigation entry)

```
Always need:
  [ ] config/routes.rb
  [ ] The controller file (existing or new)
  [ ] app/views/layouts/application.html.erb     (public nav)
        OR app/views/layouts/admin.html.erb      (admin nav)
        OR app/views/common/_navigation.html.erb (shared nav partial)

If it is a public page requiring no login:
  [ ] Verify no before_action :require_login covers the new action
  [ ] Add to navigation partial (leftmost = most prominent)

If it is an admin page:
  [ ] app/controllers/admin/base_controller.rb   (check inherited auth guard)
  [ ] app/views/layouts/admin.html.erb           (dropdown menu)
```

---

## CSV::Table — Never Use #to_a When You Need Row Indexing

**`CSV::Table#to_a` returns plain arrays, not `CSV::Row` objects.**

When you call `csv_table.to_a`, Ruby returns an array of plain arrays —
the first element is the headers array, the rest are value arrays. Plain
arrays cannot be indexed by a string column name; attempting it raises:

```
TypeError: no implicit conversion of String into Integer
```

**Wrong — #to_a produces plain arrays:**
```ruby
rows = @csv.to_a
sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }
# → TypeError: no implicit conversion of String into Integer
```

**Correct — iterate with map/select/each to get CSV::Row objects:**
```ruby
rows = @csv.map { |r| r }   # or @csv.each.to_a — both yield CSV::Row objects
sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }
# → works correctly
```

**When this matters:**
- Any time you need to collect `CSV::Row` objects into a plain array for
  subsequent indexed access (e.g. `rows[i..]` slicing, position-based lookup).
- Parsing CSV in tests that iterate and then slice by position.
- The normal `@csv.select { }`, `@csv.find { }`, `@csv.each { }` patterns
  already yield `CSV::Row` objects and are not affected.

**Real example (Session 37, March 23, 2026):**
`OwnerExportServiceTest` — two tests called `@csv.to_a` to collect rows for
position-based sentinel detection. Both failed with `TypeError` on the first
`r["record_type"]` access. Fixed by replacing `.to_a` with `.map { |r| r }`.

---

**End of RAILS_SPECIFICS.md**
