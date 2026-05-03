# RAILS_SPECIFICS.md
# version 3.1
# Session 58: Five new rules from newsletter test failures.
#   1. render is synchronous — set all iVars before calling render.
#   2. NOT NULL columns must be explicit in PATCH test params (cast(nil) → nil).
#   3. ActionMailer::TestHelper — include explicitly in integration tests (expanded).
#   4. deliver_later in tests requires perform_enqueued_jobs (addendum).
#   5. Switching users in tests — delete session_path before login_as.
# Session 57: Three new rules from newsletter email rendering fixes.
#   1. Gmail strips data: URIs from img src — no workaround for the actual image;
#      style the <img> element for readable alt text instead.
#   2. img display:block misaligns alt text — use inline-block + vertical-align:middle
#      when the <img> sits beside inline text.
#   3. Old email clients (Firebird, Thunderbird, Outlook) ignore CSS height/width on
#      <img> — always add HTML height= and width= attributes alongside CSS.
# Session 56: Three new rules from the Newsletter feature.
#   1. before_validation vs before_save — if a field is generated for a presence
#      validation, use before_validation, not before_save. Validations run before
#      before_save; the presence check sees a blank field and rejects the record.
#   2. Mailer views directory — this project stores mailer views under
#      app/views/mailers/<mailer_name>/, NOT app/views/<mailer_name>/.\n#      Always check the existing mailer structure before creating new view directories.
#   3. deliver_later vs deliver_now for admin tools — deliver_later hands off to
#      ActiveJob; letter_opener never intercepts it and no browser tab opens.
#      For admin-initiated sends where synchronous delivery is fine, use deliver_now.
# Session 53: Two new rules from bugs found this session.
# Session 50: Added "Response Body Assertions — Use assert_body_includes" rule.
# Session 46: Added "before_action :set_resource — Always Scope with only:" section.
# Session 42: Fixed stale enum assertion example in "Enum Assertions in Tests" section.
# Session 37: Added "CSV::Table — Never Use #to_a When You Need Row Indexing" section.
# decor/docs/claude/RAILS_SPECIFICS.md
# Added (Session 13): Fixture Ownership section.
# Session 19: Task-type file checklists added.
# Added (Session 15): SQLite table recreation — always use explicit column names.

**Ruby on Rails Specific Patterns and Best Practices**

**Last Updated:** May 3, 2026 (v3.1: five new rules from Session 58 test failures)

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

## Email HTML — Gmail, Old Clients, and img Elements (MANDATORY)

### Rule 1 — Gmail strips data: URIs from img src

**Gmail unconditionally strips `data:` URIs from `<img src="...">`. This is a
hardcoded Gmail security policy. There is no workaround that makes the actual
image appear in Gmail.**

The permanent fix is to serve the image from a real HTTPS URL:
- Set `config.action_mailer.asset_host` in `production.rb` to the app's
  public hostname.
- Use `asset_url('logo.png')` in the mailer/partial — it returns an absolute
  URL in production (e.g. `https://decor.example.com/assets/logo-abc.png`)
  which Gmail DOES load.
- In development, `asset_url` returns a relative path; use a `data:` URI
  fallback for letter_opener preview.

**Interim workaround — style the alt text for readability:**
Gmail applies the `style=` attribute of an `<img>` to its alt text when the
`src` is stripped. Font properties on the `<img>` element itself are therefore
the only way to size and style the fallback text:

```erb
<img src="<%= LOGO_SRC %>"
     alt="DECOR"
     height="40" width="96"
     style="display: inline-block; vertical-align: middle; border: 0;
            height: 40px; width: 96px;
            font-size: 24px; font-family: Arial, Helvetica, sans-serif;
            color: #1c1917; font-weight: normal;">
```

**Why this rule exists (Session 57, May 2, 2026):**
The newsletter chrome partial embedded the logo as a `data:image/png;base64,...`
URI. Gmail stripped it silently. The `alt="DECOR"` text appeared at browser
default font size (~12px) while the adjacent "— DEC Owner's Registry" text was
24px. Adding font styles to the `<img>` matched both.

---

### Rule 2 — img display:block misaligns alt text beside inline text

**Never use `display: block` on an `<img>` that sits beside inline text in an
email header (or anywhere alt text must align vertically with adjacent text).**

`display: block` removes the element from the inline flow. When the `src` is
stripped by Gmail (or any client), the alt text renders as a block-level element,
which pushes it above or below the adjacent inline text instead of aligning with it.

