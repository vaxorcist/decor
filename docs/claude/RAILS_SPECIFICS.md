# decor/docs/claude/RAILS_SPECIFICS.md
# version 4.1
# Session 93: Added a one-paragraph reinforcement to "Single Source of
#   Truth Refactors" — data_transfers_controller.rb and
#   admin/data_transfers_controller.rb independently missed the same new
#   OwnerImportService counter (storage_location_count) a second time,
#   the first being Session 48's connection_group_count/software_item_count
#   omission. No new rule; existing rule reinforced.
# Session 84 (Reorg Session 3 of 4, plan agreed Session 83): Topic-split
#   this file. It had grown to ~54,000 tokens on its own and mixed core
#   Rails/ActiveRecord rules with view/CSS/Stimulus rules, test/Capybara/CI
#   rules, and mailer/email rules that are each only relevant to a subset
#   of sessions. Split into four files:
#     RAILS_SPECIFICS.md   (this file) — core Rails/Ruby/ActiveRecord/
#       SQLite/routing rules + this topic index. Always loaded (mandatory
#       session-start read, unchanged).
#     RAILS_UI.md          — Tailwind/nav/z-index/CSS grid/Tom Select/ERB-
#       comment/Turbo-disabling/UI-rename rules. Load for view/CSS/Stimulus
#       work.
#     RAILS_TESTING.md     — fixture/test-helper/Capybara/system-test/CI
#       rules. Load before writing ANY test file.
#     RAILS_MISC.md        — email/mailer rules (Gmail, old clients,
#       before_validation vs before_save, mailer view paths, deliver_now vs
#       deliver_later). Load for mailer work only.
#   Every rule's lengthy "why this rule exists" incident narrative was
#   trimmed to one line across all four files — the rule statement and code
#   examples (load-bearing for Pre-Implementation Verification) are
#   unchanged. Full original narrative for every rule remains recoverable
#   via git history of this file prior to the split.
#   ALSO RESOLVED (flagged as a cross-doc issue at the end of Reorg 2, this
#   same session): the old "Directory Tree Maintenance — MANDATORY" section
#   instructed future sessions to keep DECOR_PROJECT.md's "## Directory
#   Tree" section current — but Reorg 2 deleted that section (redundant
#   with git log + file version headers). That section is REMOVED from
#   this file rather than repointed; DECOR_PROJECT.md's Session 84 note
#   already covers what replaces it (`tree` command run ad hoc, `git log`,
#   each file's own version-header comment).
# Sessions prior to 84: see git history of this file (pre-split) or
#   SESSION_HISTORY_ARCHIVE.md for full per-session narrative on every rule
#   below.

**Ruby on Rails Specific Patterns and Best Practices — Core**

**Last Updated:** July 30, 2026 (v4.0: topic-split into this core file +
  RAILS_UI.md + RAILS_TESTING.md + RAILS_MISC.md; Session 84)

---

## Topic Index — Which File Has What

**This file (RAILS_SPECIFICS.md) — always read at session start:**
Rails version compatibility, Pre-Implementation Verification (Rails),
controller action patterns (`render` synchronicity, `before_action`
scoping), routing (`namespace`, collection routes, `Arel.sql`), enum
`read_attribute` gotcha, `insert_all`, Single Source of Truth Refactors,
Geared Pagination internals, SQLite (VARCHAR/FK/ALTER TABLE/table
recreation), nested attributes, Ruby/Rails file-naming conventions, which
file types appear in context, task-type file checklists, CSV::Table,
Rails commands reference.

**RAILS_UI.md — load for view/CSS/Stimulus/nav work:** Nav logo centering,
sticky-header/dropdown z-index ties, CSS grid navbar overflow, Tailwind
rebuild reminder, Tom Select `sortField`, ERB comment gotcha,
`whitespace-pre-wrap` gotcha, `data-turbo="false"` gotcha, UI renames
(auto-generated Rails strings).

**RAILS_TESTING.md — load before writing ANY test file:** Fixture
ownership / neutral owner pattern, association-rename grep sweep,
centralized test helpers, CI security checks (bundle-audit vs Brakeman),
`gh run view` run-ID requirement, required test-class inclusions, NOT NULL
boolean PATCH params, switching users in tests, `save!` vs `create!`,
file uploads in integration tests, `assert_body_includes`, enum test
assertions, and every System Tests / Capybara rule.

**RAILS_MISC.md — load for mailer/email work:** Gmail `data:` URI
stripping, old-client image sizing, `before_validation` vs `before_save`,
mailer views directory convention, `deliver_now` vs `deliver_later`.

