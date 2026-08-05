# decor/docs/claude/RAILS_UI.md
# version 1.0 NEW
# Session 84 (Reorg Session 3 of 4): Extracted from RAILS_SPECIFICS.md v3.15
# as part of the agreed 4-session documentation reorg (see
# SESSION_HANDOVER.md "Documentation Reorganization — Status"). Contains
# every Tailwind/CSS/nav/Stimulus/ERB-view rule previously mixed into the
# single monolithic RAILS_SPECIFICS.md file. Each rule's lengthy "why this
# rule exists" incident narrative has been trimmed to one line — the rule
# statement and code examples (load-bearing for Pre-Implementation
# Verification) are unchanged. Full original narrative for every rule below
# remains recoverable via git history of RAILS_SPECIFICS.md prior to this
# split.
# Load this file for any view/CSS/Stimulus/nav work — it is NOT part of
# the mandatory session-start `cat` list (see RAILS_SPECIFICS.md's topic
# index).

**Rails-Specific Patterns — Views, CSS, and Stimulus**

**Last Updated:** July 30, 2026 (Session 84 — split out of RAILS_SPECIFICS.md)

---

## Nav Logo Centering — A 1fr Grid/Flex Middle Column Centers on Leftover Space, Not the Viewport (MANDATORY)

**RULE: If a nav bar has no `max-width` wrapper (spans full viewport
edge-to-edge) and centers a logo using a middle `1fr` grid column or a
`flex-1 flex justify-center` div flanked by two other groups, the centered
element is centered on the LEFTOVER space between those groups — not the
viewport — unless the two flanking groups are exactly equal width.**

```erb
<%# Wrong — logo only centers within the 1fr leftover space %>
<nav class="grid grid-cols-[auto_1fr_auto] items-center gap-2 px-6 py-4">
  <div class="flex items-center gap-6">  <%# left: 7 links — wide %> </div>
  <div class="flex-1 flex justify-center">
    <%= image_tag "logo.png" %>
  </div>
  <div class="flex items-center gap-6">  <%# right: 2-3 items — narrow %> </div>
</nav>

<%# Correct — take the element out of the flow, position it against the full nav %>
<nav class="relative flex items-center justify-between gap-2 px-6 py-4">
  <div class="flex items-center gap-6">  <%# left group, natural width %> </div>
  <div class="absolute left-1/2 -translate-x-1/2">
    <%= image_tag "logo.png" %>
  </div>
  <div class="flex items-center gap-6">  <%# right group, natural width %> </div>
</nav>
```

**Diagnostic symptom:** a page's own content is reported as "not centered,"
but the page template already uses correct `mx-auto` centering — check the
nav's logo/brand element next.

**Why:** reported as "the New connection group page content is not
centered"; the actual bug was `common/_navigation.html.erb`'s
`grid-cols-[auto_1fr_auto]` middle column sitting off-center because the
left nav group (7 items) is wider than the right (2-3 items) (Session 78).

---

## Sticky Page Headers vs. Nav Dropdowns — Equal z-index Ties Are Broken By DOM Order (MANDATORY)

**RULE: Never give a page-level sticky element (headers, `<thead>`s, sticky
filter sidebars) the same z-index as the top nav's positioned wrapper.**
When z-index values tie, CSS breaks the tie by DOM order — the LATER
element wins, regardless of which one should visually sit on top. A
dropdown's own z-index (e.g. `z-50`) is only compared locally, within its
nearest positioned ancestor — what matters for winning against outside
content is the ANCESTOR's z-index, not the dropdown's own.

```erb
<%# Wrong — nav wrapper and page's sticky <h1> both z-10; <h1> (later in %>
<%# the DOM) wins the tie and paints over any open dropdown that overlaps it %>
<div class="relative z-10"> ... dropdown menus, each internally z-50 ... </div>
<h1 class="sticky top-0 z-10 bg-white ...">Owners</h1>

<%# Correct — raise the nav wrapper clearly above any page-level z-10 element %>
<div class="relative z-20"> ... </div>
```