**Wrong — alt text floats above adjacent text:**
```html
<img ... style="display: block; ...">
```

**Correct — alt text aligns with adjacent text:**
```html
<img ... style="display: inline-block; vertical-align: middle; ...">
```

`vertical-align: middle` centres the element (and its alt text) on the
line-height midpoint, matching the visual centre of any adjacent text node.

**Why this rule exists (Session 57, May 2, 2026):**
After adding font styles (Rule 1 above), "DECOR" was now 24px but sat noticeably
higher than "— DEC Owner's Registry". Changing `display: block` to
`display: inline-block; vertical-align: middle` aligned them correctly.

---

### Rule 3 — Old email clients ignore CSS height/width on img

**Old email clients (Firebird, Thunderbird, Outlook with Word renderer) read
the HTML `height=` and `width=` attributes for image sizing. They may ignore
CSS `style="height: Npx; width: Npx"` entirely.**

Always provide BOTH the CSS size AND the HTML attributes:

```html
<!-- CSS alone — ignored by old clients; image renders at full 680×282px -->
<img src="..." style="height: 40px; width: 96px;">

<!-- Correct — HTML attributes ensure old clients use the right size -->
<img src="..."
     height="40" width="96"
     style="height: 40px; width: 96px;">
```

Calculate the proportional width from the source image dimensions:
`width = round(target_height × (image_width / image_height))`

The DECOR logo is 680×282px. At height=40: width = round(40 × 680/282) = 96px.

**Why this rule exists (Session 57, May 2, 2026):**
Firebird rendered the logo at its native 680×282px — the entire email header
was dominated by an enormous logo. The CSS `style="height: 40px"` was present
but ignored. Adding `height="40" width="96"` as HTML attributes fixed it.

---

## before_validation vs before_save — Generated Fields That Are Also Validated (MANDATORY)

**RULE: If a model generates a field via a callback AND validates that field for
presence, use `before_validation` — NOT `before_save`.**

Rails callback order is:
  `before_validation` → `validate` → `before_save` → save

If the callback is `before_save`, the presence validation runs BEFORE the field
is generated. The validator sees a blank value and rejects the record — even
though the field would have been filled correctly moments later.

**Wrong — presence check fires before generate_html_body runs:**
```ruby
validates :html_body, presence: true
before_save :generate_html_body   # too late — validates runs first
```

**Correct:**
```ruby
validates :html_body, presence: true
before_validation :generate_html_body   # runs before validates
```

**When to use each:**
- `before_validation` — any callback that fills a field which is then validated.
- `before_save`       — callbacks that do NOT affect validated fields
                        (e.g. normalising a field that is not presence-validated,
                        setting a computed cache value).

**Why this rule exists (Session 56, May 1, 2026):**
`Newsletter#generate_html_body` was declared as `before_save`. On first create,
`validates :html_body, presence: true` fired before `generate_html_body` ran,
producing "Html body can't be blank" even though the markdown_body was valid and
the Redcarpet conversion would have produced correct HTML. Changing to
`before_validation` fixed it immediately.

---

## Mailer Views Directory — Check Existing Structure Before Creating (MANDATORY)

**RULE: Before creating a new mailer view directory, check where existing mailer
views live in this project. Do NOT assume `app/views/<mailer_name>/`.**

Rails defaults to `app/views/<mailer_name>/` for mailer templates. However,
some projects (including DECOR) configure or organise mailer views differently.

**DECOR's actual mailer views path:**
```
decor/app/views/mailers/<mailer_name>/<action>.html.erb
```

**NOT:**
```
decor/app/views/<mailer_name>/<action>.html.erb   ← wrong for this project
```

**Check command (run once per project):**
```bash
find decor/app/views -name "*.html.erb" | grep -i mail
```

The result immediately shows the convention this project uses.

**Why this rule exists (Session 56, May 1, 2026):**
`send_newsletter.html.erb` was placed at `app/views/newsletter_mailer/` which
produced `ActionView::MissingTemplate`. Moving it to
`app/views/mailers/newsletter_mailer/` resolved the error. The `PasswordResetMailer`
view was already in `app/views/mailers/` — checking that first would have
revealed the convention immediately.

---

## deliver_later vs deliver_now — Admin Tools and letter_opener (MANDATORY)

**RULE: For admin-initiated email actions, use `deliver_now` — not `deliver_later`.**