---

## Rails Version Compatibility - CRITICAL

**ALWAYS verify Rails version compatibility before implementing ANY Rails-specific code.**

1. Check project documentation (`DECOR_PROJECT.md`) or `Gemfile.lock` for
   the exact Rails version.
2. Verify the feature/method exists in that version.
3. Check existing project files for established patterns.

**Current DECOR project:** Rails 8.1.

**Rails 8.0+ (2024):** no access to controller instance variables in
tests — use `assert_response :unprocessable_entity` to verify validation
failures, not `assigns()` (removed entirely in Rails 6+).

```ruby
# BAD — Rails 6+: NoMethodError
assert_not assigns(:user).valid?

# GOOD
assert_response :unprocessable_entity
```

---

## Pre-Implementation Verification — Rails (MANDATORY)

Elaborates on COMMON_BEHAVIOR.md's generic checklist. Follow BEFORE writing
any code.

### For Writing Tests:
- [ ] Request and review all relevant fixture files (`test/fixtures/[model]s.yml`).
- [ ] Verify exact fixture references (e.g. `computer_models(:pdp11_70)`, not guessed).
- [ ] Review existing test patterns in similar test files.
- [ ] Check for existing test files a rename/refactor may break.

### For Implementing Features:
- [ ] Have all controller, model, view, helper, and partial files involved
      — not just the primary file.
- [ ] Have seen similar working examples in this codebase — don't invent patterns.
- [ ] Understand the project's naming/styling/auth conventions.
- [ ] Verify the correct auth `before_action` for every new controller:
      `require_login` for owner-facing, `require_admin` for admin
      controllers. Omitting this leaves all actions publicly accessible.
      (Real example, Session 10: `DataTransfersController` shipped without
      `require_login`.)
- [ ] Run a grep sweep for ALL affected accessors/methods BEFORE writing
      files (see RAILS_TESTING.md "Association Rename Grep Sweep").

---

## Controller Actions — render Is Synchronous (MANDATORY)

**RULE: `render` renders the view immediately and synchronously. Any
instance variable assigned AFTER `render` is NOT visible to the template.**
Every iVar the template needs must be set BEFORE any render call, on every
code path that leads to that render.

```ruby
# Wrong — @owners set at the bottom, render fires first on failure paths
def send_newsletter
  if request.post?
    if params[:owner_id].blank?
      render :send_newsletter, status: :unprocessable_entity
      return                            # @owners never assigned
    end
  end
  @owners = Owner.order(:user_name)     # too late for the render above
end

# Correct — set iVars unconditionally at the top
def send_newsletter
  @owners = Owner.order(:user_name)     # set first, always available
  if request.post?
    # ... all render/redirect paths below can rely on @owners
  end
end
```

**Why:** `Admin::NewslettersController#send_newsletter` crashed with
`undefined method 'each' for nil` because `@owners` was assigned after two
POST failure `render` paths (Session 58).

---

## before_action :set_resource — Always Scope with only: (MANDATORY)

**RULE: Whenever a controller has `new`/`create` actions alongside a
`set_resource` callback, the callback MUST be scoped with `only:` to
exclude them.** `new`/`create` have no `:id` param — an unscoped callback
raises `ActiveRecord::RecordNotFound` before either action runs.

```ruby
# Wrong — crashes on new and create
before_action :set_software_item

# Correct
before_action :set_software_item, only: %i[show edit update destroy]
```

**Applied correctly (Session 80):** `storage_locations_controller.rb`'s
`set_storage_location` is scoped `only: %i[edit update destroy delete_confirm]`.

**Why:** `software_items_controller.rb` v1.0 shipped read-only (show only),
so the unscoped callback was harmless until `new`/`create` were about to be
added — caught in Pre-Implementation Verification, not at test time (Session 46).

---

## Named Routes (as:) Inside namespace — Still Prefixed (MANDATORY)

**RULE: A custom `as: :foo` route declared inside `namespace :admin do ...
end` is STILL prefixed `admin_` by Rails** — exactly like `resources`
routes in that namespace.

```ruby
# config/routes.rb
namespace :admin do
  post "component_order_numbers/revalidate", to: "component_order_numbers#revalidate",
                                              as: :revalidate_component_order_numbers
end
# generates: admin_revalidate_component_order_numbers_path
```

**How to avoid guessing:** `bin/rails routes | grep <as-value>` and read
the `Prefix` column — the actual helper is `Prefix + "_path"` PLUS the
namespace prefix Rails additionally prepends.