**Diagnostic symptom:** if only the FIRST item of an open dropdown looks
obscured while everything below it renders fine, suspect this exact tie —
a short sticky header only overlaps the very top of a taller dropdown.

**Why:** the Info dropdown's first item was obscured on every page with a
sticky `<h1>` (Owners/Computers/Peripherals/Components/Software); fixed by
raising the nav wrapper from `z-10` to `z-20` (Session 77).

---

## CSS grid grid-cols-N — Equal Columns Cause Overflow Hidden Behind Later Items (MANDATORY)

**RULE: Never use `grid-cols-N` (equal `1fr` columns) for a left/logo/right
navbar layout. Use `grid-cols-[auto_1fr_auto]` instead.** Equal `1fr`
columns let a wide left-column flex content overflow its cell; CSS grid
doesn't clip overflow, but later grid items (centre/right) stack on top of
it in source order, making the overflowed links visible but unclickable.

**Symptoms:** a nav link is visible but can't be clicked; a link is only
clickable at its very bottom edge; the bug worsens for users with more
right-column items (e.g. admins).

```erb
<%# Wrong %>
<nav class="grid grid-cols-3 items-center gap-2 px-6 py-4"> ... </nav>

<%# Correct %>
<nav class="grid grid-cols-[auto_1fr_auto] items-center gap-2 px-6 py-4">
  <div class="flex gap-6 relative z-10"> <%# left: sizes to content, safety-net z-index %> </div>
  <div class="flex justify-center">      <%# centre: takes remaining space %> </div>
  <div class="flex justify-end">         <%# right: sizes to content %> </div>
</nav>
```

**Why:** adding a 6th left-nav item pushed it past the `1fr` boundary;
admins (wider right column) saw it completely unclickable (Session 53).

---

## Tailwind CSS — Rebuild Required After Class Changes (MANDATORY)

**RULE: Any time a file with a new or changed Tailwind utility class
(especially an arbitrary-value class like `min-h-[2.5rem]` never used
elsewhere) is delivered, proactively remind the user to rebuild Tailwind's
CSS bundle, with the exact command — every time, not only if they report
the fix "didn't work."**

```bash
bin/rails tailwindcss:build
```
(or restart the watcher, if one is running), then hard-refresh the browser
(Ctrl+Shift+R / Cmd+Shift+R).

**Why:** Tailwind only generates CSS for classes it finds when it scans
files at build time — placing an updated `.erb` file changes markup
immediately but not the compiled bundle, with no error if skipped. A
`components/_form.html.erb` fix appeared not to work at all until the
bundle was rebuilt and the browser hard-refreshed (Session 75).

---

## Tom Select sortField — Must Be an Explicit Sort Spec, Never a Boolean (MANDATORY)

**RULE: `sortField` in `tom_select_controller.js` must always be an
explicit sort spec object (`{ field: "text", direction: "asc" }`) — never
`false`.** Tom Select doesn't treat `false` as "leave order alone"; it
falls back to enumerating options by internal object key. Since
`collection_select` builds `<option>` values from record `id`, and
ECMAScript enumerates integer-like object keys in ascending numeric order
first regardless of insertion order, this silently sorts by id, not name —
for both the closed dropdown and filtered search results.

```javascript
// Wrong — falls back to ascending-id order, not the Rails .order(:name)
new TomSelect(el, { sortField: false });

// Correct — honored for both closed list and filtered results
new TomSelect(el, { sortField: { field: "text", direction: "asc" } });
```

**Why:** the Computer Model dropdown wasn't sorted alphabetically before or
after filtering, despite a correct `.order(:name)` on the Rails side; the
bug was entirely in `sortField: false`, present since the controller's
creation and affecting every Tom Select dropdown project-wide (Session 76).

---

## ERB Comments — Never Embed a Literal `<%= %>` Delimiter Inside a `<%# %>` Comment (MANDATORY)

**RULE: An ERB comment (`<%# ... %>`) closes at the FIRST `%>` it
encounters, with no awareness of nested tags.** Never write a changelog
comment containing a literal `<%=`/`%>` pair describing a code change — the
comment terminates early and the remainder renders as visible page text.

