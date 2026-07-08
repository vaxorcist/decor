# decor/app/models/component_suggestion.rb
# version 1.1
# Session 67: Phase 4 — added the "manual" enum tracking admin-form origin.
#   String-valued hash-enum, matching the established project convention
#   (see Computer#device_type / Computer#barter_status in computer.rb v2.1 —
#   confirmed pattern: enum :name, { key: "raw_value", ... }, prefix: true).
#   Unlike Computer's enums, this column is nullable and has no CHECK
#   constraint restricting it to a fixed set at the DB level: null is a valid,
#   expected third state (untouched bulk-import row) that the enum leaves
#   alone — Rails enum accessors simply return nil when the underlying column
#   is nil, no special handling required.
#
#   The two non-null values are set programmatically by
#   Admin::ComponentSuggestionsController, never accepted as a raw form field:
#     create  -> "added"    (manual: "a") — permanent, confirmed Session 66
#     update  -> "modified" (manual: "m") — only when the row was previously
#                untouched (manual: nil); a row already "added" or "modified"
#                keeps its existing value on further edits.
#   See Admin::ComponentSuggestionsController v1.1 for exactly where this is set.
# Session 63: Phase 1 of Component Suggestions feature.
#
# Admin-managed lookup table for component order number typeahead autocomplete.
# Analogous to SoftwareName — reference data, not owner-scoped data.
#
# Design notes:
#   - order_number is the natural unique key (VARCHAR 20, NOT NULL, UNIQUE index).
#   - description and category are optional display fields.
#   - category is informational only — it is NOT stored on the Component record
#     when a suggestion is accepted via the typeahead.
#   - The :matching scope powers the Phase 2 JSON endpoint:
#       GET /component_suggestions?query=DEL
#       → ComponentSuggestion.matching("DEL").limit(10)
#     LIKE "DEL%" matches order numbers that START with the query string,
#     which is appropriate for part-number prefixes (e.g. "DE" → DELQA).

class ComponentSuggestion < ApplicationRecord
  # ── Enums ────────────────────────────────────────────────────────────────

  # Tracks whether this row was touched by hand via the admin form, as opposed
  # to being an untouched row from the bulk DEC-database import. See the file
  # header above and SESSION_HANDOVER.md "Session 66 Summary" item 1a for the
  # full rationale (this is the required backup/safety mechanism ahead of the
  # unconditional delete-all-and-reimport strategy in
  # ComponentSuggestionImportService v2.0).
  #
  # prefix: true gives manual_added? / manual_modified? — consistent with the
  # device_type_computer? / barter_status_offered? style already used on
  # Computer (see computer.rb v2.1).
  enum :manual, { added: "a", modified: "m" }, prefix: true

  # ── Validations ────────────────────────────────────────────────────────────

  validates :order_number,
            presence:   true,
            uniqueness: { case_sensitive: false },
            length:     { maximum: 20 }

  # Widened Session 67 (Phase 4) from 100 to 510 — concatenated main + variant
  # descriptions from the DEC-database export no longer fit the original size.
  validates :description, length: { maximum: 510 }, allow_blank: true
  validates :category,    length: { maximum: 40  }, allow_blank: true

  # ── Scopes ──────────────────────────────────────────────────────────────────

  # Returns suggestions whose order_number starts with the given query string.
  # Used by the Phase 2 JSON endpoint. Case-insensitive via LIKE (SQLite LIKE
  # is case-insensitive for ASCII characters by default).
  # Results are ordered alphabetically so the dropdown is predictable.
  scope :matching, ->(q) { where("order_number LIKE ?", "#{sanitize_sql_like(q)}%").order(:order_number) }

  # Returns suggestions whose order_number contains the given query string
  # anywhere (not just as a prefix). Used by the Session 67 admin index filter
  # — confirmed as substring match, not prefix match, since the admin search
  # use case ("find this order number among 55,000 rows") is different from
  # the typeahead's prefix-completion use case. A leading wildcard means
  # SQLite cannot use the order_number unique index for this query and falls
  # back to a full table scan — confirmed acceptable at this data scale
  # (~55,000 rows is not enough for the scan cost to be noticeable).
  scope :order_number_contains, ->(q) { where("order_number LIKE ?", "%#{sanitize_sql_like(q)}%") }
end
