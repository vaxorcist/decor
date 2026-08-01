# decor/db/migrate/20260730120000_add_storage_location_to_computers_components_software_items.rb
# version 1.1
# v1.1: Timestamp corrected from 20260803000100 (an invented future date)
#   to 20260730120000. bin/rails db:migrate rejected the original with
#   ActiveRecord::InvalidMigrationTimestampError — Rails validates migration
#   timestamps against the real wall-clock time the command runs at, not
#   against this project's fictional in-session "current date." The new
#   timestamp is safely after the last real migration (20260727000100,
#   Session A) and before the actual current time. DELETE the old
#   20260803000100_...rb file from db/migrate/ before running db:migrate —
#   having both would create two migrations for the same change.
#
# v1.0 (Session C, Storage Locations feature, Part 3 of 6 — see
# DECOR_PROJECT.md "Storage Locations Feature — Session Plan").
#
# Adds a nullable storage_location_id FK to computers, components, and
# software_items. Unlike the Owner Part Number migration pair
# (20260716000100 / 20260716000200), this does NOT require SQLite's full
# table-recreation pattern (RAILS_SPECIFICS.md "SQLite ALTER TABLE
# Limitations") — that pattern is only needed when adding a NOT NULL
# constraint or rebuilding a unique index on an EXISTING column, neither of
# which applies here:
#   - storage_location_id is nullable on all three tables — belongs_to
#     :storage_location, optional: true on all three models (computer.rb
#     v2.4, component.rb v1.9, software_item.rb v1.1) — a brand-new
#     nullable column needs no backfill.
#   - No uniqueness constraint touches this column.
# A plain add_reference is therefore sufficient (no disable_ddl_transaction!
# needed).
#
# on_delete deliberately NOT set on any of the three add_reference calls
# below — follows the same precedent already in this schema:
# storage_locations -> owners (Session A) has no on_delete option either,
# relying entirely on Owner's Ruby-side has_many :storage_locations,
# dependent: :destroy. The equivalent Ruby-side behaviour here is
# StorageLocation's has_many :computers/:components/:software_items,
# dependent: :nullify (storage_location.rb v1.1). Leaving on_delete unset
# means the DB's default FK behaviour (RESTRICT, since config/database.yml
# has foreign_keys: true) protects against a raw SQL DELETE bypassing
# Rails.
class AddStorageLocationToComputersComponentsSoftwareItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :computers,      :storage_location, foreign_key: true, index: true
    add_reference :components,     :storage_location, foreign_key: true, index: true
    add_reference :software_items, :storage_location, foreign_key: true, index: true
  end
end
