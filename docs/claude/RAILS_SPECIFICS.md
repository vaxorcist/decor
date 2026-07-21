# RAILS_SPECIFICS.md
# version 3.8
# Session 74: Fixed a real structural bug flagged at the end of Session 73's
#   "Documentation Compression Experiment" note: a stray premature
#   "**End of RAILS_SPECIFICS.md**" marker sat at the old line 1761, with the
#   entire "System Tests — Capybara Assertion Patterns" section (and three
#   related System Tests sections, ~140 lines) tacked on AFTER that false
#   "end" in some earlier session and never noticed since. Removed the
#   premature marker; that content now flows as ordinary sections before the
#   one true "End of RAILS_SPECIFICS.md" marker at the actual end of the
#   file. No content was removed, reworded, or reordered — only the stray
#   marker line itself. This was a pure documentation-integrity fix, not a
#   rule change; no session should have been silently missing this section
#   on a `view`-tool read (which truncates past ~16,000 characters anyway,
#   per COMMON_BEHAVIOR.md's Reading Rule Documents section) but a `bash cat`
#   read would have picked up the content either side of the false marker
#   regardless — the bug was cosmetic/structural, not a content-loss risk
#   under this project's mandatory bash cat reading rule. Fixed anyway,
#   since a stray "end of file" marker mid-document is misleading on its own
#   terms. The equivalent compression pass on DECOR_PROJECT.md (per Session
#   73's note) is still pending — not done this session.
# Session 73: Category Help Pages feature. One new MANDATORY section added:
#   Single Source of Truth Refactors — Audit ALL Consumers, Not Just the
#   File Being Changed. Real example: Session 20 introduced SiteType/
#   KNOWN_TEXTS as the single source of truth for page titles, but only
#   updated the admin controller — the owner-facing controller kept its own
#   stale, separately-hardcoded title lookup for 53 sessions until Session
#   73 happened to touch it again and caught the drift via Never-Guess file
#   review, not because anything had broken yet (it hadn't — coincidence
#   papered over it). Same underlying pattern as the Session 65/67 route-
#   helper naming traps and the Session 64 admin-nav-menu gap: a value or
#   piece of logic duplicated in more than one file, where only one copy
#   gets updated when the concept changes.
# Session 67: Phase 4 implementation (order number / variant simplification).
#   Three new MANDATORY sections added from lessons learned this session:
#   1. Collection Routes Nested in a Namespaced Resources Block — Different
#      Prefix Shape Than as: Routes. A second, distinct route-naming trap
#      found in the same file as the Session 65 lesson: a `collection do`
#      route on a `resources` block already inside `namespace :admin`
#      prepends the action name to the ALREADY admin_-prefixed resource name
#      (download_manual_admin_component_suggestions_path), rather than
#      prefixing admin_ onto an action_resource name the way a custom `as:`
#      route does. First guessed wrong (admin_download_manual_..._path),
#      caught only because `bin/rails routes | grep` was run before shipping.
#   2. Rails Enum — read_attribute Does Not Bypass Type-Casting; Use
#      _before_type_cast for the Raw Value. A real bug this session:
#      ManualComponentSuggestionsExportService used read_attribute(:manual)
#      expecting the raw "a"/"m" DB value, but got the mapped "added"/
#      "modified" label instead — read_attribute still goes through the
#      enum's custom type. Fixed with manual_before_type_cast.
#   3. Geared Pagination — paginate() Renders the Response Itself. Read the
#      actual Pagination concern this session for the first time: paginate()
#      sets @page (not an ivar named after the model) AND internally calls
#      respond_to { |format| format.turbo_stream; format.html }, so it must
#      be the last line of the action, after @page_title / @turbo_tbody_id /
#      @load_more_id / @index_path are already set.
# Session 65: Named Routes (as:) Inside namespace — Still Prefixed (NEW MANDATORY
#   section). A custom `as: :foo` route declared inside `namespace :admin do ... end`
#   is STILL prefixed "admin_" by Rails — exactly like `resources` routes in the
#   same namespace. Two new routes (revalidate_component_order_numbers,
#   unvalidated_component_order_numbers) were added correctly in routes.rb, but
#   the corresponding admin.html.erb links called them WITHOUT the admin_ prefix,
#   causing a NameError at render time — even though the same file already had a
#   working example of the correct pattern two dropdowns away (`as: :data_transfer`
#   → admin_data_transfer_path).
# Session 64: CI Security Checks lessons from Component Suggestions PR debugging.
#   1. CI Security Checks — Two Separate Tools (NEW MANDATORY section): Brakeman
#      (static code analysis) and bundle-audit (gem-version CVE scan) are two
#      distinct CI jobs; CI/Security (Ruby) = bundle-audit, NOT Brakeman.
#      Misdiagnosing this cost an entire debugging round-trip in Session 64.
#   2. bundle-audit reports vulnerabilities in batches — fixing what one CI
#      failure shows can unmask more on the next run. Always confirm clean with
#      a full local `bundle-audit check --update` before pushing.
#   3. gh run view --log-failed requires an explicit run ID outside a TTY.
#   4. gh pr checks re-displays the SAME run (same run ID/elapsed time) until a
#      new commit is actually pushed — staging/committing locally isn't enough.
#   Rails Commands Reference updated: added Step 7 (bundle-audit) alongside
#   Step 6 (Brakeman), since they were previously listed as if one scan covered
#   both code and dependency CVE checking.
# Session 60: System test Capybara rules added (see bottom).
# Session 58: One new rule from component_conditions UI rename fix.
#   6. UI Renames — Rails auto-generates strings from model/column names that
#      won't update when you rename a concept in the UI. Full checklist added.
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

