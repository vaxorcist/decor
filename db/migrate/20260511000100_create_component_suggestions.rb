# decor/db/migrate/20260511000100_create_component_suggestions.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Creates the component_suggestions lookup table.
# This is an admin-managed reference table — analogous to software_names.
#
# Fields:
#   order_number  VARCHAR(20)   NOT NULL, UNIQUE index
#     The part number / order number string (e.g. "DELQA", "M7516", "54-17647").
#     UNIQUE enforced at both DB level (index) and Rails validation.
#     SQLite note: VARCHAR length is cosmetic only; no CHECK constraint added here
#     because uniqueness is the critical constraint, and length is validated at
#     the Rails model level (presence: true, length max 20).
#
#   description   VARCHAR(100)  nullable
#     Human-readable name for the component (e.g. "DELQA Ethernet Controller").
#
#   category      VARCHAR(40)   nullable
#     Informational grouping label (e.g. "Option", "Module", "Assembly", "Part").
#     NOT stored on the component when a suggestion is accepted — display only.

class CreateComponentSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :component_suggestions do |t|
      # order_number is the natural unique key — used for duplicate detection on import
      t.string :order_number, limit: 20, null: false
      t.string :description,  limit: 100
      t.string :category,     limit: 40

      t.timestamps precision: nil
    end

    # Unique index enforces the one-order-number-per-row constraint at the DB level.
    # The import service uses this key to detect duplicates (idempotent re-import).
    add_index :component_suggestions, :order_number, unique: true
  end
end