`deliver_later` hands the email to ActiveJob's background queue. letter_opener
(the development email interceptor) never sees it, so no browser tab opens and
the email appears to vanish. The only feedback is the flash notice.

`deliver_now` delivers synchronously on the current request. letter_opener
intercepts it immediately and opens the rendered email in a browser tab —
exactly the same behaviour as other emails in the project (invites, password resets).

**Wrong — letter_opener never fires, no tab opens:**
```ruby
NewsletterMailer.send_newsletter(owner, newsletter).deliver_later
```

**Correct:**
```ruby
NewsletterMailer.send_newsletter(owner, newsletter).deliver_now
```

**When `deliver_later` IS appropriate:**
- High-volume sends triggered by user actions (e.g. "notify all followers")
  where blocking the HTTP request would cause a timeout.
- Background jobs that are explicitly tested with `assert_enqueued_emails`.

**When `deliver_now` is appropriate:**
- Admin-triggered sends of any size where the admin can wait a moment.
- Any context where letter_opener preview during development is desired.
- Small transactional emails (invites, password resets, single newsletter sends).

**Addendum — testing `deliver_later` requires `perform_enqueued_jobs` (Session 58):**
`ActionMailer::Base.deliveries` is populated only when the job actually runs.
With `deliver_later`, the job is queued but not executed until you ask for it.
Wrap the controller call in `perform_enqueued_jobs` so the job runs synchronously
during the test and `deliveries` is populated by the time assertions run:

```ruby
# Wrong — deliveries is still empty, assertions fail
post send_password_reset_admin_owner_url(owner)
assert ActionMailer::Base.deliveries.size > 0   # fails: 0

# Correct
perform_enqueued_jobs do
  post send_password_reset_admin_owner_url(owner)
end
assert ActionMailer::Base.deliveries.size > 0   # passes
```

Note: `deliver_now` does NOT need `perform_enqueued_jobs` — it populates
`deliveries` directly during the request. Only `deliver_later` needs the wrapper.

**Why this rule exists (Session 56, May 1, 2026):**
The newsletter send action used `deliver_later`. The admin clicked "Send Newsletter",
got the flash "Newsletter queued for VAXorcist" — but no letter_opener tab appeared.
Switching to `deliver_now` produced the expected browser tab immediately.
The `perform_enqueued_jobs` addendum was discovered in Session 58 when the
`send_password_reset` test (which correctly uses `deliver_later`) failed with
`deliveries.size == 0` until wrapped in the jobs runner.

---

## Controller Actions — render Is Synchronous (MANDATORY)

**RULE: `render` in a Rails controller action renders the view immediately and
synchronously. Any instance variable assigned AFTER the `render` call is NOT
visible to the template.**

This means: every iVar the template needs must be set BEFORE any `render` call,
on every code path that leads to that render.

**Common mistake — @owners set at the bottom, render fires first:**
```ruby
def send_newsletter
  if request.post?
    case params[:recipient]
    when "specific"
      if params[:owner_id].blank?
        render :send_newsletter, status: :unprocessable_entity
        return                            # @owners never assigned
      end
    else
      render :send_newsletter, status: :unprocessable_entity
                                          # falls through to @owners = ...
                                          # but too late — view already rendered
    end
  end
  @owners = Owner.order(:user_name)       # not visible to the renders above
end
```

**Correct — set iVars unconditionally at the top:**
```ruby
def send_newsletter
  @owners = Owner.order(:user_name)       # set first, always available

  if request.post?
    # ... all render/redirect paths below can rely on @owners
  end
end
```

**Pattern to follow:**
Place all iVar assignments that are needed by any render path at the very top
of the action, before any branching. On redirect paths the iVars are assigned
but unused — that is harmless.

**Why this rule exists (Session 58, May 3, 2026):**
`Admin::NewslettersController#send_newsletter` placed `@owners = Owner.order(:user_name)`
after the `if request.post?` block. Two POST failure paths called
`render :send_newsletter` before that line was reached. The view raised
`undefined method 'each' for nil` at the `@owners.each` call on line 75.

---

## before_action :set_resource — Always Scope with only: (MANDATORY)

**RULE: Whenever a controller has new or create actions alongside a set_resource
callback, the callback MUST be scoped with `only:` to exclude new and create.**

