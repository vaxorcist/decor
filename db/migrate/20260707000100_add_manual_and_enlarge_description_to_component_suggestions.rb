# decor/db/migrate/20260707000100_add_manual_and_enlarge_description_to_component_suggestions.rb
# version 1.0
# Session 67: Phase 4 of Component Suggestions feature (order number / variant
# simplification — see DECOR_PROJECT.md "Phase 4" and SESSION_HANDOVER.md
# "Session 66 Summary" for full background).
#
# Two independent changes to component_suggestions, bundled in one migration
# since both are part of the same Phase 4 rollout:
#
# 1. New nullable "manual" column — VARCHAR(1).
#    Tracks whether a row originated from the admin form rather than the bulk
#    DEC-database CSV import:
#      "a"  = added manually via the admin form (permanent — once set, an edit
#             to this row NEVER changes it back to "m" or null; confirmed design
#             decision, see SESSION_HANDOVER.md Session 66 Summary item 1a)
#      "m"  = modified manually — originated from bulk import, later hand-edited
#             via the admin form
#      null = untouched bulk-import record (the default / normal case; this is
#             why the column is nullable rather than defaulting to an empty string)
#    VARCHAR(1) is sized exactly to the two possible non-null values, per
#    PROGRAMMING_GENERAL.md "Database Column Types" (explicit length required).
#    SQLite does not enforce VARCHAR length at runtime (see RAILS_SPECIFICS.md
#    "SQLite — VARCHAR Length Enforcement") — a CHECK constraint is not added
#    here because the only writer of this column is application code going
#    through the Rails enum (see component_suggestion.rb v1.1), which already
#    restricts assignment to the two mapped values or nil.
#
# 2. Enlarge "description" from VARCHAR(100) to VARCHAR(510).
#    The adopted Phase 4 approach concatenates the main + variant descriptions
#    into one field at the DEC-database export stage (e.g. two ~250-char
#    descriptions joined with " | "), which no longer fits the original
#    single-description sizing. 510 was the figure confirmed in Session 66
#    (2 x ~250 + 3-char " | " delimiter, rounded up).
#
# Rails' SQLite3 adapter handles change_column by transparently recreating the
# table internally (SQLite has no native ALTER COLUMN) — no hand-written raw
# SQL table-recreation dance is needed for a single column-width change like
# this (that manual pattern in RAILS_SPECIFICS.md is for cases adding named
# CHECK constraints, which this migration does not need).

class AddManualAndEnlargeDescriptionToComponentSuggestions < ActiveRecord::Migration[8.1]
  def change
    # New nullable flag column. No default — null is the normal/expected state
    # for the ~55,000 bulk-imported rows; only admin-form-touched rows get a value.
    add_column :component_suggestions, :manual, :string, limit: 1

    # Widen description to accommodate concatenated main + variant descriptions.
    change_column :component_suggestions, :description, :string, limit: 510
  end
end