**Why:** two new `link_to` calls omitted the `admin_` prefix and raised
`NameError` at render time, even though the same file already had a
working example of the correct pattern two dropdowns away (Session 65).

---

## Collection Routes Nested in a Namespaced Resources Block — A SECOND, Different Prefix Shape (MANDATORY)

**RULE: A `collection do ... end` route nested inside a `resources` block
already inside `namespace :admin` produces a DIFFERENT prefix shape than
the custom `as:` case above.** The action name is PREPENDED to the
resource's own already-`admin_`-prefixed name, not appended after a bare
resource name.

```ruby
namespace :admin do
  resources :component_suggestions, only: %i[index new create edit update destroy] do
    collection do
      get :download_manual
    end
  end
end
# bin/rails routes | grep download_manual →
#   download_manual_admin_component_suggestions_path
```

**Rule in one sentence:** every new route helper — custom `as:` or a
`resources` collection/member route, namespaced or not — gets verified
with `bin/rails routes | grep <name>` before use in a view. There is no
shortcut that reliably predicts the helper name from the declaration alone.

**Why:** first guess was `admin_download_manual_component_suggestions_path`
(the wrong shape) — caught by running `bin/rails routes` before shipping,
not at render time (Session 67).

---

## Rails Enum — read_attribute Does Not Bypass Type-Casting; Use _before_type_cast for the Raw Value (MANDATORY)

**RULE: To read the raw underlying DB value of an enum-backed column, use
the auto-generated `<attribute>_before_type_cast` method — NOT
`read_attribute(:<attribute>)`,** which still goes through the custom enum
type and returns the SAME mapped value as the plain accessor.

```ruby
enum :manual, { added: "a", modified: "m" }, prefix: true
suggestion.manual                    # => "added"
suggestion.read_attribute(:manual)   # => "added"  — NOT "a"! Still type-cast.
suggestion.manual_before_type_cast   # => "a"       — correct
```

**When this matters:** CSV/data exports, debugging, raw SQL comparisons —
anywhere the mapped label would be misleading or incompatible with an
external format.

**Why:** `ManualComponentSuggestionsExportService` wrote "added" instead of
the intended raw "a" into a CSV column; a test comparing against the raw
string caught the mismatch (Session 67).

---

## Single Source of Truth Refactors — Audit ALL Consumers, Not Just the File Being Changed (MANDATORY)

**RULE: When a value or piece of logic duplicated across more than one
file is consolidated into a single source of truth, grep the ENTIRE
codebase for every other place that duplicated logic could also live** —
not just the file the current task happens to be touching. Fix all of them
in the same change, or explicitly flag the others as known-stale.

The danger is specifically that the un-updated copy can look completely
fine for a long time — it only breaks once a NEW case comes along that the
original coincidence doesn't cover.

```bash
# Before adding a new KNOWN_TEXTS-style entry anywhere, check for other
# hardcoded copies of the same concept:
grep -rn "title_for_key\|KNOWN_TEXTS" decor/app/
```

**Generalizes beyond constants** to any duplicated display logic — a field
shown on both an edit form and a read-only show page, a label computed the
same way in two view files, etc. Whenever a field is added or a display
rule changes on a model's form, grep that model's other view files
(`show.html.erb`, index partials, export templates) for the same
field/concept before considering the change complete.

**Why:** a Session 20 title-lookup refactor only updated the admin
controller, leaving the owner-facing controller's stale private copy
undetected for 53 sessions (Session 73); the same shape recurred when
`computers/show.html.erb` was never updated alongside three sessions' worth
of `_form.html.erb`-only fixes (Session 75).

**Reinforced (Session 93):** `data_transfers_controller.rb` and
`admin/data_transfers_controller.rb` both hardcode their own copy of
`build_success_message`'s count-field list (owner-facing vs. admin-facing
flash text, intentionally separate views of the same data). This is the
SECOND time a new `OwnerImportService` counter was added to one copy's
logic without the other — Session 48 (`connection_group_count`/
`software_item_count`) and now Session 93 (`storage_location_count`,
caught only via a manual browser check, not by any automated test). When a
piece of duplicated logic has recurred a second time in the same two
files, treat it as a standing project-specific risk, not a one-off miss:
grep both files by name whenever `OwnerImportService`'s result hash gains
a new key, rather than relying on remembering the duplication exists.

---

## Geared Pagination — paginate() Renders the Response Itself (MANDATORY)