`new` and `create` have no `:id` param. An unscoped `before_action :set_resource`
will call `Model.find(params[:id])` with a nil or missing id, raising
`ActiveRecord::RecordNotFound` before either action runs. The failure is
silent at write time — it only explodes when the action is first exercised.

**Wrong — crashes on new and create:**
```ruby
before_action :set_software_item
```

**Correct:**
```ruby
before_action :set_software_item, only: %i[show edit update destroy]
```

**When to use which set:**
- `only: %i[show edit update destroy]` — the standard set for a resourceful
  controller where new/create build from `Current.owner` or `Model.new`.
- Adjust if the controller has non-standard actions (e.g. a custom `duplicate`
  action that does take an :id param should be added to the only: list).

**Why this rule exists (Session 46, April 3, 2026):**
`software_items_controller.rb` v1.0 (Session 45) shipped as read-only with only
a `show` action. The `before_action :set_software_item` had no `only:` restriction
— harmless when show was the only action, because show always has an :id. In
Session 46, when `new` and `create` were about to be added, the pre-implementation
review caught the gap. The v1.0 code would have crashed `new` and `create` as
soon as they were wired up. Rule added so this is caught at write time, not at test time.

---

## data-turbo="false" — NEVER wrap Turbo-method links inside a Turbo-disabled element

**RULE: Never place a `data-turbo-method` link inside any ancestor element that
carries `data-turbo="false"` or `data: { turbo: false }`.**

`data-turbo="false"` disables Turbo for the element AND all of its descendants.
A `data-turbo-method="delete"` (or any other method) link inside such a wrapper
is silently treated as a plain GET by the browser — Turbo never processes it.

**Result:** a routing error such as `No route matches [GET] "/admin/site_texts/privacy"`
when the route only exists as DELETE.

**Wrong — Turbo disabled on the link by its ancestor:**
```erb
<%= form_with url: "#", data: { turbo: false } do |f| %>
  <a href="<%= admin_site_text_path(key) %>"
     data-turbo-method="delete"
     data-turbo-confirm="Are you sure?">Delete</a>
<% end %>
```

**Correct — link lives outside any Turbo-disabled wrapper:**
```erb
<a href="<%= admin_site_text_path(key) %>"
   data-turbo-method="delete"
   data-turbo-confirm="Are you sure?">Delete</a>
```

**Why this rule exists (Session 53, April 16, 2026):**
`delete_confirm.html.erb` v1.0 wrapped the Delete link in a `form_with` with
`data: { turbo: false }` (originally added to allow multipart form submission
on the upload page — copy-pasted unnecessarily). The link was visible and
rendered correctly; it simply fired a GET instead of DELETE, producing a
routing error. The bug was invisible to controller tests, which call routes
directly without rendering JS behaviour.

**Detection gap:** this class of bug requires a system test (real browser) to
catch. Controller integration tests bypass the view layer entirely.

---

## CSS grid grid-cols-N — Equal columns cause overflow hidden behind later items

**RULE: Never use `grid-cols-N` (equal `1fr` columns) for a left/logo/right
navbar layout. Use `grid-cols-[auto_1fr_auto]` instead.**

`grid-cols-3` divides the nav into three equal `1fr` columns. If the left
column's flex content (nav links) is wider than `1fr`, it overflows its cell.
CSS grid does NOT clip overflow — but grid items stack in source order, so the
centre and right grid cells render ON TOP of the overflowed left content.
The overflowed links are visible but unclickable (or only partially clickable
where no overlapping element covers them).

**Symptoms that point to this bug:**
- A nav link is visible but cannot be clicked (fully covered by a later column).
- A link is only clickable at its very bottom edge (partially covered by the
  centre logo image).
- The bug is worse for users with more items in the right column (e.g. admins).

**Wrong:**
```erb
<nav class="grid grid-cols-3 items-center gap-2 px-6 py-4">
  <div class="flex gap-6">   <%# left: nav links — may overflow 1fr %> </div>
  <div class="flex justify-center"> <%# centre: logo %> </div>
  <div class="flex justify-end">   <%# right: auth %> </div>
</nav>
```

**Correct:**
```erb
<nav class="grid grid-cols-[auto_1fr_auto] items-center gap-2 px-6 py-4">
  <div class="flex gap-6 relative z-10"> <%# left: sizes to content %> </div>
  <div class="flex justify-center">      <%# centre: takes remaining space %> </div>
  <div class="flex justify-end">         <%# right: sizes to content %> </div>
</nav>
```

