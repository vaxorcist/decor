# decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md
# version 1.0
# Session (July 3, 2026): Full design consultation for splitting order_number
#   main/variant in component_suggestions, three-state match status on
#   components, and related import/export/UI behavior. NOT YET IMPLEMENTED —
#   superseded, for now, by a simpler concatenated-field approach being
#   tested against a newly expanded ~85,000-record dataset (see "Status"
#   section at the end). Saved for reference in case this design is revisited.

**Status: DESIGN ONLY — NOT IMPLEMENTED**

This document captures a fully-specified design that was agreed upon in
consultation, but was NOT started in code. Before implementation was begun,
the user paused to reconsider complexity vs. usefulness, and is now testing
a simpler alternative (see "Status" at the end). This document exists so the
fuller design isn't lost if it becomes relevant again later.

---

## 1. Problem Context

DEC "order numbers" consist of a **main part** and an optional **variant**
suffix separated by a dash, e.g. `DELQA-SA`. The variant serves multiple,
inconsistent purposes depending on the component:

- Distinguishes installation variants / configurations with same function
- Specifies geometric dimensions (e.g. cable length)
- Distinguishes original vs. updated/improved revisions
- Indicates manufacturer (e.g. for RAM ICs)
- Describes accessories for a base model
- Base model conventionally uses variant `-00`
- Other/combined purposes; not all cases are known or classifiable

Some variants are essential to avoid misidentification; others are cosmetic.
Classifying *which* is which across the full dataset was judged not worth
the effort — any design should treat the variant as an opaque token, never
requiring semantic classification.

**Scale at time of design:** ~13,000 `components` records (owned items),
~46,000 `component_suggestions` order_number+variant combinations (reference
lookup table).

---

## 2. Options Considered

| Option | Schema change | Description handling | Notes |
|---|---|---|---|
| A | None | Single field, manual free text | Cheapest; relies on `LIKE` prefix search for grouping |
| B | Split `order_number_main`/`order_number_variant` on BOTH tables | Single description field | Full normalization; touches components identity key |
| C | Split only `component_suggestions` | Add `variant_description` (or later, kept as two full columns) | Targets the actual pain point (description duplication) without touching `components` |
| D | Split BOTH tables into main/variant columns | Two description columns | Most structurally complete; largest blast radius |

**Decision:** A hybrid of C and D — `component_suggestions` gets a full
structural split (like D), but `components.order_number` stays a single
consolidated string (like C/A). This was chosen because the described
import file formats (see below) required `component_suggestions` to have a
real `order_number_variant` column, while `components` had no comparable
need for it.

---

## 3. Agreed Schema (component_suggestions)

```
order_number          VARCHAR(20) NOT NULL   -- main part only, no dash
order_number_variant  VARCHAR(4)  NOT NULL, default "-00"  -- dash INCLUDED in stored value, e.g. "-00", "-SA"
description           VARCHAR(100) nullable  -- main-number description
variant_description   VARCHAR(100) nullable  -- variant-specific description
category              VARCHAR(40)  nullable  -- independent per row (not inherited from base)

UNIQUE INDEX (order_number, order_number_variant)
```

Both `description` and `variant_description` are kept as **separate columns
in all cases** (explicit user decision) because their meaning can differ
substantially — not derived from each other, not collapsed into one column
per row.

### Hard constraint: every order_number must have a "-00" row

- No variant row may exist without a corresponding `-00` base row for the
  same `order_number`.
- This constraint eliminates the SQL NULL-uniqueness gap that a nullable
  variant column would have caused (NULL never equals NULL in a unique
  index) — by making `order_number_variant` NOT NULL with a mandatory
  `"-00"` default, the standard unique index works correctly with no
  special-casing.
- **Deletion guard:** an admin cannot delete a `-00` row while sibling
  variant rows for the same `order_number` still exist (implement as a
  `before_destroy` model guard).

### Splitting rule for parsing a consolidated string into (main, variant)

**Always split on the LAST dash** — main parts can themselves contain a
dash (typically in the third position), so splitting on the first dash
would be wrong.

---

## 4. components table

`order_number` stays a **single consolidated string** field (unchanged
shape, e.g. `"DELQA-SA"` or bare `"DELQA"`).

`order_number_verified` (boolean) becomes a **three-state enum**,
`order_number_match_status`:

```
exact_variant_match  — parsed (main, variant) exactly matches a
                       component_suggestions row
base_match_only      — main part matches an existing "-00" row, but the
                       variant text given doesn't match any known variant
                       row for that main number
unmatched            — main part matches no "-00" row at all
```

### Derived matching logic (confirmed)