**Last Updated:** July 20, 2026 (v3.8: removed a stray premature "End of"
  marker that had ~140 lines of System Tests content tacked on after it,
  unnoticed for several sessions; Session 74)

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

## UI Renames — Rails Auto-Generated Strings (MANDATORY)

**When renaming a concept in the UI, changing the `<h1>` heading is not enough.**
Rails auto-generates display strings from model class names and column names in
several places. These do not update automatically when you rename a concept —
each must be overridden explicitly.

### Full checklist — check every item on every UI rename

**In form partials (`_form.html.erb`):**

1. **`f.submit`** — derives its label from the model class name.
   `ComponentCondition` → "Create Component condition" / "Update Component condition".
   Fix: pass an explicit string.
   ```erb
   <%# Wrong — shows model class name %>
   <%= f.submit class: button_classes(style: :primary) %>

   <%# Correct %>
   <%= f.submit "Save Run Status", class: button_classes(style: :primary) %>
   ```

2. **`f.label :column`** — derives its text from the column name.
   `:condition` → "Condition".
   Fix: pass an explicit string as the second argument.
   ```erb
   <%# Wrong — shows column name %>
   <%= f.label :condition, class: "..." %>

   <%# Correct %>
   <%= f.label :condition, "Status", class: "..." %>
   ```

**In view files:**

3. **`new.html.erb` / `edit.html.erb` `<h1>`** — manual text; update directly.

4. **`index.html.erb` column header** for the renamed field — manual text; update directly.

5. **`show.html.erb` field label** if the field is displayed there — manual text.

6. **`<title>` tags and breadcrumbs** that reference the model or field name.

**In controllers:**