**RULE: `paginate(scope)` is not a plain data-fetch call. It sets `@page`
(NOT an ivar named after the model) AND renders the response itself.**
Every ivar the view needs (`@page_title`, `@turbo_tbody_id`,
`@load_more_id`, `@index_path`) MUST be assigned BEFORE calling `paginate`
— it must be the last line of the action.

```ruby
# decor/app/controllers/concerns/pagination.rb (actual source)
module Pagination
  extend ActiveSupport::Concern
  def paginate(scope, **options)
    set_page_and_extract_portion_from(scope, **options)
    request.format = :html if @page.number == 1
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end
end
```

```ruby
# Correct controller pattern
def index
  @page_title     = "Component Suggestions"
  @turbo_tbody_id = "component_suggestions"
  @load_more_id   = "load_more_component_suggestions"
  @index_path     = admin_component_suggestions_path(query: params[:query].presence)
  scope = ComponentSuggestion.order(:order_number)
  scope = scope.order_number_contains(params[:query]) if params[:query].present?
  paginate(scope)   # last line — sets @page AND renders. Do not assign the return value.
end
```

This also explains the standing rule: `@page = paginate(scope)` overwrites
`@page` with the `respond_to` call's return value, not the Page object.

**Why:** a Session 67 draft assumed `paginate` set a model-named ivar and
could be called mid-action with rendering happening afterward — reading the
actual concern file corrected both assumptions before shipping.

---

## multi-table ORDER BY — Wrap in Arel.sql()

**Rails rejects raw ORDER BY strings referencing joined-table columns, SQL
keywords (`NULLS LAST`), or anything not a simple attribute name —**
raises `ActiveRecord::UnknownAttributeReference`.

```ruby
# Wrong
.order("computer_models.name ASC NULLS LAST, computers.serial_number ASC")

# Correct
.order(Arel.sql("computer_models.name ASC NULLS LAST, computers.serial_number ASC"))
```

**Safety note:** only wrap fully-hardcoded strings — NEVER wrap
user-supplied input in `Arel.sql()`.

---

## insert_all Bypasses Model Validations and Callbacks — Use unique_by: for Duplicate Handling

**RULE: `Model.insert_all(rows, unique_by: :column)` is a raw bulk SQL
INSERT — NO validations, NO callbacks run.** Correct for a disposable
mirror table whose source of truth lives outside the app.

```ruby
ActiveRecord::Base.transaction do
  ComponentSuggestion.delete_all
  rows.each_slice(1000) do |batch|
    ComponentSuggestion.insert_all(batch, unique_by: :order_number)
  end
end
```

**Tradeoffs:** no model validations run (fine for trusted upstream data,
not for user-submitted data); `unique_by:` requires an actual DB unique
index (`ON CONFLICT (column) DO NOTHING`); within one call/slice sharing an
index, the FIRST occurrence of a duplicate key wins; `created_at`/
`updated_at` are not auto-populated — supply explicitly if required.

**Why:** an O(n) per-row `exists?` check caused production timeouts at
~55,000 rows; rewriting around `delete_all` + `insert_all(unique_by:)`
eliminated the per-row round-trip (Session 67).

---

## SQLite — VARCHAR Length Enforcement

**VARCHAR length in SQLite is cosmetic only.** A CHECK constraint is
required to actually enforce it:

```sql
user_name VARCHAR(15) CHECK(length(user_name) <= 15)
```

```ruby
execute <<~SQL
  CREATE TABLE owners_new (
    user_name VARCHAR(15),
    CHECK(length(user_name) <= 15)
  )
SQL
```

---

## SQLite Foreign Key Enforcement — MANDATORY for New Projects

**Rails 8.1 with the SQLite3 adapter does NOT enable FK enforcement
automatically.** Add `foreign_keys: true` under `default:` in
`config/database.yml`.

**Before enabling on an existing project**, verify no orphaned records:
```bash
sqlite3 storage/development.sqlite3 << 'EOF'
SELECT 'table_a → table_b' AS check_name, COUNT(*) AS orphaned_rows
FROM table_a WHERE fk_id IS NOT NULL
  AND fk_id NOT IN (SELECT id FROM table_b);
EOF
```
All counts must be 0 — verify production BEFORE deploying.

`PRAGMA foreign_keys = OFF/ON` is a no-op inside a transaction — use
`disable_ddl_transaction!` in any migration that needs to suspend FK
enforcement:

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

## SQLite ALTER TABLE Limitations — Table Recreation Pattern

