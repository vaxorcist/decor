# decor/docs/claude/SESSION_HANDOVER.md
# version 73.0
# Session 73: Category Help Pages feature — 5 new owner-facing help pages
#   (Computers/Peripherals/Components/Connections/Software), admin-manageable
#   via the existing generic SiteText subsystem. Code-complete (7 files: 5
#   production, 2 test), NOT YET tested/lint/security-scanned/committed. Two
#   pre-existing bugs found and fixed via Never-Guess file review (a stale
#   title_for_key in the owner-facing controller; a hardcoded per-key case
#   statement in the admin controller's url_for_key, generalized). Also
#   closed a documentation gap: SiteText had never appeared in DECOR_PROJECT.md's
#   Data Model Overview despite existing since Session 18 — added this
#   session. See "Session 73 Summary" below for full detail.
# Session 72: CI Security (Ruby) failure on the feature/owner_part_number PR
#   diagnosed as bundle-audit (not Brakeman, per the existing rule) via the
#   actual CI log; four gems bumped (loofah, rails-html-sanitizer, sqlite3,
#   websocket-driver) to clear a batch of CVEs; confirmed clean locally;
#   merged and deployed. Separately, Ulli confirmed Sessions 67-70 (previously
#   described throughout this document as "sitting locally, uncommitted")
#   have ALL already been committed, pushed, merged, and deployed to main.
#   All "NOT YET committed/pushed/deployed" language for those sessions is
#   now resolved — see "Session 72 Summary" below and the update notes added
#   to the Date/Branch/Status block and each affected session summary.
# Session 71: Owner Part Number display fix (9 files — the 8 URLs missing the
#   column/field, per Session 70's own gap flag) delivered. Separately: agreed
#   and implemented a new File Transfer Protocol with the user — COMMON_BEHAVIOR.md
#   bumped to v3.0, replacing the old Download File Naming / Output Path Collision /
#   Upload File Naming rules with export/import shell scripts using @-encoded flat
#   filenames (decor/export/ and decor/import/, both gitignored). Updated the three
#   stale references to the old rules found in this file and in DECOR_PROJECT.md
#   (the "!! OUTPUT PATH COLLISION !!" banner below, the "Upload-collision hit
#   again this session" note, and the Session 63 file-list upload instruction).
# Session 70: Owner Part Number feature — IMPLEMENTED (11 of 12 files;
#   schema.rb regeneration pending an actual db:migrate run). All three open
#   design questions from Session 69 answered and implemented: uniqueness
#   scope keeps model/type dimension; both serial_number and the new
#   owner_part_number default to "-" via before_validation on both models;
#   spares collisions resolved via a one-time "SPARE-#{id}" backfill
#   migration with NO auto-assign going forward (Option B). CSV export/
#   import updated (owner_export_service.rb / owner_import_service.rb only —
#   computer_model_export_service.rb confirmed out of scope). See "Session 70
#   Summary" below for full detail, the resulting CSV re-import behaviour
#   change, and the complete NOT YET DONE checklist.
# Session 69: UI Terminology Rename — IMPLEMENTED (15 files). Owner Part
#   Number feature — design consultation only, NOT implemented, three open
#   questions. Also: this session found no "Session 68 Summary" exists in
#   this file despite Session 68 code changes clearly present in the actual
#   source (component_suggestions views carry "Session 68 (cont'd)" comments).
#   See "!! GAP NOTICE !!" and "Session 69 Summary" below.
# Session 67: Component Suggestions Phase 4 — IMPLEMENTED (migration, manual
#   flag, Download Manual Changes, import rewrite, paginated/filterable admin
#   index). bin/rails test passing locally (900 tests, 0 failures/errors).
#   NOT YET committed/pushed/deployed. See "Session 67 Summary" below.
# Session 66: Order number / variant — design pivot, no implementation. Full
#   multi-column variant-split design worked out in detail, then set aside
#   before implementation began (risk of "self-indulgent featuritis"). Saved
#   for reference at decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md. Adopted
#   a simpler concatenated-field approach instead. See "Session 66 Summary"
#   below for confirmed requirements going into next session.
# Session 65: Component order_number bulk maintenance (admin Components dropdown).

**Date:** July 19, 2026
**Branch:** main (Sessions 49–72 all committed, pushed, merged, and deployed).
  Session 73 (Category Help Pages feature, this session) is **code-complete
  but NOT YET tested, lint/security-scanned, or committed** — sitting
  locally. This is a single-session checklist, not a multi-session stack
  like the Sessions 67–70 situation Session 72 resolved.
**Status:** Sessions 1–72 fully closed out (see "Session 72 Summary"). Session
  73's checklist (see "Session 73 Summary" below) is the only currently open
  one. The GAP NOTICE below (Session 68's missing formal summary — a
  documentation-only issue, not a code issue) also remains open.

---

## !! RELIABILITY NOTICE — READ FIRST !!

The `decor-session-rules` skill (v1.3) is installed. Read it before anything else.

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

## !! GAP NOTICE — Session 68 has no formal summary in this document (found Session 69) !!

While reading files for the Session 69 UI rename task, several source files
delivered as part of the project (e.g.
`decor/app/views/admin/component_suggestions/index.html.erb`, which carried
a "Session 68 (cont'd)" changelog comment about dropdown-width/full-bleed
layout fixes) showed clear evidence of Session 68 work having happened and
been delivered. **But this SESSION_HANDOVER.md (as uploaded to the project)
has no "Session 68 Summary" section, and DECOR_PROJECT.md's own header
changelog jumps straight from Session 67 to Session 69 with no Session 68
entry either.**

This was not reconstructed or guessed at — per the Never-Guess rule, no
"Session 68 Summary" has been fabricated from the partial evidence in the
source files. **This is flagged for Ulli to reconcile:** either a newer
version of these two documents (containing the real Session 68 Summary)
exists outside this project and simply wasn't the version uploaded here, or
Session 68's rule-doc updates were never actually produced/delivered despite
the code changes shipping. Worth checking before treating this document as
a complete history.

**Update (Session 72):** Ulli confirmed the underlying code for Sessions
67–70 has all been committed, pushed, merged, and deployed to `main` — the
"uncommitted, stacked locally" situation described above and throughout this
document is now resolved on the git/deploy side. This documentation gap
(no formal Session 68 Summary ever written here) is a separate, still-open
issue — it does not block or affect the code, which is live — but is left
flagged in case Ulli wants to reconstruct it later from source history.

---

## !! GEARED PAGINATION — paginate() SETS @page AND RENDERS ITSELF (learned Session 67) !!

`paginate(scope)` is not a data-fetch step — it assigns `@page` (never a
model-named ivar) and internally calls `respond_to { format.turbo_stream;
format.html }`, i.e. it renders the response. Every ivar the view needs
(`@page_title`, `@turbo_tbody_id`, `@load_more_id`, `@index_path`) MUST be
set BEFORE calling it — it must be the last line of the action.
See RAILS_SPECIFICS.md v3.6 for the full rule and the actual concern source.

---

## !! RAILS ENUM — read_attribute DOES NOT BYPASS TYPE-CASTING (learned Session 67) !!

To get the raw stored value of an enum column ("a"/"m"), use
`<attribute>_before_type_cast` — NOT `read_attribute(:<attribute>)`, which
still returns the mapped label ("added"/"modified"). See RAILS_SPECIFICS.md
v3.6 for the full rule.

---

## !! COLLECTION ROUTES IN A NAMESPACED resources BLOCK — A SECOND PREFIX SHAPE (learned Session 67) !!