7. **Flash notices** that interpolate the field value directly, e.g.:
   `notice: "#{@component_condition.condition} has been saved."` — the value
   itself is fine (it's data), but surrounding words like "condition" should
   reflect the new name: `notice: "Run status saved."`.

### Why this rule exists (Session 58, May 3, 2026)

`ComponentCondition#condition` was renamed to "Run Status" in the UI. The `<h1>`
headings in `new.html.erb` and `edit.html.erb` were updated, but two auto-generated
strings were missed:
- `f.submit` still showed "Create Component condition" / "Update Component condition".
- `f.label :condition` still showed "Condition" above the input field.
Both required separate fixes after deployment because there is no Rails mechanism
that maps a model/column name to a human display name automatically — the
override must be explicit.

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

Step 6: Run static security scan bin/brakeman --no-pager
Step 7: Run dependency CVE scan  bundle exec bundle-audit check --update
```

**Additional Rails rules:**
- ❌ NEVER run rubocop on `.erb` files — it cannot parse them
- ❌ NEVER check only changed files — CI checks entire project
- Use `bundle exec rubocop -f github` only when debugging CI failures
- **Brakeman and bundle-audit are two separate CI checks, testing two different
  things — see "CI Security Checks — Two Separate Tools (MANDATORY)" below.
  `bin/brakeman` passing locally does NOT mean the CI Security check will pass.

---

## CI Security Checks — Two Separate Tools (MANDATORY, learned Session 64)

GitHub Actions runs **two independent security jobs** under names that look
similar but check completely different things. Confusing them wastes time —
this happened in Session 64 (Component Suggestions PR): a failing
`CI/Security (Ruby)` check was assumed to be Brakeman, `bin/brakeman` was run
locally, came back clean ("No warnings found"), and the real cause
(`bundle-audit` flagging outdated gem versions) wasn't found until the actual
CI log was read.

### The two tools

| CI job name              | Tool             | Checks                                  | Local command                          |
|---------------------------|------------------|------------------------------------------|------------------------------------------|
| `CI/Security (Ruby)`      | `bundle-audit`   | Known CVEs in **gem versions** (incl. transitive deps) in `Gemfile.lock` | `bundle exec bundle-audit check --update` |
| (separate, not yet named in this project's CI list, but exists) | `brakeman`       | Static analysis of **your own code** (SQL injection, mass assignment, XSS, etc.) | `bin/brakeman --no-pager`                |

**Key distinction:** Brakeman scans the code you wrote. `bundle-audit` scans
the *versions* of every gem in `Gemfile.lock` — including gems you never
touched, pulled in transitively by something else. A PR that changes zero
Ruby code can still fail `CI/Security (Ruby)` if any dependency anywhere in
the lockfile has a newly-published CVE.

### Diagnostic rule

If `CI/Security (Ruby)` fails:
1. Do NOT assume Brakeman — `bin/brakeman --no-pager` passing locally proves
   nothing about this check.
2. Get the actual CI log instead of guessing:
   ```
   gh run view <run-id> --log-failed -R <owner>/<repo> > /tmp/fail.log
   tail -60 /tmp/fail.log
   ```
   (`<run-id>` must be passed explicitly when piping to a file — the
   interactive run-picker only works in a TTY; see `gh run view` note below.)
3. If the log shows `Name: <gem>`, `CVE:`, `Solution: update to '>= x.y.z'`
   repeated for several gems, ending in `Vulnerabilities found!` — that's
   `bundle-audit`, not Brakeman.

### Fix pattern

```bash
bundle update <gem1> <gem2> <gem3>   # exactly the gems named in the failure
bundle exec bundle-audit check --update
```

**bundle-audit reports failures in batches, not all at once on a single run.**
Fixing the gems shown in one CI failure can unmask a *longer* list of
previously-hidden advisories on the next run (the scan doesn't necessarily
exit after enumerating only the first N vulnerable gems — different runs can
surface different subsets). Do not assume "fixed what CI showed" means clean.
**Always confirm with a full local `bundle-audit check` run that returns
"No vulnerabilities found" before pushing** — only that output is a reliable
signal the CI job will pass.

### Scope note

These dependency CVEs are typically pre-existing on `main`, unrelated to
whatever feature branch happens to surface them first. It's reasonable to fix
them on the feature branch to unblock the PR, but also bump `main` directly
(or let Dependabot's existing PRs handle it) afterward so the next branch
doesn't inherit the same failing baseline.

---

## `gh run view` — Run ID Required When Not Interactive (learned Session 64)

`gh run view --log-failed` opens an interactive run-picker by default. That
picker does NOT work when output is piped/redirected:

```bash
# FAILS outside a TTY:
gh run view --log-failed -R owner/repo > /tmp/fail.log
# Error: run or job ID required when not running interactively
```

**Fix:** pass the run ID explicitly. It's the number in the run's URL
(`.../actions/runs/<run-id>/job/...`), also shown by `gh pr checks`:

```bash
gh run view <run-id> --log-failed -R owner/repo > /tmp/fail.log
tail -60 /tmp/fail.log
```

Note that `gh pr checks <branch> --watch` re-displays the **same run** (same
run ID, same elapsed times) until a new commit is actually pushed — re-running
`gh pr checks` after only staging/committing locally (without `git push`) will
show stale, unchanged results. Confirm the run ID has changed before treating
the output as a fresh result.

---

## insert_all Bypasses Model Validations and Callbacks — Use unique_by: for Duplicate Handling (learned Session 67)

**RULE: `Model.insert_all(rows, unique_by: :column)` performs a raw bulk SQL
INSERT. It runs NO model validations and NO callbacks. Duplicate handling
must be done via `unique_by:` (an `ON CONFLICT ... DO NOTHING` clause), not
by checking `exists?` per row beforehand.**

This is the correct tool for a **disposable mirror table** — one whose
source of truth lives outside the Rails app (an external database, a bulk
CSV feed) and gets fully replaced on each sync, rather than reconciled
record-by-record against prior state.

```ruby
ActiveRecord::Base.transaction do
  ComponentSuggestion.delete_all
  rows.each_slice(1000) do |batch|
    ComponentSuggestion.insert_all(batch, unique_by: :order_number)
  end
end
```

**Tradeoffs to know before choosing this pattern:**
- Model validations (length limits, format checks) do NOT run — anything
  the source data contains is stored as-is. Acceptable when the upstream
  source is already trusted (e.g. an internal export from another system
  of record), NOT acceptable for user-submitted data.
- `unique_by:` requires an actual DB unique index on the named column(s) —
  it generates `ON CONFLICT (column) DO NOTHING`, which needs that
  constraint to target.
- Within a single `insert_all` call (or across slices sharing an index),
  the FIRST occurrence of a duplicate key wins; later ones are silently
  dropped — there's no equivalent of "last write wins" here.
- `created_at`/`updated_at` are not auto-populated by AR callbacks the way
  `create!` would — supply them explicitly in each row hash if the schema
  requires them.

**Why this rule exists (Session 67, July 2026):**
`ComponentSuggestionImportService` v1.0 checked every incoming CSV row
against the database via `ComponentSuggestion.exists?(order_number:)` — an
O(n) round-trip per row against a table that only grows, which caused
production timeouts at ~55,000 rows. Rewritten (v2.0) around
`delete_all` + `insert_all(unique_by: :order_number)`, eliminating the
per-row database round-trip entirely. This was the single highest-value fix
of the Phase 4 rewrite (see DECOR_PROJECT.md "Component Suggestions Feature
— Phase 4" for the full context).

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

## Named Routes (as:) Inside namespace — Still Prefixed (MANDATORY, learned Session 65)

**RULE: A custom named route declared with `as: :some_name` inside
`namespace :admin do ... end` is STILL prefixed with `admin_` by Rails —
exactly the same as `resources` routes in that namespace.**

This is easy to forget because the `as:` value you write looks like the
literal helper name. It isn't, once it's inside a namespace block.

**Wrong — link_to call omits the namespace prefix:**
```erb
<%= link_to "Re-validate Order Numbers", revalidate_component_order_numbers_path %>
```
Raises `NameError: undefined local variable or method
'revalidate_component_order_numbers_path'` at render time.

**Correct — the actual generated helper carries the admin_ prefix:**
```ruby
# config/routes.rb
namespace :admin do
  post "component_order_numbers/revalidate", to: "component_order_numbers#revalidate",
                                              as: :revalidate_component_order_numbers
end
# generates: admin_revalidate_component_order_numbers_path
```
```erb
<%= link_to "Re-validate Order Numbers", admin_revalidate_component_order_numbers_path %>
```

**How to avoid guessing the helper name:** run `bin/rails routes | grep <as-value>`
and read the `Prefix` column directly, rather than assuming it matches the
`as:` value verbatim.

```bash
bin/rails routes | grep revalidate_component_order_numbers
# revalidate_component_order_numbers  admin_revalidate_component_order_numbers POST  /admin/component_order_numbers/revalidate(.:format)  admin/component_order_numbers#revalidate
```
Note the `Prefix` column already shows the un-namespaced name
(`revalidate_component_order_numbers`) — the actual path helper is
`Prefix + "_path"` == `admin_revalidate_component_order_numbers_path` only
because Rails additionally prepends the namespace. When in doubt, generate
the routes table and read the full helper name Rails reports, not the `as:`
value alone.

**Why this rule exists (Session 65, June 2026):**
Two new admin routes were added for Component order_number bulk maintenance:
`revalidate_component_order_numbers` and `unvalidated_component_order_numbers`,
both declared inside `namespace :admin do ... end` in `routes.rb`. The two new
`link_to` calls added to `admin.html.erb` in the same change referenced
`revalidate_component_order_numbers_path` and
`unvalidated_component_order_numbers_path` — without the `admin_` prefix.
The page raised `NameError` on first render. The same file already contained
a correct, working example of this exact pattern two dropdowns away
(`as: :data_transfer` inside `namespace :admin` → `admin_data_transfer_path`,
used in the Imports/Exports dropdown) — the existing correct pattern was not
cross-checked before writing the new links.

---

## Collection Routes Nested in a Namespaced Resources Block — A SECOND, Different Prefix Shape (MANDATORY, learned Session 67)

**RULE: A `collection do ... end` route nested inside a `resources` block
that is already inside `namespace :admin` produces a DIFFERENT prefix shape
than the custom `as:` routes covered above. Do not assume the two work the
same way — verify each with `bin/rails routes | grep <name>`.**

The Session 65 rule above covers a custom `as: :foo` route declared directly
inside `namespace :admin do ... end` (not nested in a `resources` block):
Rails prepends `admin_` onto a name that already ends in the resource/action
name → `admin_foo_path`.

A **collection route nested inside `resources`** works differently. For:
```ruby
namespace :admin do
  resources :component_suggestions, only: %i[index new create edit update destroy] do
    collection do
      get :download_manual
    end
  end
end
```
`bin/rails routes | grep download_manual` reports:
```
download_manual_admin_component_suggestions  GET  /admin/component_suggestions/download_manual
```
The path helper is **`download_manual_admin_component_suggestions_path`** —
the action name (`download_manual`) is PREPENDED to the resource's own
already-`admin_`-prefixed route name (`admin_component_suggestions`), not
appended after a bare resource name the way the `as:` case above works.

**First guessed wrong in Session 67:** `admin_download_manual_component_suggestions_path`
was written into `admin.html.erb` based on the (incorrect) assumption that
this case matched the Session 65 `as:` shape. Because `bin/rails routes | grep
download_manual` was run before the change was shipped, the error was caught
immediately rather than at render time — but it's worth noting that guessing
between these two shapes is genuinely easy to get wrong, since both produce
similarly-structured names that only differ in prepend/append order.

**Rule in one sentence:** every new route helper — whether from a custom
`as:` route or a `resources` collection/member route, whether namespaced or
not — gets verified with `bin/rails routes | grep <name>` before it's used
in a view. There is no shortcut that reliably predicts the helper name from
the route declaration alone.

---

## Rails Enum — read_attribute Does Not Bypass Type-Casting; Use _before_type_cast for the Raw Value (MANDATORY, learned Session 67)

**RULE: To read the raw underlying DB value of an enum-backed column (not
the mapped label), use the auto-generated `<attribute>_before_type_cast`
method — NOT `read_attribute(:<attribute>)`.**

Rails' `enum` macro attaches a custom type to the attribute at the schema
level. `read_attribute` still goes through that attribute's type-casting —
it returns the SAME mapped value as the plain accessor (`model.manual`),
not the raw stored string.

**Wrong — still returns the mapped label, not the raw value:**
```ruby
enum :manual, { added: "a", modified: "m" }, prefix: true
# ...
suggestion.manual                    # => "added"
suggestion.read_attribute(:manual)   # => "added"  — NOT "a"! Still type-cast.
```

**Correct — bypasses the type-casting layer:**
```ruby
suggestion.manual_before_type_cast   # => "a"
```

**Why this rule exists (Session 67, July 2026):**
`ManualComponentSuggestionsExportService` needed to write the raw one-character
DB value ("a"/"m") into a CSV column, so the file stays meaningful if someone
inspects it alongside the raw schema. `read_attribute(:manual)` was used,
based on the (incorrect) general assumption that `read_attribute` always
bypasses model-level behavior and returns the raw column value. A test
comparing the exported value against the expected raw string ("a") caught the
mismatch immediately — the export was writing "added" instead. Switching to
`manual_before_type_cast` fixed it.

**When this matters:** any time code needs the literal stored value of an
enum column for a purpose OTHER than application logic — CSV/data exports,
debugging, raw SQL comparisons, or anywhere the mapped label would be
misleading or incompatible with an external format.

---

## Single Source of Truth Refactors — Audit ALL Consumers, Not Just the File Being Changed (MANDATORY, learned Session 73)

**RULE: When a value or a piece of logic is duplicated across more than one
file and gets consolidated into a single source of truth (a constant, a
class method, a helper), grep the ENTIRE codebase for every other place
that duplicated logic could also live — not just the one file the current
task happens to be touching. Fix all of them in the same change, or at
minimum flag the others explicitly as known-stale.**

This is the same underlying failure shape as three other rules already in
this document (the Session 65/67 route-helper naming traps, the Session 64
admin-nav-menu gap) — a concept that exists in more than one place, where
only the copy directly in front of Claude gets updated when the concept
changes. The danger is specifically that the un-updated copy can look
completely fine for a long time: it only breaks once a NEW case comes along
that the original coincidence doesn't cover.

**Real example (Session 73, July 2026):**
Session 20 introduced `SiteText::KNOWN_TEXTS` and `SiteText.title_for_key`
as the single source of truth for text-page titles — but that refactor only
updated `Admin::SiteTextsController`. The owner-facing
`SiteTextsController` kept its own separate, private `title_for_key` hash
with only `"readme"` hardcoded, falling back to `key.titleize` for
everything else. For 53 sessions this looked completely fine: `.titleize`
of "news", "barter_trade", and "privacy" all happened to produce the exact
same string as their `KNOWN_TEXTS`-configured titles. The drift was only
caught in Session 73 because implementing 5 new Category Help Pages
happened to pick titles ("Computers Help") that do NOT match what
`.titleize` would produce from their keys ("Help Computers") — at which
point the stale duplicate would have silently shipped a wrong page heading
had the actual controller file not been read directly (Never-Guess) before
writing new code near it.

**How to apply this rule:**
Before extending or touching any file that consumes a "single source of
truth" constant/method, grep for the OLD pattern that source of truth was
meant to replace — do not assume a past refactor's changelog entry
("consolidated into KNOWN_TEXTS") means every consumer was actually
updated. A changelog note describes intent; it doesn't verify completeness.
```bash
# Before adding a new KNOWN_TEXTS-style entry anywhere, check for other
# hardcoded copies of the same concept:
grep -rn "title_for_key\|KNOWN_TEXTS" decor/app/
```

---

## Geared Pagination — paginate() Renders the Response Itself (MANDATORY, learned Session 67)

**RULE: `paginate(scope)` is not a plain data-fetch call. It sets `@page`
(NOT an instance variable named after the model) AND it renders the
response itself. Every ivar the view needs (`@page_title`,
`@turbo_tbody_id`, `@load_more_id`, `@index_path`) MUST be assigned BEFORE
calling `paginate` — it must be the last line of the action.**

The actual `Pagination` concern (`decor/app/controllers/concerns/pagination.rb`)
is thin but easy to misread:
```ruby
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
Two things this reveals that are easy to get wrong without reading the file:
1. `set_page_and_extract_portion_from` (from the `geared_pagination` gem)
   assigns `@page` — always `@page`, regardless of which model is being
   paginated. The view reads `@page.records`, not `@component_suggestions`
   or any other model-named ivar.
2. The `respond_to` block IS the render. `paginate(scope)` doesn't just
   return paginated data for the controller to do something with — calling
   it triggers the actual HTML or turbo_stream render, choosing the format
   based on `@page.number` (page 1 always forces `:html`, so a plain page
   load never renders the turbo_stream template even if the request headers
   suggest otherwise).

**Correct controller pattern:**
```ruby
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

This also fully explains the pre-existing "paginate — NEVER assign the
return value" rule from PROGRAMMING_GENERAL.md / SESSION_HANDOVER.md
(`@page = paginate(scope)` overwrites `@page` with whatever `paginate`
returns from the `respond_to` call, not the Page object `set_page_and_
extract_portion_from` just built).

**Why this rule exists (Session 67, July 2026):**
Before reading the concern file, the Session 67 draft of
`Admin::ComponentSuggestionsController#index` assumed `paginate` set an ivar
named after the model (`@component_suggestions`) and could be called as an
ordinary data-loading step with the render happening afterward as usual.
Reading `decor/app/controllers/concerns/pagination.rb` directly (rather than
inferring from one example view) corrected both assumptions before any
broken code shipped.

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

## System Tests — Capybara Assertion Patterns (MANDATORY, learned Session 60)

### assert_selector with a message string raises ArgumentError

Capybara's `assert_selector` does NOT accept a plain string as its second
positional argument. Passing one raises:
```
ArgumentError: Unused parameters passed to Capybara::Queries::SelectorQuery
```
The same applies to `refute_selector` and `assert_text`.

**Wrong:**
```ruby
assert_selector "input[name='user_name']", "Login form must have this field"
refute_selector "select[name='barter_status']", "Must not be rendered"
assert_text "+ Add port", "Button must be visible"
```

**Correct — route the message through Minitest's assert:**
```ruby
assert page.has_css?("input[name='user_name']"),     "Login form must have this field"
assert page.has_no_css?("select[name='barter_status']"), "Must not be rendered"
assert page.has_text?("+ Add port"),                 "Button must be visible"
```

`has_css?` / `has_no_css?` / `has_text?` still use Capybara's smart waiting
(retry until condition met or timeout). The message is handled by Minitest.

---

## System Tests — Capybara select() Matches by TEXT, Not value= (MANDATORY, learned Session 60)

`Capybara.select(string, from: field)` searches for an `<option>` whose
**visible text** equals the string. It does NOT search by the HTML `value=`
attribute. Passing a fixture integer ID (e.g. `"994812667"`) always raises
`Capybara::ElementNotFound`.

**Wrong:**
```ruby
first_option_value = select_el.all("option").reject { |o| o.value.empty? }.first&.value
select first_option_value, from: "software_name_id"  # looks for TEXT "994812667"
```

**Correct — keep a reference to the option element, use select_option:**
```ruby
first_option = select_el.all("option").reject { |o| o.value.empty? }.first
skip "No options in fixture data" unless first_option
first_option.select_option   # selects the element directly, no text/value lookup
```

To assert the selection persists after form submission, compare option text:
```ruby
assert page.has_select?("software_name_id", selected: first_option.text, wait: 5)
```

---

## System Tests — Filter Forms in Turbo Frames Don't Update URL (learned Session 60)

The software_items, components, and computers filter forms are rendered inside
Turbo Frames. After form submission, the frame content updates but the browser's
top-level URL stays at the bare path. `assert_includes current_url, "param="` will
always fail.

**Wrong:**
```ruby
within("form[method='get']") { find("[type=submit]").click }
assert_includes current_url, "query=vms"
```

**Correct — click the named Apply button; assert form field state instead of URL:**
```ruby
fill_in "query", with: "vms"
click_button "Apply"
assert page.has_field?("query", with: "vms", wait: 5),
  "Query field must reflect submitted value after filter applies"
```

For select filters, `has_select?` with the option's visible text:
```ruby
first_option.select_option
click_button "Apply"
assert page.has_select?("sort", selected: first_option.text, wait: 5)
```

Both `has_field?` and `has_select?` use Capybara's smart waiting and work
correctly for both full-page navigation and Turbo Frame navigation.

---

## System Tests — <template> Elements Require evaluate_script (learned Session 60)

HTML `<template>` elements are not part of the live rendering tree. Their content
lives in a DocumentFragment, not as rendered DOM children. Capybara's
`assert_selector` and `has_css?` cannot find them even with `visible: :all`.

**Wrong:**
```ruby
assert_selector "[data-connection-members-target='template']", visible: :all
```

**Correct — use evaluate_script with document.querySelector:**
```ruby
template_present = evaluate_script(
  "document.querySelector(\"[data-connection-members-target='template']\") !== null"
)
assert template_present, "Form must render the template Stimulus target"
```

`document.querySelector` operates on the full element tree and CAN locate
`<template>` nodes as DOM elements (even though their content is in a fragment).

---

## System Tests — Turbo Navigation Race in sign_in / sign_out (learned Session 60)

`form_with` without `local: true` submits via Turbo (an async `fetch()` call).
`find("[type=submit]").click` returns immediately after the click fires, before
Turbo's redirect/navigation completes. Reading `current_path` right after the
click races the navigation and sees the old path.

**Fix in sign_in:** wait for the login form to disappear before returning:
```ruby
find("[type=submit]").click
has_no_field?("user_name", wait: 5)  # retries until login page is gone
```

**Fix in sign_out:** use `click_on "Sign out"` (matches both `<a>` and `<button>`)
and wait for the sign-out element to disappear:
```ruby
click_on "Sign out"
has_no_text?("Sign out", wait: 5)
```

**Prerequisite:** the nav partial must render a "Sign out" link/button when
`logged_in?` is true. See `_navigation.html.erb` v2.3.

---

**End of RAILS_SPECIFICS.md**
