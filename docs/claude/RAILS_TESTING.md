# decor/docs/claude/RAILS_TESTING.md
# version 1.0 NEW
# Session 84 (Reorg Session 3 of 4): Extracted from RAILS_SPECIFICS.md v3.15
# as part of the agreed 4-session documentation reorg (see
# SESSION_HANDOVER.md "Documentation Reorganization — Status"). Contains
# every fixture/test-helper/Capybara/CI rule previously mixed into the
# single monolithic RAILS_SPECIFICS.md file. Each rule's lengthy "why this
# rule exists" incident narrative has been trimmed to one line — the rule
# statement and code examples (load-bearing for Pre-Implementation
# Verification) are unchanged. Full original narrative for every rule below
# remains recoverable via git history of RAILS_SPECIFICS.md prior to this
# split.
# Load this file for any test-writing session — it is NOT part of the
# mandatory session-start `cat` list (see RAILS_SPECIFICS.md's topic
# index), but should be read before writing ANY test file, per the
# Pre-Implementation Verification checklist in RAILS_SPECIFICS.md.

**Rails-Specific Patterns — Testing, Fixtures, and CI**

**Last Updated:** July 30, 2026 (Session 84 — split out of RAILS_SPECIFICS.md)

---

## Fixture Ownership — Derive Counts from Data; Use Neutral Owners for Support Fixtures