A `collection do get :foo end` route nested inside `resources` already
inside `namespace :admin` prepends the action name to the already-prefixed
resource name (`download_manual_admin_component_suggestions_path`) —
DIFFERENT from a custom `as:` route declared directly in the namespace
(Session 65's `admin_foo_path` shape). Always verify with
`bin/rails routes | grep <name>` — never assume either shape.
See RAILS_SPECIFICS.md v3.6 for the full rule.

---

## !! FLAGGING A GUESS DOES NOT SATISFY NEVER-GUESS (learned Session 67) !!

Writing a file from general convention and labeling it "inferred, please
verify" is still a Never-Guess violation — it shifts verification burden
onto the user instead of Claude asking for the real file. See
COMMON_BEHAVIOR.md v2.8 for the full rule and the real example.

---

## !! SYSTEM TESTS — BROWSER-LAYER LOGIN (learned Session 59) !!

`login_as` (AuthenticationHelper) posts to the Rails Rack adapter. It sets a
session cookie on the Rack test adapter — NOT on the Selenium browser process.
System tests run a real Chrome instance; its cookie jar is completely separate.

**Rule:** Never call `login_as` from a system test file.
Use `sign_in` (defined in ApplicationSystemTestCase v1.3) instead.
`sign_in` drives the real login form through the browser.

See `decor/test/application_system_test_case.rb` v1.3 for implementation.

---

## !! SYSTEM TESTS — CAPYBARA ASSERTION PATTERNS (learned Session 60) !!

### assert_selector with a message string raises ArgumentError

Capybara's `assert_selector` does NOT accept a plain string as its second
positional argument. It raises:
```
ArgumentError: Unused parameters passed to Capybara::Queries::SelectorQuery
```

**Wrong:**
```ruby
assert_selector "input[name='user_name']", "Login form must have this field"
refute_selector "select[name='barter_status']", "Must not be rendered"
```

**Correct — route the message through Minitest's assert:**
```ruby
assert page.has_css?("input[name='user_name']"),    "Login form must have this field"
assert page.has_no_css?("select[name='barter_status']"), "Must not be rendered"
```

Same rule applies to `assert_text "text", "message"` → `assert page.has_text?("text"), "message"`.

### Capybara select(value) matches by TEXT, not by value= attribute

`select "994812667", from: "software_name_id"` raises ElementNotFound because
Capybara looks for an `<option>` whose visible text is "994812667", not one
whose value attribute is "994812667".

**Wrong:**
```ruby
first_option_value = select_el.all("option").first&.value
select first_option_value, from: "field_name"
```

**Correct — select by element, not by text or value string:**
```ruby
first_option = select_el.all("option").reject { |o| o.value.empty? }.first
first_option.select_option
```

To assert the selection persists after form submit, use has_select? with text:
```ruby
assert page.has_select?("field_name", selected: first_option.text, wait: 5)
```

### Filter forms in Turbo Frames — URL does not update

The software_items, components, and computers filter forms are inside Turbo
Frames. After submitting a filter, the frame content updates but the top-level
URL stays at the bare path (e.g. `/software_items`). URL-based assertions fail.

**Wrong:**
```ruby
within("form[method='get']") { find("[type=submit]").click }
assert_includes current_url, "query=vms"
```

**Correct — assert form field value instead of URL:**
```ruby
click_button "Apply"
assert page.has_field?("query", with: "vms", wait: 5),
  "Query field must reflect submitted value after filter applies"
```

For select filters, use has_select? with option text:
```ruby
click_button "Apply"
assert page.has_select?("sort", selected: first_option.text, wait: 5)
```

### Turbo navigation race in sign_in / sign_out

`form_with` without `local: true` submits via Turbo (async fetch). Calling
`current_path` immediately after `find("[type=submit]").click` races the redirect.

Fix: wait for the login form to disappear before returning from sign_in.
Fix: wait for the sign-out button to disappear before returning from sign_out.

See `application_system_test_case.rb` v1.3.

### <template> elements not findable via assert_selector

HTML `<template>` elements are not part of the live rendering tree. Even with
`visible: :all`, Capybara/Selenium cannot find them via CSS selectors.

**Correct — use evaluate_script:**
```ruby
template_present = evaluate_script(
  "document.querySelector(\"[data-connection-members-target='template']\") !== null"
)
assert template_present, "Form must render the template Stimulus target"
```

---

## !! SYSTEM TESTS — SIGN-OUT LINK MUST BE IN THE NAV (learned Session 60) !!

The `sign_out` helper in ApplicationSystemTestCase clicks a "Sign out" link.
The nav partial (`decor/app/views/common/_navigation.html.erb`) must include
this link inside the `<% if logged_in? %>` block:

```erb
<%= link_to "Sign out", session_path,
      data: { turbo_method: :delete },
      class: "font-medium text-stone-700 hover:text-stone-900" %>
```

Without this link, every system test that calls `sign_out` raises ElementNotFound.
The link was added in v2.3 of the navigation partial.

---

## !! DRY RULE — ALL passwords must use AuthenticationHelper constants !!

`TEST_PASSWORD_CHARLIE = "DecorTest2026!"` added to AuthenticationHelper v2.1.
**No literal password strings are permitted anywhere in the test suite.**
All test files must use:
  TEST_PASSWORD_ALICE   — owners(:one)
  TEST_PASSWORD_BOB     — owners(:two)
  TEST_PASSWORD_CHARLIE — owners(:three)
  TEST_PASSWORD_VALID   — dynamically created owners

---

## !! UI Renames — Rails auto-generates strings from model/column names (learned Session 58) !!

When renaming a concept in the UI, `<h1>` headings alone are not enough.
Also check and override explicitly:
  1. `f.submit`        — derives label from model class name
  2. `f.label :col`   — derives text from column name
  3. Index column headers, show labels, titles, breadcrumbs
  4. Flash notices that reference the field or model name
See RAILS_SPECIFICS.md v3.3 "UI Renames" section for full checklist with examples.

---

## !! FILE TRANSFER PROTOCOL — export/import scripts, @-encoded flat names !!

Session 71 replaced the old "Output Path Collision" rule (and the old
Download File Naming / Upload File Naming rules) with a single scheme: Claude
generates a shell script to export needed files into `decor/export/` (run from
inside that directory) and a placement script for delivered files staged in
`decor/import/`, both using @-encoded flat filenames (full path, `/`→`@`, all
dots except the true extension→`@`). `decor/export/` and `decor/import/` are
both gitignored. See COMMON_BEHAVIOR.md v3.0 "File Transfer Protocol —
Export/Import Scripts" for the full rule.

---

## !! OUTPUT FILE NAMING — NEVER substitute underscores for dots !!

See COMMON_BEHAVIOR.md v2.7 for the full rule.

---

## !! FIXTURE DELIVERY RULE !!

Whenever a fixture file is modified, upload it to verify before closing the session.

---

## !! NEVER GUESS RULE (added Session 39) !!

Before writing any code or test that depends on a value, path, method name,
or behaviour in the codebase: READ THE FILE.

---

## !! REMOVE ROUTES AFTER VIEWS (learned Session 41) !!

When removing a route, always update the views that call that path helper FIRST.

---

## !! MANUAL DATA MIGRATIONS — CHECK ALL TABLES (learned Session 42) !!

When running a manual data migration that changes an enum value, grep for ALL
tables that share that enum/column before assuming the migration is complete.

---

## !! before_action :set_resource — ALWAYS scope with only: (learned Session 46) !!

When a controller has new/create actions alongside show/edit/update/destroy,
the set_resource before_action MUST be scoped with only: %i[show edit update destroy].

---

## !! paginate — NEVER assign the return value (learned Session 48) !!

`paginate scope` — no assignment. `@page = paginate(scope)` overwrites @page with nil.

---

## !! EXPORT/IMPORT — ALWAYS include a stable unique key (learned Session 49) !!

Every exported record type must carry a stable unique field for duplicate detection.
See PROGRAMMING_GENERAL.md v2.0 for the full rule.

---

## !! RESPONSE BODY ASSERTIONS — Use assert_body_includes (learned Session 50) !!

In integration tests, NEVER use `assert_match(text, response.body)` or
`refute_match(text, response.body)`. Use `assert_body_includes` /
`refute_body_includes` from ResponseHelpers instead.
See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! FILTER TESTS — assert/refute on data-row values only (learned Session 50) !!

When testing that a filter excludes an item, never refute_match on a name that
also appears in the filter sidebar's <option> elements.

---

## !! data-turbo="false" — NEVER wrap Turbo-method links inside it (learned Session 53) !!

See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! CSS grid grid-cols-N — Equal columns hide overflowed links (learned Session 53) !!

See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! before_validation vs before_save (learned Session 56) !!

If a model generates a field via callback AND validates it for presence, the
callback MUST be `before_validation` — NOT `before_save`.
See RAILS_SPECIFICS.md v3.3 for the full rule.

---

## !! Mailer views directory — Check existing structure first (learned Session 56) !!

This project stores mailer views under `app/views/mailers/<mailer_name>/`.
Always grep for existing mailer views before creating a new directory.

---

## !! deliver_later vs deliver_now — Admin tools use deliver_now (learned Session 56) !!

`deliver_later` hands off to ActiveJob — letter_opener never intercepts it.
For admin-initiated sends, use `deliver_now`.

---

## !! Email HTML — Gmail strips data: URIs (learned Session 57) !!

See RAILS_SPECIFICS.md v3.3 "Email HTML" section for full rules.

---

## !! ActionMailer::TestHelper in integration tests — include explicitly (learned Session 58) !!

ActionDispatch::IntegrationTest does NOT include ActionMailer::TestHelper
automatically. Include it explicitly in any test file using assert_emails.

---

## !! Newsletter fixture html_body — Set explicitly (learned Session 58) !!

Rails fixture loading bypasses model callbacks. Always set html_body explicitly.

---

## !! Admin update tests — include admin: "true" when updating self (learned Session 58) !!

See SESSION_HANDOVER v64.0 for the full rule.

---

## !! CI SECURITY CHECKS — bundle-audit reports in batches, confirm clean locally (learned Session 64, reinforced Session 72) !!

`CI/Security (Ruby)` is `bundle-audit` (dependency CVE scan), NOT Brakeman
(static code scan) — two separate CI jobs. If `CI/Security (Ruby)` fails,
pull the actual CI log (`gh run view <run-id> --log-failed -R <owner>/<repo>`)
rather than assuming it's the same tool as a clean local `bin/brakeman` run.

**Session 72 reinforcement:** the `feature/owner_part_number` PR failed
`CI/Security (Ruby)` on four gems simultaneously in one batch: `loofah`
(2.25.1 → needed >= 2.25.2), `rails-html-sanitizer` (1.7.0 → >= 1.7.1),
`sqlite3` (2.9.1 → >= 2.9.5), `websocket-driver` (0.8.0 → >= 0.8.2). Fixed
with `bundle update loofah rails-html-sanitizer sqlite3 websocket-driver`,
confirmed clean with a full local `bundle exec bundle-audit check --update`
before re-pushing. See "Session 72 Summary" below for the full incident.

---

## Note for next session — Documentation Compression Experiment (after Session 73's main work)

After Session 73's Category Help Pages feature was delivered and this rule
set updated, Ulli asked whether the rule documents could be shrunk ~30%
without losing much. Findings and status, for whoever picks this up:

- **Confirmed real bloat, not just an impression:** `RAILS_SPECIFICS.md` has
  a stray `**End of RAILS_SPECIFICS.md**` marker mid-file (~line 1761 in the
  v3.7 delivered this session) with ~140 more lines appended after it (the
  System Tests Capybara section) — content was tacked on past a false "end"
  in some past session and never noticed. Separately, `SESSION_HANDOVER.md`
  had 32 `!! BANNER !!` sections, several of which fully restated rules
  already documented in complete detail in `RAILS_SPECIFICS.md`, plus 10
  full `## Session N Summary` narratives that duplicate feature detail
  already carried in `DECOR_PROJECT.md`.
- **Drafted a compressed `SESSION_HANDOVER.md` as a proof of concept** —
  delivered as `SESSION_HANDOVER_COMPRESSED_DRAFT.md` (1,490 → 788 lines,
  ~47% reduction). Approach: turned duplicate-content banners into short
  pointers into `RAILS_SPECIFICS.md`, and compressed the resolved historical
  session summaries (65, 66, 67, 69, 70, 72) down to what shipped + the one
  durable lesson + a pointer, while leaving Session 73 (open), the GAP
  NOTICE, and Sessions 59/61 (whose design rationale isn't duplicated
  elsewhere) untouched.
- **Status: NOT adopted.** This draft was for Ulli to compare against the
  real `SESSION_HANDOVER.md` before treating it as the working file — that
  review had not happened when the session ended on a token-limit warning.
  **Do not assume the compressed draft is in effect** — the full
  `SESSION_HANDOVER.md` (this file, v73.0) remains authoritative until Ulli
  confirms the draft (or a revised version of it) should replace it.
- **Not yet started:** the equivalent compression pass on `RAILS_SPECIFICS.md`
  (fixing the duplicate-`End of` bug alone recovers ~140 lines) and on
  `DECOR_PROJECT.md` (whose closed-out feature sections have similar
  "Session N update: this is now done" annotations bolted onto full original
  narratives).
- **Next session should:** ask Ulli whether the compressed draft looked
  right, and only then either adopt it (bump `SESSION_HANDOVER.md`'s version,
  replace it) or revise it further — before doing the same pass on the other
  two documents.

Unrelated: the Session 73 Category Help Pages feature itself is still
sitting at "code-complete, not yet tested/committed" — see its own checklist
in the summary immediately below. That work is independent of the
documentation-compression question above and still needs the standard
pre-commit checklist run.

---

## Session 73 Summary — Category Help Pages feature: implemented, code-complete, not yet tested/committed

**5 new owner-facing help pages (Computers, Peripherals, Components,
Connections, Software), built entirely on top of the existing `SiteText`
generic text-page subsystem. No migration.** 7 files delivered (5
production, 2 test).

### What this request turned out to need

Before writing anything, `decor/app/models/site_text.rb`,
`decor/app/controllers/site_texts_controller.rb`,
`decor/app/controllers/admin/site_texts_controller.rb`,
`decor/config/routes.rb`, `decor/app/views/common/_navigation.html.erb`,
`decor/app/views/layouts/admin.html.erb`, the three
`decor/app/views/admin/site_texts/*.html.erb` views,
`decor/app/views/site_texts/show.html.erb`, `decor/db/schema.rb`, and
`decor/test/controllers/admin/site_texts_controller_test.rb` were all
requested and read directly (Never-Guess / Pre-Implementation
Verification — via the File Transfer Protocol export script). This
confirmed `SiteText` is a generic `key`/`content` model whose `KNOWN_TEXTS`
constant is the actual single source of truth driving every admin
selector — meaning the 5 new pages needed no schema change at all, just 5
new `KNOWN_TEXTS` entries + 5 new routes + 5 new nav links.

**Also surfaced a real documentation gap while reading:** `SiteText` had
never appeared anywhere in DECOR_PROJECT.md's "Data Model Overview" despite
existing since Session 18 — the same shape of gap as the still-open Session
68 issue (see GAP NOTICE above), just for a different model. Closed this
one: added a full "SiteText" entry to DECOR_PROJECT.md's Data Model
Overview this session.

### Two pre-existing bugs found and fixed (not new bugs from this session's own additions)

1. **`site_texts_controller.rb` (owner-facing) — stale `title_for_key`.**
   Session 20 introduced `SiteText.title_for_key` / `KNOWN_TEXTS` as the
   single source of truth for page titles, but that refactor only touched
   the admin controller — the owner-facing controller kept its own private
   `title_for_key` hash with only `"readme"` hardcoded, falling back to
   `key.titleize` otherwise. This coincidentally produced correct output for
   the 4 pre-existing keys (`.titleize` of "news"/"barter_trade"/"privacy"
   happens to match their configured titles) but would have shipped the
   WRONG title for the new pages (`"help_computers".titleize` → "Help
   Computers", not "Computers Help"). Fixed (v1.1) by deleting the private
   method and delegating to `SiteText.title_for_key`.
2. **`admin/site_texts_controller.rb` — hardcoded `url_for_key` case
   statement.** Required manual editing every time a `KNOWN_TEXTS` entry was
   added — the same "touch N places, miss one" trap as the Session 64
   admin-nav-menu gap and the Session 68 documentation gap. Every existing
   route's `as:` name is identical to its key, so this was generalized
   (v1.3) to a single `send("#{key}_path")` call, rescuing `NoMethodError`
   back to `root_path`. No future `KNOWN_TEXTS` addition should need to
   touch this file again for this purpose.

Both were caught by actually reading the files rather than assuming the
Session 20 refactor had been applied everywhere — see DECOR_PROJECT.md
"Category Help Pages Feature — Session 73" for the full write-up.

### New keys, titles, routes

    Key                  Title                Route helper
    help_computers       Computers Help       help_computers_path
    help_peripherals     Peripherals Help     help_peripherals_path
    help_components      Components Help      help_components_path
    help_connections     Connections Help     help_connections_path
    help_software        Software Help        help_software_path

Owner-facing: new links in the "Info" dropdown (`_navigation.html.erb`),
below a new divider separating them from the 4 pre-existing general-info
links; dropdown widened `w-36` → `w-48` (the new labels are longer than any
existing entry and would wrap at the old width). Admin-facing: **zero
changes needed** to `admin.html.erb`'s "Texts" dropdown or any of the three
admin `site_texts` views — all already iterate `KNOWN_TEXTS` generically, so
the 5 new entries appear automatically in Upload/Download/Delete.

### Files delivered (7: 5 production, 2 test; 0 migrations)

    decor/app/models/site_text.rb                            v1.1 → v1.2
    decor/app/controllers/site_texts_controller.rb            v1.0 → v1.1
    decor/app/controllers/admin/site_texts_controller.rb      v1.2 → v1.3
    decor/config/routes.rb                                    v3.6 → v3.7
    decor/app/views/common/_navigation.html.erb                v2.4 → v2.5
    decor/test/controllers/admin/site_texts_controller_test.rb v1.1 → v1.2
    decor/test/controllers/site_texts_controller_test.rb      NEW (v1.0)

### Test Coverage Check (per PROGRAMMING_GENERAL.md, offered proactively)

`site_texts_controller_test.rb` had never existed for the owner-facing
controller — flagged and written from scratch (3 tests: content render,
empty-placeholder path, and a regression test specifically proving the
`title_for_key` fix using the `help_computers` key). The admin controller
test file was extended with 2 new tests that deliberately use
`help_computers` — a key the OLD hardcoded `case` statement never
special-cased — so a regression back to the old code, or a typo in the new
`send("#{key}_path")` call, would fail these specific tests even though
tests against the 4 pre-existing keys would still pass. `site_text.rb`
(data-only change) and `_navigation.html.erb` (view/CSS only) needed no new
tests.

### Open item raised, not yet resolved

Whether `render_markdown` (in `application_helper.rb`, not reviewed this
session) enables Redcarpet's `:with_toc_data` extension — required for
Markdown header `id=` attributes, which in turn is required for in-page
anchor links (e.g. `[Trade Status](#trade-status)`) to work on any of the 5
new help pages. Raised when Ulli asked how to link to a multi-word Markdown
header; answered the general Markdown convention (lowercase, hyphenated)
but flagged that whether it actually works here depends on a file not yet
reviewed. Worth checking during the manual browser check below if any new
page is written with an in-page table of contents.

### NOT YET DONE — required before this feature can be committed

    [ ] Place the 7 delivered files into the actual project (via the
        Session 73 placement script, decor/import/place_session_73_files.sh)
    [ ] Upload actual Markdown content for the 5 new keys via Admin > Texts >
        Upload Text (pages currently show "== Empty ==")
    [ ] bin/rails test
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check: all 5 new Info dropdown links; admin
        Upload/Download/Delete selectors show the 5 new entries;
        help_computers_path renders "Computers Help" as its heading
        (regression check for the title_for_key fix); confirm whether
        render_markdown supports header anchors if a TOC is wanted on any
        new page
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

---

## Session 72 Summary — CI Security (bundle-audit) fix, merge, and deploy; all prior stacked sessions confirmed committed

**This session closed out the `feature/owner_part_number` branch (Session
70's Owner Part Number feature) and, per Ulli's confirmation, resolved the
"four sessions' worth of uncommitted local work" situation described
throughout this document.**

### Ulli's confirmation (this session)

Ulli confirmed that Sessions 67 (Component Suggestions Phase 4), 68
(Component Suggestions UI refinements — the session with the still-unresolved
missing-summary documentation gap, see the GAP NOTICE above), 69 (UI
Terminology Rename), and 70 (Owner Part Number feature) have ALL already been
committed, pushed, merged, and deployed to `main` — this had simply not been
communicated to Claude in prior sessions. **All "NOT YET committed/pushed/
deployed" and "sitting locally, uncommitted" language throughout this
document (Sessions 67, 69, 70 summaries, the Date/Branch/Status block above)
describes a state that no longer applies as of this session.** The
documentation gap around Session 68's missing formal summary is a separate,
still-open item — it is a paper-trail gap only, not a code/deployment gap.

### This session's own work — CI Security (Ruby) failure on the Owner Part Number PR

After Session 70's `bin/rails db:migrate`, `bin/rails test`,
`bin/rails test:system`, `bundle exec rubocop -A`, and `bin/brakeman
--no-pager` all passed, the branch was pushed and a PR opened
(`feature/owner_part_number`). `gh pr checks --watch` showed 4 of 5 checks
green, with `CI/Security (Ruby)` failing.

Per the "CI Security Checks — Two Separate Tools" rule (RAILS_SPECIFICS.md /
this document's own banner above), this was correctly NOT assumed to be
Brakeman (which had already passed locally) — the actual CI log was pulled
via `gh run view <run-id> --log-failed`, which confirmed `bundle-audit` as
the failing tool, batch-reporting four vulnerable gems at once:

    loofah                2.25.1  → >= 2.25.2  (3 advisories: javascript: URI
                                                 bypass ×2, SVG href bypass)
    rails-html-sanitizer  1.7.0   → >= 1.7.1   (possible XSS)
    sqlite3               2.9.1   → >= 2.9.5   (2 use-after-free CVEs)
    websocket-driver       0.8.0   → >= 0.8.2   (4 advisories: memory
                                                 exhaustion ×2, resource-limit
                                                 bypass, malformed-Host DoS —
                                                 the last one specifically
                                                 required 0.8.2, not just 0.8.1)

Fixed with `bundle update loofah rails-html-sanitizer sqlite3
websocket-driver`; confirmed clean with a full local `bundle exec
bundle-audit check --update` ("No vulnerabilities found") before pushing the
fix commit, per the "bundle-audit reports in batches" rule — the fix was not
assumed complete just because it addressed everything the first CI failure
showed.

Pushed, `gh pr checks` re-run (confirmed a new run ID, not a stale
re-display), all 5 checks green. Merged with `gh pr merge --merge` (regular
merge, per project convention), switched back to `main`, pulled, deleted the
local and remote feature branch, deployed with `kamal deploy`.

### Net result of this session

- Sessions 67, 68 (code only), 69, and 70 — all now confirmed live on `main`
  and deployed.
- Four additional gem CVEs (independent of any Session 67–70 code) fixed as
  part of getting this PR's CI green: `loofah`, `rails-html-sanitizer`,
  `sqlite3`, `websocket-driver`.
- Per the RAILS_SPECIFICS.md "Scope note" on CI Security Checks, these four
  gem bumps are now part of `main`'s baseline via this merge — no separate
  Dependabot reconciliation needed since this branch's merge already carries
  the fix forward.

### Outstanding items after this session

- **Session 68's missing formal SESSION_HANDOVER.md/DECOR_PROJECT.md summary**
  — a documentation-only gap, not a code gap; the underlying UI refinement
  code is live on `main` per Ulli's confirmation above. Left open for Ulli to
  decide whether it's worth reconstructing from source/git history, since the
  code itself needs no further action.
- No other checklist items remain open from Sessions 67, 69, or 70 — all
  their individual "NOT YET DONE" lists (below, in their own summaries) are
  now satisfied and are left in place as historical record with a note added
  to each rather than deleted, per the project's practice of dating and
  preserving lessons learned.

---

## Session 70 Summary — Owner Part Number feature: IMPLEMENTED, unmigrated/untested

> **Session 72 update:** Ulli confirmed this feature has since been fully
> migrated, tested, lint/security-scanned, committed, pushed, merged, and
> deployed to `main` — see "Session 72 Summary" above. The checklist and
> narrative below are left as the historical record of what was true at the
> close of Session 70 itself; do not read the "NOT YET DONE" list at the
> bottom of this section as still current.

**Code-complete, 11 of 12 planned files delivered. NOT run against a real
database, NOT tested, NOT lint/security-scanned.** Picks up directly from
Session 69's three open design questions — all three answered by Ulli this
session and implemented.

### Confirmed answers and how each was implemented

**1. Uniqueness scope — kept the existing model/type dimension**, per Ulli's
explicit instruction, over the alternative (plain per-owner scope) that was
also on the table. New combined uniqueness:
`(owner, computer_model, owner_part_number, serial_number)` on Computer,
`(owner, component_type, owner_part_number, serial_number)` on Component.
Implemented as a widened `uniqueness: { scope: [...] }` Rails validation on
each model's `serial_number`, backed by a new 4-column unique DB index on
each table (migration 20260716000200).

**2. Presence + defaulting, symmetric across both models/fields** — Ulli
confirmed both `Computer#serial_number` and `Component#serial_number` must
never be blank, both default to `"-"`, and Owner Part Number gets the same
treatment on both models. `Component#serial_number`'s previous
`allow_blank: true` is REMOVED (Component's original asymmetry vs Computer
is now gone). All four default-assignments use `before_validation` — NOT
`before_save` (RAILS_SPECIFICS.md "before_validation vs before_save": a
`before_save` default would run AFTER the presence validation and the blank
value would be rejected first).

**3. Spares collision — Ulli asked directly for a SQL script fixing this,
with placeholder format `"SPARE-#{component.id}"` confirmed.** Implemented
as a two-migration sequence (data-cleaning migration, then a separate
constraint-adding migration, per PROGRAMMING_GENERAL.md's 3-Step Safe
Process):
  - Migration 1 (`20260716000100`): adds both nullable columns, backfills
    blank `Component#serial_number` to `"-"`, detects every
    `(owner_id, component_type_id)` group with 2+ dash-serial components,
    assigns each member of a colliding group a distinct
    `"SPARE-#{component.id}"` (globally unique via `component.id`, no
    per-group counter needed), then blanket-backfills everything else
    (including all of `computers`, which has no collision risk since
    `Computer#serial_number` was already unique per owner+model) to `"-"`.
  - Migration 2 (`20260716000200`): full SQLite table-recreation for both
    `computers` and `components` (explicit column lists, no `SELECT *`) to
    add the `NOT NULL` constraints and swap in the new 4-column unique
    indexes — required because SQLite cannot `ALTER COLUMN` to add
    `NOT NULL` to an already-nullable column.

  **Raised and resolved a design gap in Ulli's proposed fix**: a one-time
  backfill alone doesn't address what happens with the NEXT unserialized
  spare added after the migration runs. Presented as Option A (model-level
  auto-assign of a fresh unique placeholder, mirroring the existing
  `owner_group_id`/`owner_member_id` auto-assign pattern) vs Option B (no
  auto-assign — the constraint simply blocks a second dash/dash spare of the
  same type/owner going forward, requiring the user to supply a real
  distinguishing value themselves). **Ulli confirmed Option B.** This is a
  real, user-visible behaviour change from today, not just an implementation
  detail — flagged clearly in both `component.rb` v1.6's header comment and
  here.

**4. CSV export/import** — Ulli's original request also named
`computer_model_export_service.rb`; this was flagged as a likely mismatch
(that service exports `ComputerModel` catalog/reference data — model names
only — with no relationship to per-instance `owner_part_number` values) and
Ulli confirmed it should be left untouched. `owner_export_service.rb` v1.11
and `owner_import_service.rb` v1.12 were updated instead.

### An import-side consequence surfaced during implementation, not asked, worth knowing

`OwnerImportService` previously never deduplicated blank-serial component
rows at all — the old guard `if serial_number && exists?(...)` skipped the
duplicate check entirely whenever `serial_number` was blank, so re-importing
a CSV with several unserialized spares of the same type created a brand new
row every single time. Now that both `serial_number` and `owner_part_number`
normalize to `"-"` on import (matching the model's own default), that guard
was removed and the duplicate check runs unconditionally — a second
identical `"-"/"-"` spare row of the same type in a re-import will now be
silently skipped as a duplicate, exactly like computers and serialized
components already behave. This is a direct, unavoidable consequence of the
Option B decision above, not a separate bug — but worth a one-time sanity
check against any CSV exported before this migration if Ulli re-imports
spare-heavy historical data.

### Files delivered this session (11 of 12 planned)

    decor/db/migrate/20260716000100_add_owner_part_number_to_computers_and_components.rb  NEW
    decor/db/migrate/20260716000200_enforce_owner_part_number_constraints.rb              NEW
    decor/app/models/computer.rb                                       v2.1 → v2.2
    decor/app/models/component.rb                                      v1.5 → v1.6
    decor/app/controllers/computers_controller.rb                      v1.22 → v1.23
    decor/app/controllers/components_controller.rb                     v2.0 → v2.1
    decor/app/views/computers/_form.html.erb                           v2.6 → v2.7
    decor/app/views/components/_form.html.erb                          v1.11 → v1.12
    decor/app/services/owner_export_service.rb                        v1.10 → v1.11
    decor/app/services/owner_import_service.rb                        v1.11 → v1.12
    decor/test/fixtures/computers.yml                                  v1.9 → v1.10
    decor/test/fixtures/components.yml                                 v1.4 → v1.5

**Not delivered — the 12th item:** `decor/db/schema.rb` regeneration. This
requires actually running `bin/rails db:migrate` against a real database,
which did NOT happen this session. The two-migration table-recreation logic
— especially the `"SPARE-#{id}"` collision backfill in migration 1 — has
never executed against real data. **This is the single highest-risk
untested part of the whole feature and should be the first thing verified
next session**, before anything else.

### Pre-Implementation Verification note — files gathered this session

Per Never-Guess / Pre-Implementation Verification, no model, controller, or
view file was written from memory or convention this session. Every file
touched was read directly first: `computer.rb`, `component.rb`,
`computers_controller.rb`, `components_controller.rb`, both `_form.html.erb`
files, `owner_export_service.rb`, `owner_import_service.rb`, both
`20260316*` migrations, `schema.rb`, `computers.yml`, `components.yml`.

### Upload-collision hit again this session — RESOLVED Session 71

`computers/_form.html.erb` and `components/_form.html.erb` both mangled to
the identical upload filename `_form_html.erb` (Rails' partial-naming
convention plus the browser's dot-to-underscore substitution on upload).
Uploading them in separate messages (the old "Upload File Naming" rule's
prescription) was NOT sufficient — the mangled name being identical meant
the second upload silently overwrote the first ON DISK mid-session regardless
of message separation, and the first file's content (already viewed) had to
be re-requested and re-uploaded from scratch. This was flagged here as a
stronger failure mode than the old rule anticipated, and formalized in
Session 71: COMMON_BEHAVIOR.md v3.0's new "File Transfer Protocol —
Export/Import Scripts" replaces one-file-per-message with @-encoded flat
filenames (full path, `/`→`@`, all dots except the true extension→`@`),
which structurally prevents this collision — the encoded name always
contains the full path, so two files can never encode to the same name.

### Scope notes — deliberately not touched this session

- The embedded Component sub-table inside `computers/_form.html.erb`
  (Type | Description | Order No. | Serial No. | Condition | Trade) — shows
  each Component's own fields via a separate association; not requested to
  gain an Owner Part No. column, so left as-is. Flagged inline in the file's
  own v2.7 header comment.
- No index/show display views were touched — not requested, not provided
  this session. Owner Part Number is currently only visible on the edit/new
  forms and in CSV export/import.

### NOT YET DONE — required before this feature can be committed

**Session 72 update: ALL items below are now confirmed complete —
`bin/rails db:migrate` was run, the 6 test files were provided/written,
`bin/rails test` and `bin/rails test:system` both passed, `bundle exec
rubocop -A` / `bin/brakeman --no-pager` both ran clean, and the full git
workflow (branch → commit → push → PR → CI → merge → deploy) completed in
Session 72 — including an additional `bundle-audit` gem-CVE fix required to
get CI green, see "Session 72 Summary" above.** Left below as historical
record of what this checklist looked like at the end of Session 70 itself.

    [ ] bin/rails db:migrate                          — never run against a real DB this session
    [ ] decor/db/schema.rb                             — regenerate and review after migrating
    [ ] Tests — 6 test files needed as Pre-Implementation Verification inputs before
        writing test code (Never-Guess): computer_test.rb, component_test.rb,
        owner_export_service_test.rb, owner_import_service_test.rb,
        computers_controller_test.rb, components_controller_test.rb
    [ ] bin/rails test                                 — not run (blocked on migrate + tests above)
    [ ] bundle exec rubocop -A / bundle exec rubocop   — lint fix + verify
    [ ] bin/brakeman --no-pager                        — static code security scan
    [ ] bundle exec bundle-audit check --update        — dependency CVE scan
    [ ] Manual browser check: both new form fields, CSV export/import round-trip
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

    This now stacks on top of Sessions 67/68/69's own already-outstanding
    pre-commit checklists (see their respective summaries below/further down
    in this document) — FOUR sessions' worth of uncommitted local work.

---

## Session 69 Summary — UI Terminology Rename (implemented) + Owner Part Number (design only)

> **Session 72 update:** Part 1 of this session (the UI Terminology Rename)
> has since been committed, pushed, merged, and deployed to `main`, per
> Ulli's confirmation — see "Session 72 Summary" above. The "NOT YET DONE"
> list at the end of Part 1 below is historical.

### Part 1 — UI Terminology Rename: IMPLEMENTED, 15 files

Renamed throughout the owner-facing and admin UI:
"Model" → "Computer Model", "Order Number" → "DEC Part Number",
"Serial Number" → "DEC Serial Number". Display text only — no attribute,
column, or route renamed. Full mapping (including the abbreviated-header
variants and what was deliberately left alone) now recorded in
DECOR_PROJECT.md "UI Terminology — Established Renames (Session 69)" —
**future sessions must use those labels for any new UI, not the legacy
terms.**

Scope was confirmed with the user mid-session: the Admin > Component
Suggestions screens and the two admin.html.erb Components-dropdown menu
links ARE in scope (not just the primary Computer/Component forms).

    decor/app/views/computers/_filters.html.erb                    v1.6 → v1.7
    decor/app/views/computers/index.html.erb                       v1.9 → v1.10
    decor/app/views/computers/_computer_component_form.html.erb    v1.3 → v1.4
    decor/app/views/computers/_computer.html.erb                   v1.10 → v1.11
    decor/app/views/components/_form.html.erb                      v1.10 → v1.11
    decor/app/views/components/show.html.erb                       v1.7 → v1.8
    decor/app/views/components/index.html.erb                      v1.6 → v1.7
    decor/app/views/computer_statistics/index.html.erb             v1.1 → v1.2
    decor/app/views/owners/computers.html.erb                      v1.4 → v1.5
    decor/app/views/owners/peripherals.html.erb                    v1.3 → v1.4
    decor/app/views/owners/components.html.erb                     v1.4 → v1.5
    decor/app/views/admin/component_suggestions/_form.html.erb     v1.0 → v1.1
    decor/app/views/admin/component_suggestions/_filters.html.erb  v1.0 → v1.1
    decor/app/views/admin/component_suggestions/index.html.erb     v1.3 → v1.4
    decor/app/views/layouts/admin.html.erb                         v2.7 → v2.8

Note: `decor/app/views/computers/_form.html.erb` and
`decor/app/views/computers/show.html.erb` needed NO changes — Ulli had
already renamed those two himself before this session started.

**Deliberately left unchanged** (flagged to the user, not yet decided):
- CSV column headers / literal `order_number`/`serial_number` references in
  `data_transfers/show.html.erb` and `admin/bulk_uploads/new.html.erb` —
  these are the actual import/export contract field names.
- The downloaded CSV filename `unvalidated_order_numbers_<date>.csv` in
  `admin/component_order_numbers_controller.rb` — still says the old term;
  not addressed since it's controller/service code, a step beyond "UI
  labels."
- Whether Owner Part Number-style CSV export/import fields should be
  touched — not applicable to this rename (no such field existed yet), but
  raised here since it came up again in Part 2 below.

**NOT YET DONE for this rename:**
    [ ] Grep test/ for hardcoded assertions on "Order Number" / "Serial Number" / "Model"
        text (RAILS_SPECIFICS.md "UI Renames" checklist flags this explicitly) — not yet run
    [ ] bin/rails test — not run this session (no logic changed, but unverified)
    [ ] Manual browser check of all 15 renamed views
    [ ] git workflow — on top of Session 67's already-outstanding checklist below

    (Session 72 update: git workflow item above is now done — see "Session 72
    Summary." The grep-for-hardcoded-assertions and manual-browser-check items
    were folded into Session 70/72's broader `bin/rails test` / manual-check
    passes; not separately itemised, but no rename-related test failures were
    reported.)

### Part 2 — Owner Part Number: DESIGN CONSULTATION ONLY, NOT IMPLEMENTED

No files created or modified for this part. Full detail in DECOR_PROJECT.md
"Owner Part Number Feature — Session 69" — summary here:

Requested: new `VARCHAR(20)` "Owner Part Number" field on `computers`
(covers peripherals) and `components`, defaulting to `"-"`; DEC Serial
Number also backfilled to `"-"` where blank; uniqueness changed from DEC
Serial Number alone to the (Owner Part Number, DEC Serial Number) pair,
scoped per owner.

Before writing anything, `decor/app/models/computer.rb` and
`decor/app/models/component.rb` were read directly (Pre-Implementation
Verification / Never-Guess). This surfaced three open questions, none yet
answered by the user:

1. **Uniqueness scope** — today's constraint is `(owner, computer_model)`
   for Computers / `(owner, component_type)` for Components, not plain
   "per owner" as described. Keep that extra dimension in the new
   constraint, or drop it?
2. **Asymmetric presence today** — `Computer.serial_number` already has
   `presence: true` (can't be blank now); `Component.serial_number` has
   `allow_blank: true` (genuinely can be blank). Confirm this asymmetry
   should persist.
3. **Spares collision risk (real design conflict)** — Components
   intentionally allow multiple unserialized spares of the same type per
   owner today. Defaulting both new fields to `"-"` under a plain
   multi-column uniqueness check would break that — every such spare would
   collide on `"-"`/`"-"`. Recommend exempting `"-"`/`"-"` combinations from
   the uniqueness check (dash-sentinel equivalent of today's `allow_blank`),
   but not yet confirmed.

**Files requested from the user, not yet received:**
    The migration(s) that added serial_number + its unique index (referenced
      in the model comments as 20260316120000 and 20260316110000)
    decor/db/schema.rb (or a fresh schema dump)
    decor/test/fixtures/computers.yml
    decor/test/fixtures/components.yml

**Status: WAITING — do not implement until the three questions above are
answered and the requested files are provided.**

(Session 72 note: all three questions were answered in Session 70 and the
feature is now fully implemented and deployed — see "Session 70 Summary"
above and "Session 72 Summary" further up. This "WAITING" status is
historical.)

---

## Session 67 Summary — Component Suggestions Phase 4: fully implemented

> **Session 72 update:** confirmed committed, pushed, merged, and deployed to
> `main` — see "Session 72 Summary" above. The "NOT YET DONE" checklist at
> the end of this section is historical.

**All four confirmed requirements from Session 66 delivered.** 12 production
files (4 new, 8 updated) + 4 test files updated/added. `bin/rails test`:
900 tests, 0 failures, 0 errors, on the final run this session.

### Files delivered

    decor/db/migrate/20260707000100_add_manual_and_enlarge_description_to_component_suggestions.rb  NEW
    decor/app/models/component_suggestion.rb                                    v1.0 → v1.1
    decor/app/services/component_suggestion_import_service.rb                   v1.0 → v2.0
    decor/app/services/manual_component_suggestions_export_service.rb          v1.0 → v1.1 NEW
    decor/app/controllers/admin/component_suggestions_controller.rb            v1.0 → v1.2
    decor/config/routes.rb                                                      v3.5 → v3.6
    decor/app/views/layouts/admin.html.erb                                      v2.6 → v2.7
    decor/app/helpers/admin/component_suggestions_helper.rb                     NEW
    decor/app/views/admin/component_suggestions/_filters.html.erb              NEW
    decor/app/views/admin/component_suggestions/_component_suggestion.html.erb NEW
    decor/app/views/admin/component_suggestions/index.html.erb                 v1.0 → v1.1
    decor/app/views/admin/component_suggestions/index.turbo_stream.erb         NEW

    decor/test/models/component_suggestion_test.rb                            v1.0 → v1.1
    decor/test/services/manual_component_suggestions_export_service_test.rb   NEW
    decor/test/services/component_suggestion_import_service_test.rb           v1.0 → v2.0
    decor/test/controllers/admin/component_suggestions_controller_test.rb     v1.0 → v1.1

`component_suggestion_export_service_test.rb` needed no changes — the
underlying `ComponentSuggestionExportService` is untouched by Phase 4.

### What each piece does

**Migration:** nullable `manual` VARCHAR(1) column (`"a"` added / `"m"`
modified / `null` untouched bulk-import row, permanent once `"a"`); widened
`description` VARCHAR(100) → VARCHAR(510) for concatenated main+variant text.

**"Download Manual Changes":** new `ManualComponentSuggestionsExportService`
exports every `manual: "a"`/`"m"` row (both together, one CSV) — the
required backup step before a re-import, since the import deletes
everything unconditionally with no preservation. New collection route +
admin.html.erb link.

**Import rewrite (the core fix):** `ComponentSuggestionImportService` v1.0's
per-row `exists?` check (O(n) DB round-trip per row) was the confirmed root
cause of production timeouts at ~55,000 rows. v2.0: `delete_all` +
batched `insert_all(unique_by: :order_number)` inside one transaction — zero
per-row DB reads. Accepted tradeoff: bypasses Rails model validations
entirely (documented in RAILS_SPECIFICS.md); acceptable since the source
data is a trusted external DEC-database export.

**Paginated + filterable admin index:** root cause of the slow page load
confirmed by code review — v1.0 had no pagination and no filtering
whatsoever. Rewritten to match the project's established geared_pagination
"Load more" infinite-scroll pattern (same as software_items/computers/
components), with a new filter sidebar: order_number substring search
(confirmed as substring, not prefix — different use case from the
typeahead's `:matching` scope) + a manual-flag filter.

### create/update manual-flag logic

    create:  manual always set to "added" — permanent, never reverts on later edits.
    update:  manual promoted from nil → "modified" ONLY on a previously-untouched
             row. A row already "added" or "modified" keeps its value unchanged.
    Neither value is accepted as a raw form param — always set explicitly in
    the controller, never in component_suggestion_params.

### Two mistakes made and corrected mid-session — both now codified as rules

1. **Route-naming shape guessed wrong initially.**
   `admin_download_manual_component_suggestions_path` was assumed (matching
   the Session 65 `as:` shape), but the real helper — confirmed by running
   `bin/rails routes | grep download_manual` before shipping — is
   `download_manual_admin_component_suggestions_path`. A collection route
   nested in `resources` inside a namespace prepends the action to the
   already-prefixed resource name, a different shape than a custom `as:`
   route in the same namespace. Caught before shipping because the
   verification step was actually run. New RAILS_SPECIFICS.md v3.6 section.

2. **A file was inferred from convention and flagged rather than requested.**
   `index.turbo_stream.erb` was written from the standard Rails/Turbo
   "append + replace" idiom, explicitly labeled in its own header as
   unverified, and delivered alongside genuinely file-based deliverables.
   The user pointed out this was still a Never-Guess violation despite the
   disclosure. The real file was then requested and uploaded — the guess
   turned out to match exactly, but that was luck, not rule compliance.
   New COMMON_BEHAVIOR.md v2.8 section: "Flagging a Guess Does Not Satisfy
   Never-Guess."

Also one real bug caught by the test suite itself and fixed the same
session: `ManualComponentSuggestionsExportService` used
`read_attribute(:manual)` expecting the raw `"a"`/`"m"` value, but Rails
enum type-casting means `read_attribute` returns the mapped label
(`"added"`/`"modified"`) same as the plain accessor. Fixed with
`manual_before_type_cast`. New RAILS_SPECIFICS.md v3.6 section.

### Also fixed this session (unrelated to Phase 4 logic, but blocking CI)

`bundle-audit` flagged the `json` gem (CVE-2026-54696, transitive
dependency) — fixed with `bundle update json`; `bundle exec bundle-audit
check --update` came back clean afterward. Per RAILS_SPECIFICS.md "CI
Security Checks — Two Separate Tools" scope note, this should also be
reflected on `main` (merge this branch's PR, or merge Dependabot's
equivalent PR if it lands first) so the next branch doesn't inherit the
same failing baseline.

### File-placement friction, worth remembering for future sessions

Several rounds of "tests still failing" during this session turned out to
be the delivered files simply not yet copied into the actual project paths
(old versions of `component_suggestion.rb`, `component_suggestion_import_
service.rb` still in place; the new `manual_component_suggestions_export_
service.rb` not added at all) — not code bugs. Worth a habit for future
sessions: after a "still failing" report, check whether the failure
signatures match "old code still running" (uninitialized constant, wrong
validation limits, missing methods) before assuming a logic bug in the
newly-delivered code.

### NOT YET DONE — required before this can be committed

**Session 72 update: ALL items below are now confirmed complete — see
"Session 72 Summary" above.** Left as historical record.

    [ ] bundle exec rubocop -A / bundle exec rubocop — lint fix + verify (not run this session)
    [ ] bin/brakeman --no-pager                      — static code security scan (not run this session)
    [ ] Manual browser check: filters, Load more, Download Manual Changes link, re-import behavior
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy
    [ ] Confirm main also gets the json gem bump (this PR, or Dependabot's PR, whichever merges first)

---

## Session 66 Summary — Order Number / Variant: design pivot, no implementation

**Design consultation only. No files were created, modified, or committed
this session.**

A full multi-column variant-split design (splitting `order_number` into
main + variant columns on `component_suggestions`, a three-state
`order_number_match_status` on `components`, two-file CSV import/export,
Stimulus typeahead rework, a match-status badge on the component form) was
worked out in complete detail across this session — schema, matching logic,
import/export rules, deletion guards, form behavior — but was set aside
**before implementation began**. Reason: recognized risk of "self-indulgent
featuritis" — added complexity on both the implementation/maintenance side
and the user-facing side, without confirmed need at the scale involved
(~13,000 components / ~46,000 suggestion combinations at the time).

That full design is saved for reference at
`decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md` — **NOT implemented, NOT
the current direction.** Copy this file into the project docs folder if it
isn't already there. Revisit only if the adopted simpler approach (below)
proves insufficient.

### Adopted approach instead (closer to original "Option A" from the design doc)

Main order number + variant are concatenated into **one** `order_number`
string at the DEC-database export stage (e.g. `"DELQA-00"`) — **no bare/
undashed part numbers**; every record has an explicit variant suffix,
`"-00"` for base models. Both descriptions (main + variant) are
concatenated into **one** `description` field using `" | "` as a delimiter
(tested — confirmed not to conflict with any existing data). **No schema
split of `order_number` or `description`** — this is the key simplification
versus the shelved design. Data scope: ~55,000 `component_suggestions`
records after filtering (expanded from ~46,000, tested up from ~85,000
before filtering).

### Confirmed requirements for next session

**1. Migration on `component_suggestions`:**
   a. New nullable `manual` field, two possible values:
      - `"a"` = record added manually (via admin form, not from bulk import)
      - `"m"` = record modified manually (originated from bulk import,
        later hand-edited via admin form)
      - `null` = untouched bulk-import record (the default/normal case)
      Once a row is flagged `"a"`, it **stays `"a"` permanently** — further
      edits never change it to `"m"` (confirmed). Likely implementation:
      `VARCHAR(1)` nullable column + Rails `enum` mapping raw values
      (e.g. `added: "a", modified: "m"`) — confirm exact column type and
      enum declaration syntax against this project's conventions (see
      `device_type`/`barter_status` hash-enum precedent in `computer.rb`)
      when writing the actual migration/model code.
   b. Enlarge `description` column from `VARCHAR(100)` to `VARCHAR(510)` —
      concatenated dual descriptions need more room than the original
      single-description field was sized for.

**2. Admin "Components" dropdown — new download option:**
   CSV export of all `component_suggestions` rows where `manual IS NOT
   NULL` (both `"a"` and `"m"` together, one download). This is the
   **required backup mechanism** for manual work: the import (below)
   deletes these rows unconditionally along with everything else, so an
   admin must download this list **before** running a re-import if they
   want to reapply manual changes afterward. Exact CSV columns and the
   menu label were not finalized this session — decide at implementation
   time (likely: `order_number, description, category, manual`, following
   the pattern of the existing "Download Unvalidated Order Numbers"
   feature from Session 65).

**3. Import service — full rewrite (root cause of production timeout):**
   Confirmed root cause: the current import checks every incoming row for
   a conflict against existing records — an O(n) lookup per row against a
   table that only grows, which is exactly why it times out in production
   and takes minutes locally even before scaling further.
   a. **Delete ALL existing `component_suggestions` records
      unconditionally** — including `"a"`/`"m"` manual rows. **No
      preservation logic of any kind** (confirmed — the download in
      item 2 is the intended backup step, to be run by the admin *before*
      triggering a re-import, not automated by the import itself).
   b. **Bulk-insert all new records.** The only constraint is
      `order_number` uniqueness, already enforced by SQLite's existing
      unique index — **no app-level duplicate pre-check is needed at all**.
      Replace whatever per-record `find_or_create_by`/conflict-check loop
      exists with a batched `insert_all` (or equivalent bulk-insert
      approach) to eliminate the O(n²) behavior entirely. This is the
      single highest-value fix from this session's findings.
   This is the right design **because the data's source of truth is the
   external DEC database** — Rails' `component_suggestions` table is a
   disposable, fully-regenerated mirror of it on every import, not a
   record that needs reconciliation against prior state.

**4. Admin suggestions index/listing page is slow to LOAD** (once loaded,
   performance is fine — this is a load-time issue only, not a rendering
   or interaction issue). Root cause **not yet diagnosed** — needs the
   actual controller and view files to investigate. Candidates to check
   first: missing pagination (geared_pagination gem is used elsewhere in
   this project — confirm it's actually applied here), a missing DB index
   backing a sort/filter/search column at ~55,000 rows, or an N+1
   association load in the index action.

### Files needed at start of next session (not yet reviewed this session)

```
decor/db/migrate/20260511000100_create_component_suggestions.rb
decor/app/models/component_suggestion.rb
decor/app/services/component_suggestion_import_service.rb
decor/app/services/component_suggestion_export_service.rb
decor/app/controllers/admin/component_suggestions_controller.rb
decor/app/views/admin/component_suggestions/index.html.erb
decor/app/views/layouts/admin.html.erb
decor/config/routes.rb
decor/test/fixtures/component_suggestions.yml
```

(As of Session 71, prefer the File Transfer Protocol — export/import scripts
with @-encoded flat filenames — over manually uploading these one at a time;
see COMMON_BEHAVIOR.md v3.0.)

(Session 72 note: this design pivot was subsequently implemented in Session
67 and is deployed — see "Session 67 Summary" above and "Session 72
Summary" further up. This section is left as historical record of the
decision-making process.)

---

## Session 65 Summary

**Focus: Component order_number bulk maintenance — two new items in the admin
Components dropdown.**

### Confirmed design decisions (from Ulli, before implementation)

    Re-validate applies immediately — no preview step (bulk data-integrity sync).
    Download list — one row per component, NOT deduplicated by order_number.
    Menu placement — existing Components dropdown, not a new dropdown.

### Files delivered this session (8 files)

    decor/config/routes.rb                                                v3.4 → v3.5
    decor/app/controllers/admin/component_order_numbers_controller.rb     v1.0  NEW
    decor/app/services/component_order_number_revalidation_service.rb     v1.0  NEW
    decor/app/services/unvalidated_order_numbers_export_service.rb        v1.0  NEW
    decor/app/views/layouts/admin.html.erb                                v2.4 → v2.6
    decor/test/services/component_order_number_revalidation_service_test.rb  v1.0 NEW
    decor/test/services/unvalidated_order_numbers_export_service_test.rb     v1.0 NEW
    decor/test/controllers/admin/component_order_numbers_controller_test.rb  v1.0 NEW

Also updated (rule documents, this session):
    decor/docs/claude/RAILS_SPECIFICS.md   v3.4 → v3.5
    decor/docs/claude/DECOR_PROJECT.md     v2.56 → v2.57

### Feature: "Re-validate Order Numbers" (POST /admin/component_order_numbers/revalidate)

Re-syncs `order_number_verified` for every `Component` against the current
`component_suggestions` table: `true` iff `order_number` is present AND
matches a `component_suggestions.order_number`; else `false`. Symmetric — can
flip a component in either direction (e.g. un-verifies a component if its
matching `ComponentSuggestion` was later deleted). Uses `update_column`
(skips validations — this is a data-integrity sync, not a form edit).
Redirects to `admin_component_suggestions_path` with a flash summarising
verified/unverified/unchanged counts.

### Feature: "Download Unvalidated Order Numbers" (GET /admin/component_order_numbers/unvalidated)

CSV export, one row per component (not deduplicated), ordered by component
id, limited to components with a non-blank `order_number` and
`order_number_verified: false`. Columns: `order_number, component_type,
owner, serial_number, description`.

### Bug found and fixed mid-session: NameError in admin.html.erb v2.5

Both new dropdown links used `revalidate_component_order_numbers_path` /
`unvalidated_component_order_numbers_path` — missing the `admin_` prefix that
Rails still applies to `as:` routes declared inside `namespace :admin do ... end`.
Fixed in v2.6. New MANDATORY rule added to RAILS_SPECIFICS.md v3.5: **"Named
Routes (as:) Inside namespace — Still Prefixed."** See that document for the
full rule, including the `bin/rails routes | grep <name>` verification tip.

### Test design notes

All three new test files create `Component` records fresh in-test, assigned
to `owners(:three)` (the project's neutral owner — see RAILS_SPECIFICS.md
"Fixture Ownership"), rather than adding new fixtures. Both new services scan
**every** `Component` row project-wide, so a hardcoded count assertion would
be fragile against the existing `components.yml` fixture set (all of which
have a blank `order_number`). Assertions target either the specific records
each test creates, or `Component.count` derived at call time.

### NOT YET DONE — required before this feature can be committed

    [ ] bin/rails test                              — tests were written but never run
    [ ] bundle exec rubocop -A / bundle exec rubocop — lint fix + verify
    [ ] bin/brakeman --no-pager                      — static code security scan
    [ ] bundle exec bundle-audit check --update      — dependency CVE scan (separate tool — see RAILS_SPECIFICS.md v3.5 "CI Security Checks")
    [ ] Manual browser check of both new Components dropdown links
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

(Session 66 confirmed this session's checklist was completed and this
feature is live — see the "Status update (Session 66)" note in
DECOR_PROJECT.md's Phase 3 section.)

---

## Session 61 Summary

**Focus: Computers Statistics page + Statistics dropdown in the top nav.**

Local testing passed. All existing tests continue to pass.

### Files delivered this session (7 files)

    decor/config/routes.rb                                                v3.1 → v3.2
    decor/app/controllers/computer_statistics_controller.rb               v1.0 → v1.1  NEW
    decor/app/helpers/computer_statistics_helper.rb                       v1.0         NEW
    decor/app/views/computer_statistics/_filters.html.erb                 v1.0         NEW
    decor/app/views/computer_statistics/index.html.erb                    v1.0 → v1.1  NEW
    decor/app/views/common/_navigation.html.erb                           v2.3 → v2.4
    decor/test/controllers/computer_statistics_controller_test.rb         v1.0 → v1.1  NEW

### Feature: Computers Statistics page (`/computer_statistics`)

**Route:** `GET /computer_statistics` → `ComputerStatisticsController#index`
Named helper: `computer_statistics_path`.

**Controller strategy (two queries, Ruby-side sort):**
- Query 1: `Computer.where(device_type: "computer").group(:computer_model_id).count`
  Returns a Hash `{ computer_model_id => Integer }` scoped to actual computers only.
  Peripheral Computer records that reference a computer ComputerModel are excluded.
  (Confirmed in fixtures: `dec_unibus_router` has `computer_model: pdp11_70`.)
- Query 2: `ComputerModel.where(device_type: "computer")` — all computer models.
- Map to `[{ model:, count: }]`, reject count == 0, then sort in Ruby.

**Sort options** (param: `sort`):
- `most_common` (default) — `sort_by { [-count, name] }`
- `least_common`           — `sort_by { [count, name] }`
- `model_asc`              — `sort_by { name }`
- `model_desc`             — `sort_by { name }.reverse`

**Zero-count exclusion:** models with no registered computers are rejected before
the sort step. They do not appear in the table.

**Filter partial** — Search (LIKE by model name) + Sort only. No condition/run-status/
barter filters (those are per-computer attributes, not per-model attributes).

**Table layout:** `w-auto` (not `min-w-full`) so the table shrinks to content width.
Count column is `text-left pl-10` — sits close to the model name column.
Model names link to `computers_path(model: stat[:model].id)` (pre-filters computers
index to that model).

### Feature: Statistics dropdown in the top nav

`_navigation.html.erb` v2.4 — new "Statistics ▾" dropdown appended after "Software"
in the left nav group. Uses the same `data-controller="dropdown"` pattern as "Info".
First (and currently only) entry: "Computers" → `computer_statistics_path`.
Future statistics pages can be added as additional `link_to` entries in this dropdown.

---

## Session 60 Summary

**Focus: System tests — fixed all 48 failures/errors from Session 59 test:system run.**

Final result: **49 tests, 0 failures, 0 errors, 0 skips.**

### Files delivered this session (8 files)

    decor/test/application_system_test_case.rb             v1.1 → v1.3
    decor/app/views/common/_navigation.html.erb            v2.2 → v2.3
    decor/test/system/authentication_test.rb               v1.0 → v1.1
    decor/test/system/computers_filters_test.rb            v1.0 → v1.2
    decor/test/system/software_items_filters_test.rb       v1.0 → v1.2
    decor/test/system/components_filters_test.rb           v1.0 → v1.2
    decor/test/system/connection_groups_test.rb            v1.0 → v1.3
    decor/docs/claude/RAILS_SPECIFICS.md                   v3.2 → v3.3

### Root causes fixed (6 categories)

1. **ArgumentError on Capybara assert_selector** — 17 occurrences across 5 test files.
   `assert_selector "css", "message"` → `assert page.has_css?("css"), "message"`.
   Same for refute_selector → `has_no_css?`, assert_text → `has_text?`.

2. **Turbo navigation race in sign_in** — form_with without local: true submits
   asynchronously. Added `has_no_field?("user_name", wait: 5)` after submit click
   in application_system_test_case.rb.

3. **sign_out had no target link** — the nav partial had no "Sign out" link.
   Added `link_to "Sign out", session_path, data: { turbo_method: :delete }` to
   `_navigation.html.erb` v2.3. Changed sign_out helper to `click_on "Sign out"`.

4. **Capybara select(value) matches by TEXT** — fixture IDs passed as value strings
   never matched. Fixed by using `first_option.select_option` throughout and
   asserting with `has_select?("name", selected: first_option.text, wait: 5)`.

5. **Filter forms in Turbo Frames — URL doesn't update** — replaced all
   `assert_includes current_url, "param="` assertions with `has_field?` /
   `has_select?` assertions that check form state rather than URL.

6. **<template> element not findable via Capybara** — replaced
   `assert_selector "...", visible: :all` with
   `evaluate_script("document.querySelector(...) !== null")`.

### Production change: navigation partial v2.3

Added "Sign out" link to `_navigation.html.erb`. This is visible to all
logged-in users in the top-right nav. Required for system tests but also
correct UX — users previously had no way to sign out from the nav.

---

## Session 59 Summary

**Focus: System tests — Track 1 (JS-dependent interactions) + DRY fix.**

### Files delivered (7 files)

    decor/test/application_system_test_case.rb             v1.0 → v1.1
    decor/test/support/authentication_helper.rb            v2.0 → v2.1
    decor/test/controllers/computers_controller_test.rb    v1.10 → v1.11
    decor/test/system/authentication_test.rb               v1.0  NEW
    decor/test/system/computers_filters_test.rb            v1.0  NEW
    decor/test/system/components_filters_test.rb            v1.0  NEW
    decor/test/system/software_items_filters_test.rb       v1.0  NEW
    decor/test/system/connection_groups_test.rb            v1.0  NEW

---

## Priority 1 — Future Sessions

1. **System tests Track 2** — Tom Select combobox, admin CRUD flows, full auth flow.
2. **Legal/Compliance** — Impressum, Privacy Policy, GDPR, Cookie Consent, TOS.
3. **Account deletion + data export** (GDPR).
4. **Spam / Postmark DNS fix** — awaiting Rob's dashboard findings.
5. **BulkUploadService stale model references** — low priority.
6. **Gmail logo fix (long-term)** — set `config.action_mailer.asset_host` in
   `production.rb` to the app's public hostname.

---

## Connections Feature — Design Reference (updated Session 38)

### Tables

```
connection_groups
  id                  integer  PK
  owner_id            integer  FK → owners.id, NOT NULL
  connection_type_id  integer  FK → connection_types.id, nullable
  label               VARCHAR(100) nullable
  owner_group_id      integer  NOT NULL (≥1, unique per owner)
  created_at / updated_at
  UNIQUE INDEX (owner_id, owner_group_id)

connection_members
  id                   integer  PK
  connection_group_id  integer  FK → connection_groups.id, NOT NULL, ON DELETE CASCADE
  computer_id          integer  FK → computers.id, NOT NULL
  owner_member_id      integer  NOT NULL (≥1, unique per group)
  label                VARCHAR(100) nullable
  created_at / updated_at
  UNIQUE INDEX (connection_group_id, computer_id)
  UNIQUE INDEX (connection_group_id, owner_member_id)
```

### Connections sub-page URL
`/owners/:id/connections` → `connections_owner_path(@owner)`

### Auto-assign rules
- `owner_group_id`: assigned on create as `max(owner.connection_groups.owner_group_id) + 1`
- `owner_member_id`: assigned on create as `max(in-memory siblings, db rows) + 1`
- Guard: `return if field.to_i > 0` — NOT `field.present?` (0.present? is true)

---

**End of SESSION_HANDOVER.md**