`relative z-10` on the left div is a safety net: if future crowding causes any
visual overlap, the left column's links remain above the centre column.

**Why this rule exists (Session 53, April 16, 2026):**
`_navigation.html.erb` used `grid-cols-3` since its creation. Adding the
Software link as the 6th item in the left nav pushed it past the `1fr`
boundary. Logged-out users saw the bug mildly; admins (with Admin link +
username dropdown in the right column, widening the right cell's visual
footprint) saw Software completely unclickable.

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

- ✅ Assign all new test-support fixtures to the neutral owner
- ✅ Document the intent clearly in `owners.yml`
- ❌ Never add hardcoded count assertions for the neutral owner

**Grep check before assigning a fixture to an existing owner:**
```bash
grep -rn "\.count" decor/test/ | grep -i "alice\|bob\|owners(:one)\|owners(:two)"
```

If any hardcoded counts exist → use the neutral owner instead.

---

## Association Rename Grep Sweep — MANDATORY

**When renaming a model, table, or association, BEFORE writing any files:**

Run a grep across the ENTIRE project for the old name in all contexts:

```bash
grep -rn "\.old_name" decor/app/
grep -rn "OldClassName" decor/app/ decor/test/
grep -rn "old_names(:" decor/test/
grep -rn "old_name_id" decor/app/
```

Fix ALL occurrences found before running the test suite.

---

## Rails Testing Patterns

### Centralized Test Helpers

**ALWAYS create support modules for shared test logic.**

**Structure:**
```
test/
├── support/
│   ├── authentication_helper.rb
│   ├── test_constants.rb
│   └── factory_helpers.rb
├── test_helper.rb
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

`PRAGMA foreign_keys = OFF/ON` is a no-op inside a transaction. Use
`disable_ddl_transaction!` in any migration that needs to temporarily suspend
FK enforcement:

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

```ruby
# Integration test that checks email delivery — must include explicitly:
class Admin::NewslettersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  ...
end

# Mailer test — no include needed, ActionMailer::TestCase has it already:
class NewsletterMailerTest < ActionMailer::TestCase
  ...
end
```

Also clear `ActionMailer::Base.deliveries` in `setup` so email counts are
independent across tests:

```ruby
setup do
  ActionMailer::Base.deliveries.clear
end
```

---

## NOT NULL Boolean Columns — Always Explicit in PATCH Test Params (MANDATORY)

**RULE: Every PATCH test must supply an explicit value for every NOT NULL column
the controller writes — even columns the test doesn't care about.**

**Root cause:** `ActiveModel::Type::Boolean.cast(nil)` returns `nil`, not `false`.
When a param key is absent from the request, `params.dig(:owner, :admin)` returns
`nil`. If the controller assigns `@owner.admin = nil`, the DB raises
`ActiveRecord::NotNullViolation`.

**Wrong — admin: absent, cast(nil) → nil → NOT NULL violation:**
```ruby
patch admin_owner_url(bob), params: {
  owner: { user_name: "bobby", email: bob.email, newsletter: 1 }
  # admin: not supplied — params.dig returns nil → @owner.admin = nil → crash
}
```

**Correct — explicit value for every NOT NULL column the controller touches:**
```ruby
patch admin_owner_url(bob), params: {
  owner: { user_name: "bobby", email: bob.email, newsletter: 1, admin: "false" }
}
```

**Special case — updating the currently-logged-in admin's own record:**
The self-demotion guard fires when `@owner == Current.owner && !requested_admin`.
`cast(nil)` → nil → `!nil` → true → guard fires even when the test has nothing
to do with admin status. Pass `admin: "true"` to bypass the guard:

```ruby
patch admin_owner_url(alice), params: {
  owner: { ..., newsletter: 0, admin: "true" }  # prevents guard redirect
}
```

**Why this rule exists (Session 58, May 3, 2026):**
Three PATCH tests for `Admin::OwnersController` omitted `admin:` from params
for bob's record. All three raised `NOT NULL constraint failed: owners.admin`.
The fix was adding `admin: "false"` to each params hash.

---

## Switching Users in Tests With a Setup Login (MANDATORY)

**RULE: When `setup` logs in as one owner and a test needs to switch to a
different owner, always call `delete session_path` before `login_as other_owner`.**

If `login_as(other_owner)` fails silently (wrong password constant, session
conflict, any error in the session controller), the first owner's session
remains active. The test then runs as the wrong user with no error raised —
producing a misleading assertion failure (e.g. 200 instead of redirect).

**Wrong — alice's session may persist if login_as(bob) fails:**
```ruby
setup do
  login_as owners(:one)   # alice (admin)