**Never hardcode a count assertion on fixture-owned records** (general
principle in PROGRAMMING_GENERAL.md "Derive Test Assertions from Data, Not
Constants"). Adding any new fixture to an owner breaks a hardcoded count —
often in a completely unrelated test file.

```ruby
# Bad — breaks the moment a 3rd fixture is added to bob
assert_equal 2, @bob.computers.count

# Good
bob_computer_ids = @bob.computers.pluck(:id)
assert bob_computer_ids.any?, "Bob must have at least one computer for this test"
# ... perform action ...
bob_computer_ids.each { |id| assert_nil Computer.find_by(id: id) }
```

**Neutral Owner Pattern:** when hardcoded counts already exist and can't be
immediately removed, assign new test-support fixtures to a dedicated
neutral owner whose counts no test ever asserts. In decor: `owners(:three)`
/ charlie.

```bash
# Grep check before assigning a fixture to an existing owner:
grep -rn "\.count" decor/test/ | grep -i "alice\|bob\|owners(:one)\|owners(:two)"
```

---

## Association Rename Grep Sweep — MANDATORY

**When renaming a model, table, or association, BEFORE writing any test
files, grep the ENTIRE project for the old name:**

```bash
grep -rn "\.old_name" decor/app/
grep -rn "OldClassName" decor/app/ decor/test/
grep -rn "old_names(:" decor/test/
grep -rn "old_name_id" decor/app/
```

Fix ALL occurrences found before running the test suite.

---

## Rails Testing Patterns — Centralized Test Helpers

**ALWAYS create support modules for shared test logic.**

```
test/
├── support/
│   ├── authentication_helper.rb
│   ├── test_constants.rb
│   └── factory_helpers.rb
├── test_helper.rb
```

```ruby
# test/support/authentication_helper.rb
module AuthenticationHelper
  TEST_PASSWORD_ADMIN = "password12345".freeze
  TEST_PASSWORD_USER = "password45678".freeze

  def login_as(user, password: nil)
    password ||= detect_password(user)
    post session_path, params: { user_name: user.user_name, password: password }
  end
end
```

```ruby
# test/test_helper.rb
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

**DRY rule (Session 59):** `TEST_PASSWORD_CHARLIE` for `owners(:three)`; NO
literal password strings are permitted anywhere in the test suite — always
use the AuthenticationHelper constants (ALICE/BOB/CHARLIE/VALID).

---

## CI Security Checks — Two Separate Tools (MANDATORY)

GitHub Actions runs **two independent security jobs** that check completely
different things:

| CI job name          | Tool           | Checks                                    | Local command                            |
|-----------------------|----------------|--------------------------------------------|--------------------------------------------|
| `CI/Security (Ruby)` | `bundle-audit` | Known CVEs in gem **versions** (incl. transitive deps) | `bundle exec bundle-audit check --update` |
| (separate)            | `brakeman`     | Static analysis of **your own code**       | `bin/brakeman --no-pager`                  |

A PR that changes zero Ruby code can still fail `CI/Security (Ruby)` if any
dependency in `Gemfile.lock` has a newly-published CVE.

**Diagnostic rule if `CI/Security (Ruby)` fails:**
1. Do NOT assume Brakeman — a clean local `bin/brakeman` proves nothing.
2. Get the actual CI log:
   ```bash
   gh run view <run-id> --log-failed -R <owner>/<repo> > /tmp/fail.log
   tail -60 /tmp/fail.log
   ```
3. `Name:`/`CVE:`/`Solution: update to '>= x.y.z'` repeated for several
   gems, ending in `Vulnerabilities found!` → that's bundle-audit.

**Fix pattern:**
```bash
bundle update <gem1> <gem2> <gem3>
bundle exec bundle-audit check --update
```

**bundle-audit reports in batches** — fixing what one CI failure shows can
unmask more on the next run. Always confirm with a full local
`bundle-audit check --update` returning "No vulnerabilities found" before
pushing.

**Why:** a Session 64 PR's `CI/Security (Ruby)` failure was misdiagnosed as
Brakeman and cost a full debugging round-trip; Session 72 hit the
batching behavior (4 gems in one batch, unrelated to that session's own code).

---

## `gh run view` — Run ID Required When Not Interactive

`gh run view --log-failed` opens an interactive picker by default, which
fails outside a TTY:

```bash
# FAILS outside a TTY:
gh run view --log-failed -R owner/repo > /tmp/fail.log
# Error: run or job ID required when not running interactively
```

**Fix:** pass the run ID explicitly (the number in the run's URL, also
shown by `gh pr checks`):

```bash
gh run view <run-id> --log-failed -R owner/repo > /tmp/fail.log
```

Note `gh pr checks <branch> --watch` re-displays the SAME run until a new
commit is actually pushed — confirm the run ID changed before treating
output as a fresh result.

---

## Rails Test Class — Required Inclusions

`ActionMailer::TestHelper` (`assert_emails`, `assert_no_emails`):
- Included automatically in `ActionMailer::TestCase`.
- NOT included in `ActiveJob::TestCase`, `ActiveSupport::TestCase`,
  `ActionDispatch::IntegrationTest` — include it explicitly.

```ruby
class Admin::NewslettersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  ...
end
```

Also clear deliveries in `setup` for independence across tests:
```ruby
setup { ActionMailer::Base.deliveries.clear }
```

---

## NOT NULL Boolean Columns — Always Explicit in PATCH Test Params (MANDATORY)

**RULE: Every PATCH test must supply an explicit value for every NOT NULL
column the controller writes** — even columns the test doesn't care about.
`ActiveModel::Type::Boolean.cast(nil)` returns `nil`, not `false`; an
absent param key becomes `@owner.admin = nil` → `NotNullViolation`.

```ruby
# Wrong — admin: absent → cast(nil) → nil → NOT NULL violation
patch admin_owner_url(bob), params: {
  owner: { user_name: "bobby", email: bob.email, newsletter: 1 }
}

# Correct
patch admin_owner_url(bob), params: {
  owner: { user_name: "bobby", email: bob.email, newsletter: 1, admin: "false" }
}
```

**Special case — updating the currently-logged-in admin's own record:** the
self-demotion guard fires on `cast(nil) → nil → !nil → true`. Pass
`admin: "true"` to bypass it even when the test has nothing to do with
admin status.

**Why:** three PATCH tests for `Admin::OwnersController` omitted `admin:`
for bob's record and all three raised `NotNullViolation` (Session 58).

---

## Switching Users in Tests With a Setup Login (MANDATORY)

**RULE: When `setup` logs in as one owner and a test needs a different
owner, always call `delete session_path` before `login_as other_owner`.**
If `login_as` fails silently, the first owner's session persists — the test
then runs as the wrong user with no error, producing a misleading
assertion failure.

```ruby
# Wrong — alice's session may persist if login_as(bob) fails
setup { login_as owners(:one) }
test "non-admin cannot access admin area" do
  login_as owners(:two)
  get admin_owners_url
  assert_redirected_to root_path   # fails: gets 200, alice still active
end

# Correct
test "non-admin cannot access admin area" do
  delete session_path
  login_as owners(:two)
  get admin_owners_url
  assert_redirected_to root_path
end
```

Also applies to unauthenticated tests in the same class: use
`delete session_path` alone (no subsequent `login_as`).

**Why:** `Admin::OwnersControllerTest`'s "non-admin cannot access" test got
200 instead of a redirect — alice's session was still active (Session 58).

---

## Rails Test Helper — save! vs create! with Callbacks

**`save!(validate: false)` skips `before_validation` callbacks entirely.**

```ruby
# Wrong
record = Model.new(email: "x@example.com")
record.save!(validate: false)   # before_validation never runs

# Correct
record = Model.create!(email: "x@example.com")
record.update_columns(sent_at: 21.days.ago)
```

---

## File Uploads in Integration Tests — Use Rack::Test::UploadedFile

Use `Rack::Test::UploadedFile`, NOT `ActionDispatch::Http::UploadedFile`:

```ruby
upload = Rack::Test::UploadedFile.new(tempfile.path, "text/csv", false,
                                       original_filename: "file.csv")
post path, params: { file: upload }
```

---

## Response Body Assertions — Use assert_body_includes (MANDATORY)

**NEVER use `assert_match(text, response.body)` / `refute_match(...)` in
integration tests.** These dump the ENTIRE rendered HTML on failure
(often 5,000–20,000 chars), making failures unreadable.

```ruby
# Wrong — dumps the full HTML page on failure
assert_match "SN12345", response.body

# Correct — truncates to 300 chars on failure
assert_body_includes "SN12345"
refute_body_includes "PDP8-7891"
```

`assert_body_includes`/`refute_body_includes` live in
`test/support/response_helpers.rb`, included via `test_helper.rb`.

**Why:** software index filter test failures dumped the full rendered page
(nav, sidebar, table, footer) making failures unreadable (Session 50).

**Filter test corollary (Session 50):** when testing that a filter
excludes an item, never `refute_match` on a name that ALSO appears in the
filter sidebar's `<option>` elements — assert/refute on data-row values only.

---

## Enum Assertions in Tests — Use String or Predicate, Not Integer

**Rails enum accessors always return the mapped string label, never the
raw integer.**

```ruby
# Wrong
assert_equal 0, model.device_type   # actually returns "computer"

# Correct
assert_equal "computer", model.device_type
assert model.device_type_computer?
```

---

## System Tests — Browser-Layer Login (MANDATORY)

`login_as` (AuthenticationHelper) posts via the Rack test adapter — it sets
a session cookie on the Rack adapter, NOT the Selenium browser process,
which has a completely separate cookie jar.

**Rule: Never call `login_as` from a system test file.** Use `sign_in`
(`ApplicationSystemTestCase` v1.3) — it drives the real login form through
the browser.

---

## System Tests — Capybara Assertion Patterns (MANDATORY)

### assert_selector with a message string raises ArgumentError

`assert_selector`/`refute_selector`/`assert_text` do NOT accept a plain
string as a second positional argument.

```ruby
# Wrong
assert_selector "input[name='user_name']", "Login form must have this field"

# Correct — route the message through Minitest's assert
assert page.has_css?("input[name='user_name']"), "Login form must have this field"
assert page.has_no_css?("select[name='barter_status']"), "Must not be rendered"
assert page.has_text?("+ Add port"), "Button must be visible"
```
`has_css?`/`has_no_css?`/`has_text?` still use Capybara's smart waiting.

### Capybara select() matches by TEXT, not value=

`Capybara.select(string, from: field)` searches by visible **text**, not
the HTML `value=`. Passing a fixture integer ID always raises
`Capybara::ElementNotFound`.

```ruby
# Wrong
select first_option_value, from: "software_name_id"   # looks for TEXT "994812667"

# Correct — keep a reference to the option element
first_option = select_el.all("option").reject { |o| o.value.empty? }.first
first_option.select_option
assert page.has_select?("software_name_id", selected: first_option.text, wait: 5)
```

**Addendum — capture that text BEFORE navigating, not after:** reading a
Capybara element's property AFTER a Turbo-driven navigation
(`click_button`/`click_link`) risks `StaleElementReferenceError`, since
Turbo replaces the DOM.

```ruby
# Wrong — reads first_option.text AFTER click_button has already navigated
click_button "Apply"
assert page.has_select?("owner_id", selected: first_option.text, wait: 5)

# Correct — capture the text as a plain string BEFORE the click
expected_text = first_option.text
select_el.find("option[value='#{first_option.value}']").select_option
click_button "Apply"
assert page.has_select?("owner_id", selected: expected_text, wait: 5)
```

**Why:** CI's `CI/Tests (System)` check failed with
`StaleElementReferenceError` in a Capybara select test; two sibling tests
in the same file had the identical latent risk but hadn't failed yet
(Sessions 60, 76).

### Filter forms in Turbo Frames don't update the URL

Filter forms rendered inside Turbo Frames update the frame content but the
top-level URL stays at the bare path — `assert_includes current_url,
"param="` will always fail.

```ruby
# Correct — click the named Apply button; assert form field state, not URL
fill_in "query", with: "vms"
click_button "Apply"
assert page.has_field?("query", with: "vms", wait: 5)
```

### `<template>` elements require evaluate_script

`<template>` content lives in a DocumentFragment, not the live render tree
— `assert_selector`/`has_css?` cannot find it even with `visible: :all`.

```ruby
# Correct
template_present = evaluate_script(
  "document.querySelector(\"[data-connection-members-target='template']\") !== null"
)
assert template_present, "Form must render the template Stimulus target"
```

### Turbo navigation race in sign_in / sign_out

`form_with` without `local: true` submits via Turbo (async `fetch()`); a
click returns before the navigation completes, so reading `current_path`
immediately after races the navigation.

```ruby
# sign_in fix — wait for the login form to disappear
find("[type=submit]").click
has_no_field?("user_name", wait: 5)

# sign_out fix — click_on matches <a> or <button>; wait for it to disappear
click_on "Sign out"
has_no_text?("Sign out", wait: 5)
```
Prerequisite: the nav partial must render "Sign out" when `logged_in?`.

**Why (all System Tests items above):** discovered together while writing
the first system-test suite in Session 60; the StaleElementReferenceError
addendum was a separate CI-caught recurrence in Session 76.

---

**End of RAILS_TESTING.md**