```erb
<%# Wrong — closes early at "capitalize %>"; everything after leaks onto the page %>
<%#      Fixed to "<%= @computer.device_type.capitalize %> Model" %>

<%# Correct — plain prose, no embedded ERB delimiters %>
<%#      Fixed to use the device's capitalized device_type value in the %>
<%#      label, matching the pattern _form.html.erb v2.9 already uses. %>
```

**Check before delivering any `.erb` file with changelog comments:**
```bash
grep -n '<%#.*<%=' path/to/file.erb
```

**Why:** `computers/show.html.erb`'s own changelog comment embedded a
literal ERB output tag to illustrate a fix, closed early, and leaked
"Model", matching the exact %>" as visible text directly below the nav bar
in production (Session 75).

---

## UI Renames — Rails Auto-Generated Strings (MANDATORY)

**RULE: When renaming a concept in the UI, changing the `<h1>` heading is
not enough.** Rails auto-generates display strings from model/column names
in several places that do NOT update automatically:

1. **`f.submit`** derives its label from the model class name — pass an
   explicit string: `f.submit "Save Run Status", class: ...`
2. **`f.label :column`** derives its text from the column name — pass an
   explicit second argument: `f.label :condition, "Status", class: ...`
3. **`new.html.erb`/`edit.html.erb` `<h1>`** — manual text, update directly.
4. **`index.html.erb` column header** for the renamed field — manual text.
5. **`show.html.erb` field label**, if displayed there — manual text.
6. **`<title>` tags and breadcrumbs** referencing the model/field name.
7. **Flash notices** that interpolate surrounding words, not just the value:
   `notice: "#{@component_condition.condition} has been saved."` → reword
   the surrounding text too, e.g. `"Run status saved."`.

**Why:** `ComponentCondition#condition` was renamed to "Run Status" in the
UI; `<h1>`s were updated but `f.submit` still showed "Create Component
condition" and `f.label :condition` still showed "Condition" — both needed
separate fixes after deployment (Session 58).

---

## ERB + whitespace-pre-wrap — Literal Whitespace Gotcha

**`whitespace-pre-wrap` renders ALL whitespace literally**, including the
newline/indentation between a tag and its `<%= %>` content.

```erb
<%# Wrong — literal newline/indentation renders %>
<dd class="whitespace-pre-wrap">
  <%= record.description %>
</dd>

<%# Correct %>
<dd class="whitespace-pre-wrap"><%= record.description %></dd>
```

**Rule:** whenever `whitespace-pre-wrap` is used, the `<%= %>` tag MUST be
on the same line as the opening HTML tag.

---

## data-turbo="false" — NEVER Wrap Turbo-Method Links Inside a Turbo-Disabled Element (MANDATORY)

**RULE: Never place a `data-turbo-method` link inside any ancestor carrying
`data-turbo="false"` or `data: { turbo: false }`.** This disables Turbo for
the element AND all descendants — a `data-turbo-method="delete"` link
inside it is silently treated as a plain GET, producing a routing error
(the route only exists as DELETE).

```erb
<%# Wrong — Turbo disabled on the link by its ancestor %>
<%= form_with url: "#", data: { turbo: false } do |f| %>
  <a href="<%= admin_site_text_path(key) %>"
     data-turbo-method="delete" data-turbo-confirm="Are you sure?">Delete</a>
<% end %>

<%# Correct — link lives outside any Turbo-disabled wrapper %>
<a href="<%= admin_site_text_path(key) %>"
   data-turbo-method="delete" data-turbo-confirm="Are you sure?">Delete</a>
```

**Detection gap:** requires a system test (real browser) to catch —
controller integration tests call routes directly, bypassing the view/JS layer.

**Why:** `delete_confirm.html.erb` wrapped the Delete link in a `form_with`
with `data: { turbo: false }` (copy-pasted unnecessarily from a multipart
upload page); the link fired GET instead of DELETE (Session 53).

---

**End of RAILS_UI.md**
