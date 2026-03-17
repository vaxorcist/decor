# decor/db/migrate/20260316110000_add_unique_index_to_components_serial_number.rb
# version 1.0
# Session 28: Add a unique database index on (owner_id, component_type_id, serial_number)
# to enforce that no single owner can register two components of the same type with
# the same serial number.
#
# Design notes:
#   - owner_id is the first column: matches the query pattern used in
#     OwnerImportService (`@owner.components.exists?(serial_number:)`), which
#     always filters by owner first. Putting owner_id first lets SQLite use this
#     index efficiently for that query.
#   - serial_number is nullable (VARCHAR(20) or NULL). SQLite treats every NULL
#     as distinct from every other NULL in a unique index, so multiple components
#     of the same type and owner without a serial number are still permitted.
#     Only rows where serial_number IS NOT NULL are subject to uniqueness enforcement.
#   - The constraint is scoped per owner: two different owners may register a
#     component of the same type with the same serial number. This is intentional
#     — owners often use their own replacement numbering schemes, so collisions
#     between owners' serial numbers are expected and valid.
#   - This migration is a straightforward add_index — no table recreation needed.
#     SQLite supports adding indexes to existing tables without restrictions.
#   - The migration is reversible via the standard `change` method.

class AddUniqueIndexToComponentsSerialNumber < ActiveRecord::Migration[8.1]
  def change
    # Composite unique index: one owner cannot have two components of the same
    # type with the same serial number. Different owners may share the same
    # type+serial combination.
    add_index :components,
              [:owner_id, :component_type_id, :serial_number],
              unique: true,
              name: "index_components_on_owner_type_and_serial_number"
  end
end
