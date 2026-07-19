# decor/db/migrate/20260716000200_enforce_owner_part_number_constraints.rb
# version 1.0
# Session 70: Owner Part Number feature — Migration 2 of 2 (constraint step).
#
# Runs AFTER 20260716000100 has backfilled every row. This migration:
#   - computers:  owner_part_number becomes NOT NULL.
#   - components: serial_number AND owner_part_number both become NOT NULL
#                 (components.serial_number was allow_blank: true before this).
#   - Both tables: drop the old 3-column unique index (owner+model/type+serial)
#                  and add the new 4-column unique index (owner+model/type+
#                  owner_part_number+serial), per Ulli's confirmed scope —
#                  keeping the existing model/type dimension.
#
# SQLite cannot ALTER COLUMN to add a NOT NULL constraint to an existing
# nullable column — this requires the full table-recreation pattern from
# RAILS_SPECIFICS.md "SQLite ALTER TABLE Limitations": PRAGMA foreign_keys
# OFF, CREATE TABLE new (explicit columns, not SELECT *), INSERT ... SELECT
# with explicit column lists on both sides, DROP old, RENAME, recreate every
# index/FK the original table had, PRAGMA foreign_keys ON.
#
# disable_ddl_transaction! is required because PRAGMA foreign_keys is a
# no-op inside a transaction (RAILS_SPECIFICS.md "SQLite Foreign Key
# Enforcement").
#
# This migration is NOT reversible (data-narrowing NOT NULL change combined
# with a full recreation) — down raises IrreversibleMigration, matching the
# project's existing pattern for this class of migration.

class EnforceOwnerPartNumberConstraints < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Explicit column lists — alphabetical, matching schema.rb's existing order
  # with owner_part_number inserted in its alphabetical position (after
  # owner_id, before run_status_id / serial_number). Per RAILS_SPECIFICS.md
  # "SQLite Table Recreation — Always Use Explicit Column Names": never
  # SELECT * during the INSERT step.
  COMPUTERS_COLUMNS = %w[
    id barter_status computer_condition_id computer_model_id created_at
    device_type history order_number owner_id owner_part_number
    run_status_id serial_number updated_at
  ].freeze

  COMPONENTS_COLUMNS = %w[
    id barter_status component_category component_condition_id
    component_type_id computer_id created_at description history
    order_number order_number_verified owner_id owner_part_number
    serial_number updated_at
  ].freeze

  def up
    execute "PRAGMA foreign_keys = OFF"

    recreate_computers_table
    recreate_components_table

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def recreate_computers_table
    execute <<~SQL
      CREATE TABLE computers_new (
        id INTEGER PRIMARY KEY,
        barter_status INTEGER NOT NULL DEFAULT 0,
        computer_condition_id INTEGER,
        computer_model_id INTEGER NOT NULL,
        created_at DATETIME NOT NULL,
        device_type INTEGER NOT NULL DEFAULT 0,
        history TEXT,
        order_number VARCHAR(20),
        owner_id INTEGER NOT NULL,
        owner_part_number VARCHAR(20) NOT NULL,
        run_status_id INTEGER,
        serial_number VARCHAR(20) NOT NULL,
        updated_at DATETIME NOT NULL
      )
    SQL

    col_list = COMPUTERS_COLUMNS.join(", ")
    execute "INSERT INTO computers_new (#{col_list}) SELECT #{col_list} FROM computers"

    execute "DROP TABLE computers"
    execute "ALTER TABLE computers_new RENAME TO computers"

    # Recreate every index the original table had (see schema.rb v2026_07_07_000100),
    # replacing the old 3-column unique index with the new 4-column one.
    add_index :computers, :barter_status
    add_index :computers, :computer_condition_id
    add_index :computers, :computer_model_id
    add_index :computers, :device_type
    add_index :computers, :owner_id
    add_index :computers, :run_status_id
    add_index :computers,
              [:owner_id, :computer_model_id, :owner_part_number, :serial_number],
              unique: true,
              name: "index_computers_on_owner_model_opn_and_serial_number"

    # Recreate every FK the original table had.
    add_foreign_key :computers, :computer_conditions
    add_foreign_key :computers, :computer_models
    add_foreign_key :computers, :owners
    add_foreign_key :computers, :run_statuses
  end

  def recreate_components_table
    execute <<~SQL
      CREATE TABLE components_new (
        id INTEGER PRIMARY KEY,
        barter_status INTEGER NOT NULL DEFAULT 0,
        component_category INTEGER NOT NULL DEFAULT 0,
        component_condition_id INTEGER,
        component_type_id INTEGER NOT NULL,
        computer_id INTEGER,
        created_at DATETIME NOT NULL,
        description TEXT,
        history TEXT,
        order_number VARCHAR(20),
        order_number_verified BOOLEAN NOT NULL DEFAULT 0,
        owner_id INTEGER NOT NULL,
        owner_part_number VARCHAR(20) NOT NULL,
        serial_number VARCHAR(20) NOT NULL,
        updated_at DATETIME NOT NULL
      )
    SQL

    col_list = COMPONENTS_COLUMNS.join(", ")
    execute "INSERT INTO components_new (#{col_list}) SELECT #{col_list} FROM components"

    execute "DROP TABLE components"
    execute "ALTER TABLE components_new RENAME TO components"

    # Recreate every index the original table had, replacing the old
    # 3-column unique index with the new 4-column one.
    add_index :components, :barter_status
    add_index :components, :component_category
    add_index :components, :component_condition_id
    add_index :components, :component_type_id
    add_index :components, :computer_id
    add_index :components, :owner_id
    add_index :components,
              [:owner_id, :component_type_id, :owner_part_number, :serial_number],
              unique: true,
              name: "index_components_on_owner_type_opn_and_serial_number"

    # Recreate every FK the original table had.
    add_foreign_key :components, :component_conditions
    add_foreign_key :components, :component_types
    add_foreign_key :components, :computers, on_delete: :cascade
    add_foreign_key :components, :owners
  end
end