Cannot add named CHECK constraints to existing columns — requires full
table recreation:

1. `PRAGMA foreign_keys = OFF`
2. `CREATE TABLE new_name (...)`
3. `INSERT INTO new_name (col1, col2, ...) SELECT col1, col2, ... FROM
   old_name` — **ALWAYS explicit column names on both sides; never
   `SELECT *`**
4. `DROP TABLE old_name`
5. `ALTER TABLE new_name RENAME TO old_name`
6. Recreate all indexes
7. `PRAGMA foreign_keys = ON`

```ruby
COLUMNS = %w[id col1 col2 col3 created_at updated_at].freeze
col_list = COLUMNS.join(", ")
execute "INSERT INTO components_new (#{col_list}) SELECT #{col_list} FROM components"
```

---

## Nested Attributes — Always Use reject_if: :all_blank

```ruby
accepts_nested_attributes_for :connection_members,
                               allow_destroy: true,
                               reject_if:     :all_blank
```

---

## CSV::Table — Never Use #to_a When You Need Row Indexing

**`CSV::Table#to_a` returns plain arrays, not `CSV::Row` objects.**

```ruby
# Wrong — TypeError: no implicit conversion of String into Integer
rows = @csv.to_a
sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }

# Correct
rows = @csv.map { |r| r }
sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }
```

---

## Ruby Code Style

- **String literals:** always double quotes unless single quotes are
  needed to avoid escaping (Rubocop standard).
- **Whitespace:** no trailing whitespace; 2-space indentation; blank line
  at end of file.

---

## Rails File Naming Conventions

**Views:** `index.html.erb` NOT `computers_index.html.erb`;
`_computer.html.erb` NOT `_computers.html.erb`; `index.turbo_stream.erb`
for turbo stream responses.

**Models/Controllers:** singular model (`computer.rb`), plural controller
(`computers_controller.rb`).

---

## Which File Types Appear in the Context Window

Only these render as readable text/image when uploaded: `.md`, `.txt`,
`.html`, `.csv` (as text); `.yml`/`.yaml` (as text); `.png`/`.pdf` (as image).

**ERB and other code files do NOT appear in the context window**, even
when uploaded. Same for `.rb`, `.js`, and all other code files.

**RULE: when a user uploads any `.erb`, `.rb`, or other non-Markdown,
non-YAML file, ALWAYS use the `view` tool immediately — do NOT assume the
content is visible.**

---

## Rails Commands Reference

```
Step 4: Run full test suite      bin/rails test
Step 5: Run lint (auto-fix)      bundle exec rubocop -A
        Verify clean             bundle exec rubocop
Step 6: Run static security scan bin/brakeman --no-pager
Step 7: Run dependency CVE scan  bundle exec bundle-audit check --update
```

- ❌ NEVER run rubocop on `.erb` files — it cannot parse them.
- ❌ NEVER check only changed files — CI checks the entire project.
- Brakeman and bundle-audit are two separate CI checks — see
  RAILS_TESTING.md "CI Security Checks."

---

## Task-Type File Checklists

### Table Column Changes
```
[ ] app/views/MODEL/index.html.erb
[ ] app/views/MODEL/_MODEL.html.erb
[ ] app/views/MODEL/index.turbo_stream.erb (check if needed)
```

### Sort / Filter Changes
```
[ ] app/views/MODEL/_filters.html.erb
[ ] app/helpers/MODEL_helper.rb
[ ] app/controllers/MODEL_controller.rb
```

### Controller Action Changes
```
[ ] app/controllers/MODEL_controller.rb
[ ] test/controllers/MODEL_controller_test.rb
[ ] test/fixtures/MODELs.yml
```

### Model / Association Changes
```
[ ] app/models/MODEL.rb
[ ] test/models/MODEL_test.rb
[ ] test/fixtures/MODELs.yml
Run grep sweep BEFORE writing any files.
```

### New Page / Route
```
[ ] config/routes.rb
[ ] The controller file
[ ] app/views/layouts/application.html.erb (public nav)
      OR app/views/layouts/admin.html.erb  (admin nav)
```

### New Mailer
```
[ ] app/mailers/<mailer_name>_mailer.rb
[ ] app/views/mailers/<mailer_name>/<action>.html.erb  ← check existing path first! (RAILS_MISC.md)
[ ] test/mailers/<mailer_name>_mailer_test.rb
Use deliver_now for admin tools; deliver_later only for high-volume background sends.
```

---

**End of RAILS_SPECIFICS.md**