end

test "non-admin cannot access admin area" do
  login_as owners(:two)   # bob — may fail silently; alice still logged in
  get admin_owners_url
  assert_redirected_to root_path  # fails: gets 200 because alice is still active
end
```

**Correct — explicit logout guarantees a clean session:**
```ruby
test "non-admin cannot access admin area" do
  delete session_path      # clear alice's session unconditionally
  login_as owners(:two)    # bob — now definitely the active user
  get admin_owners_url
  assert_redirected_to root_path
end
```

**When this applies:**
- Any test in a class whose `setup` calls `login_as` where the test itself
  needs a different user (different owner, non-admin, unauthenticated).
- Also applies to unauthenticated tests in the same class: use `delete session_path`
  without a subsequent `login_as` to test the logged-out state.

**Why this rule exists (Session 58, May 3, 2026):**
`Admin::OwnersControllerTest` setup logged in as alice. The "non-admin cannot
access" test called `login_as(bob)` directly. The test got 200 (admin access
granted) instead of a redirect — alice's session was still active. Adding
`delete session_path` first fixed it immediately.

---

## Rails Test Helper — save! vs create! with Callbacks

**`save!(validate: false)` skips `before_validation` callbacks entirely.**

**Wrong:**
```ruby
record = Model.new(email: "x@example.com")
record.save!(validate: false)  # before_validation never runs
```

**Correct:**
```ruby
record = Model.create!(email: "x@example.com")
record.update_columns(sent_at: 21.days.ago)
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

`whitespace-pre-wrap` renders ALL whitespace literally — including the newline
and indentation between a tag and its `<%= %>` content block.

**Wrong:**
```erb
<dd class="whitespace-pre-wrap">
  <%= record.description %>
</dd>
```

**Correct:**
```erb
<dd class="whitespace-pre-wrap"><%= record.description %></dd>
```

**Rule:** whenever `whitespace-pre-wrap` is used on an element whose content
comes from an ERB tag, the `<%= %>` tag MUST be on the same line as the
opening HTML tag.

---

## File Uploads in Integration Tests — Use Rack::Test::UploadedFile

**When writing integration tests that upload files via `post params:`:**

Use `Rack::Test::UploadedFile`, NOT `ActionDispatch::Http::UploadedFile`.

```ruby
upload = Rack::Test::UploadedFile.new(tempfile.path, "text/csv", false,
                                       original_filename: "file.csv")
post path, params: { file: upload }
```

---

## Response Body Assertions — Use assert_body_includes (MANDATORY)

**In integration tests, NEVER use `assert_match(text, response.body)` or
`refute_match(text, response.body)`.**

The default `assert_match` / `refute_match` helpers print the entire "actual"
value on failure. For controller tests that check `response.body`, this dumps
the full rendered HTML (often 5,000–20,000 characters) making the failure
message impossible to read.

**Use the project helpers instead:**

```ruby
# WRONG — dumps the full HTML page on failure
assert_match "SN12345", response.body
refute_match "PDP8-7891", response.body

# CORRECT — truncates to 300 chars on failure
assert_body_includes "SN12345"
refute_body_includes "PDP8-7891"
```

`assert_body_includes` and `refute_body_includes` are defined in
`test/support/response_helpers.rb` and included in
`ActionDispatch::IntegrationTest` via `test_helper.rb`.

**Why this rule exists (Session 50, April 2026):**
Filter tests for the software index produced 7 failures. Each failure message
contained the full rendered HTML of the page — nav, sidebar with all dropdown
options, table rows, footer — making it impossible to see what actually went
wrong without scrolling through thousands of lines of markup.

---

## multi-table ORDER BY — Wrap in Arel.sql()

**Rails rejects raw ORDER BY strings that reference joined table columns.**

Any `.order()` argument containing a dot (`table.column`), a SQL keyword
(`NULLS LAST`, `ASC`, `DESC` with spaces), or anything that is not a simple
attribute name will raise `ActiveRecord::UnknownAttributeReference`.

**Wrong:**
```ruby
.order("computer_models.name ASC NULLS LAST, computers.serial_number ASC")
```

