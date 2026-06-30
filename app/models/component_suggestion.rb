# decor/app/models/component_suggestion.rb
# version 1.0
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
  # ── Validations ────────────────────────────────────────────────────────────

  validates :order_number,
            presence:   true,
            uniqueness: { case_sensitive: false },
            length:     { maximum: 20 }

  validates :description, length: { maximum: 100 }, allow_blank: true
  validates :category,    length: { maximum: 40  }, allow_blank: true

  # ── Scopes ──────────────────────────────────────────────────────────────────

  # Returns suggestions whose order_number starts with the given query string.
  # Used by the Phase 2 JSON endpoint. Case-insensitive via LIKE (SQLite LIKE
  # is case-insensitive for ASCII characters by default).
  # Results are ordered alphabetically so the dropdown is predictable.
  scope :matching, ->(q) { where("order_number LIKE ?", "#{sanitize_sql_like(q)}%").order(:order_number) }
end