```
Component.order_number split on LAST dash → (main, typed_variant_or_nil)

No dash typed (bare entry, e.g. "DELQA"):
  → look for suggestions row (main, "-00")
  → found     → EXACT_VARIANT_MATCH   (bare = implicit "-00", always fully matched)
  → not found → UNMATCHED
  → (base_match_only is NEVER produced from a bare/undashed entry — this
     was an explicit UX requirement: less-experienced users who don't know
     about variants should never see an "unconfirmed" status just because
     they typed a plain order number)

Dash + variant typed (e.g. "DELQA-Z"):
  → look for suggestions row (main, "-" + typed_variant) exactly
  → found                              → EXACT_VARIANT_MATCH
  → not found, but (main, "-00") exists → BASE_MATCH_ONLY
  → (main, "-00") also doesn't exist    → UNMATCHED
```

### Description fill behavior on the component form

- **exact_variant_match** (single row lookup): both `Component Description`
  and `Variant Description` are filled directly from that one matched
  row's `description` / `variant_description` columns.
- **base_match_only**: `Component Description` is filled from the `-00`
  row's `description`; `Variant Description` is left blank (no variant row
  matched).
- Both description fields are **independently user-editable after
  auto-fill**, and editing them does **not** downgrade the match status
  (consistent with existing Session 63/64 behavior for the single
  description field).

### Form UI addition

A small badge/icon near the order-number field shows the current
match-status state (exact match / base only / unmatched).

---

## 5. Admin CSV Import — Two-File Format

```
File (a): "order_number","description","category"
  → auto-assigns variant "-00" to every row
  → always succeeds structurally (no dependency on other rows)

File (b): "order_number","order_number_variant","description","category"
  → requires an existing "-00" base row for that order_number
  → if both files are uploaded together: file (a) is processed FULLY
    first, then file (b) is validated against the now-current table state
    (so a variant row CAN reference a base row from the same upload)
  → a file (b) row referencing an order_number with NO matching "-00" row
    (neither pre-existing nor from file (a) in the same upload) is a
    HARD IMPORT ERROR — no auto-create leniency on import
```

`category` is independent per row — not inherited or validated against the
base row's category.

### Admin manual form — different leniency than import

If an admin manually creates a single new `ComponentSuggestion` via the web
form, for a brand-new `order_number` with a variant other than `-00`, the
form **auto-creates a `-00` row** (blank description/category) **with an
informational flash message** — this is intentionally more lenient than
the bulk-import hard-error behavior, because a single interactive action
is low-blast-radius and easily reviewed, whereas bulk auto-healing could
mask a real data problem across many rows silently.

---

## 6. Bulk Maintenance Service Impact (Session 65 services)

Both of these Session-65-era services would need a substantive rewrite
under this design (not just an edit):

- **ComponentOrderNumberRevalidationService** — must parse each
  component's consolidated `order_number` (split on last dash), then
  perform the three-state lookup logic above per component, instead of
  its current binary true/false sync.
- **UnvalidatedOrderNumbersExportService** — "unvalidated" scope changes
  from `order_number_verified: false` to **both** `unmatched` AND
  `base_match_only` states (confirmed — the export should surface
  anything short of a fully confirmed exact variant match).

**Sequencing note:** this rewrite should only be built AFTER Session 65's
own code has been committed and deployed (avoids stacking untested changes
on untested changes). At the time of this consultation, Session 65 was
confirmed already committed, deployed, and tested on the server.

---

## 7. Proposed Implementation Phasing (if resumed)

```
Phase 0  Session 65 commit/deploy                          DONE (confirmed)
Phase 1  Migrations + ComponentSuggestion model + admin
         CRUD (variant field, auto-"-00" creation, guard)
         + fixtures + model/controller tests
Phase 2  Import/export services (two-file format) + tests
Phase 3  Owner-facing component form + Stimulus typeahead
         + JSON endpoint + match-status badge + tests
Phase 4  ComponentOrderNumberRevalidationService +
         UnvalidatedOrderNumbersExportService rewrite + tests
```

Each phase was designed to be an independent, testable commit boundary,
similar to how the original Component Suggestions feature was split across
Sessions 63/64/65.

---

## 8. Status as of end of this consultation (July 3, 2026)

**Not implemented.** Before any files were requested for Phase 1, the user
paused to reconsider: concern that this design risks "self-indulgent
featuritis" — added complexity on both the implementation/maintenance side
and the user-facing side, without firm confidence it's actually needed.

**Alternative now being tested (outside Rails, at the DEC-database export
stage):**
- On export, main order number + variant are concatenated into a single
  "part number" string (no schema split at all — closest to Option A).
- Both descriptions (main + variant) are concatenated into a single
  `description` field using `" | "` as a delimiter.
- The data scope has been expanded to ~85,000 records (up from the
  ~46,000 figure this design was originally scoped against).
- Testing is in progress; new challenges are anticipated and will be
  reported back before any implementation decision is finalized.

**If this simpler approach is adopted instead:** it most closely resembles
Option A from Section 2 — no schema change to either table, `order_number`
absorbs the variant as part of one string, `description` absorbs both
descriptions as one string with a delimiter. Watch for: delimiter
collision if `" | "` can appear inside legitimate description text, and
a consistent convention for records that have no real variant information
in the source DEC database (do they still get a trailing marker, or does
the field simply omit any variant segment?).

---

**End of ORDER_NUMBER_VARIANT_DESIGN.md**