**Correct:**
```ruby
.order(Arel.sql("computer_models.name ASC NULLS LAST, computers.serial_number ASC"))
```

**When Arel.sql() is required:**
- Multi-table references: `"joined_table.column_name"`
- `NULLS LAST` / `NULLS FIRST`
- Any expression that is not a bare column symbol (`:created_at`) or hash (`created_at: :asc`)

**Safety note:** Only wrap strings that are fully hardcoded — NEVER wrap
user-supplied input in `Arel.sql()`.

---

## Directory Tree Maintenance — MANDATORY

The `## Directory Tree` section in `DECOR_PROJECT.md` is the authoritative
record of the project's file structure. It must be kept current.

### When to update

Update `DECOR_PROJECT.md` (Directory Tree + Key file versions table) whenever:
- A new file is created
- A file is deleted
- A file's version number changes

### How to update

1. Claude updates the **Key file versions** table inline after every file change.
2. The full tree block is replaced only when the user re-runs the tree command
   and uploads a fresh `decor_tree.txt`.

### Tree command (run from parent of decor/)

```bash
tree decor/ \
  -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" \
  --dirsfirst -F --prune -L 6 \
  > decor_tree.txt
```

---

## Enum Assertions in Tests — Use String or Predicate, Not Integer

**Rails enum accessors always return the mapped string label, never the raw integer.**

**Wrong:**
```ruby
assert_equal 0, model.read_attribute(:device_type)   # returns "computer"
assert_equal 0, model[:device_type]                  # returns "computer"
assert_equal 0, model.device_type                    # returns "computer"
```

**Correct:**
```ruby
assert_equal "computer", model.device_type
assert model.device_type_computer?
```

---

## SQLite Table Recreation — Always Use Explicit Column Names

**RULE: Never use `SELECT *` in the INSERT step of a SQLite table recreation
migration. Always name every column explicitly on both sides.**

```ruby
COLUMNS = %w[id col1 col2 col3 created_at updated_at].freeze
col_list = COLUMNS.join(", ")
execute "INSERT INTO components_new (#{col_list}) SELECT #{col_list} FROM components"
```

---

## Nested Attributes — Always Use reject_if: :all_blank

**When using `accepts_nested_attributes_for` with a form that lets the user add
rows dynamically, always include `reject_if: :all_blank`.**

```ruby
accepts_nested_attributes_for :connection_members,
                               allow_destroy: true,
                               reject_if:     :all_blank
```

---

## Task-Type File Checklists

### Table Column Changes

```
Always need:
  [ ] The index view                    app/views/MODEL/index.html.erb
  [ ] The row partial                   app/views/MODEL/_MODEL.html.erb
  [ ] Turbo stream (check if needed)    app/views/MODEL/index.turbo_stream.erb
```

### Sort / Filter Changes

```
Always need (all three):
  [ ] app/views/MODEL/_filters.html.erb
  [ ] app/helpers/MODEL_helper.rb
  [ ] app/controllers/MODEL_controller.rb
```

### Controller Action Changes

```
Always need:
  [ ] app/controllers/MODEL_controller.rb
  [ ] test/controllers/MODEL_controller_test.rb
  [ ] test/fixtures/MODELs.yml
```

### Model / Association Changes

```
Always need:
  [ ] app/models/MODEL.rb
  [ ] test/models/MODEL_test.rb
  [ ] test/fixtures/MODELs.yml
Run grep sweep BEFORE writing any files.
```

### New Page / Route

```
Always need:
  [ ] config/routes.rb
  [ ] The controller file
  [ ] app/views/layouts/application.html.erb  (public nav)
        OR app/views/layouts/admin.html.erb   (admin nav)
```

### New Mailer

```
Always need:
  [ ] app/mailers/<mailer_name>_mailer.rb
  [ ] app/views/mailers/<mailer_name>/<action>.html.erb   ← check existing path first!
  [ ] test/mailers/<mailer_name>_mailer_test.rb
  Use deliver_now for admin tools; deliver_later only for high-volume background sends.
```

---

## CSV::Table — Never Use #to_a When You Need Row Indexing

**`CSV::Table#to_a` returns plain arrays, not `CSV::Row` objects.**

**Wrong:**
```ruby
rows = @csv.to_a
sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }
# → TypeError: no implicit conversion of String into Integer
```

**Correct:**
```ruby
rows = @csv.map { |r| r }
sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }
```

---

**End of RAILS_SPECIFICS.md**
