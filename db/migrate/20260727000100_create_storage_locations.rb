# decor/db/migrate/20260727000100_create_storage_locations.rb
# version 1.0
# Session A (Storage Locations feature, Part 1 of a 6-part session plan —
# see DECOR_PROJECT.md "Storage Locations Feature — Session Plan").
#
# Creates the storage_locations table: a private, owner-managed list of
# physical storage locations (e.g. "Attic Shelf 3", "Garage Box B") that an
# owner can later assign to their own Computers, Peripherals (device_type on
# Computer, not a separate table), Components, and SoftwareItems. The FK
# columns on those four categories are added in Session C, once this table
# exists for them to reference.
#
# Fields:
#   owner_id  integer NOT NULL, FK -> owners.id
#     Each storage_locations row belongs to exactly one owner. This is
#     private, owner-scoped data (confirmed in design consultation: visible
#     only to the owning owner, not other owners, not visitors — but
#     included in admin-wide exports) — never a global/admin-managed lookup
#     table the way component_suggestions or computer_models are.
#
#   name  VARCHAR(50) NOT NULL
#     Free-text label the owner chooses (e.g. "Basement Shelf A"). Uniqueness
#     is enforced PER OWNER, not globally — two different owners may each
#     have a location named "Garage" without conflict.
#     SQLite note: VARCHAR length is cosmetic only at the DB level. No CHECK
#     constraint is added here, matching the existing project convention set
#     by component_suggestions.order_number (see that migration) — length is
#     enforced at the Rails model level via
#     `validates :name, length: { maximum: 50 }` instead.
#
# Unique index on (owner_id, name) enforces "no two locations with the same
# name for the same owner" at the DB level, backing the model-level
# uniqueness validation (defense-in-depth, per PROGRAMMING_GENERAL.md).

class CreateStorageLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :storage_locations do |t|
      t.references :owner, null: false, foreign_key: true
      t.string :name, limit: 50, null: false

      t.timestamps precision: nil
    end

    add_index :storage_locations, [ :owner_id, :name ], unique: true
  end
end
