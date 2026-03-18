# decor/db/migrate/20260318000000_add_device_type_check_to_computer_models.rb
# version 1.0
#
# Adds CHECK(device_type IN (0,1,2)) constraint to the computer_models table.
#
# Background:
#   The device_type enum on ComputerModel maps { computer: 0, appliance: 1, peripheral: 2 }.
#   The companion computers table received this constraint in Session 25
#   (migration 20260316100000). This migration closes the same gap for computer_models.
#
# Why table recreation is required:
#   SQLite cannot add named CHECK constraints to existing columns via ALTER TABLE.
#   The only way to enforce CHECK constraints in SQLite is to declare them in the
#   CREATE TABLE statement, which requires full table recreation.
#
# Safety notes:
#   - disable_ddl_transaction! is required because PRAGMA foreign_keys is a no-op
#     inside a transaction, and Rails wraps migrations in transactions by default.
#   - Explicit column names on both sides of the INSERT/SELECT guard against silent
#     data corruption due to SQLite storage order differing from schema.rb column order.
#   - PRAGMA foreign_keys = OFF is required to allow DROP/RENAME while computers
#     holds a foreign key reference to computer_models.
#
# Columns (from schema.rb):
#   id          INTEGER PRIMARY KEY (autoincrement managed by Rails)
#   created_at  DATETIME NOT NULL
#   device_type INTEGER NOT NULL DEFAULT 0
#   name        VARCHAR(40) NOT NULL
#   updated_at  DATETIME NOT NULL
#
# Indexes to recreate:
#   index_computer_models_on_device_type  (device_type)
#   index_computer_models_on_name         (name) UNIQUE

class AddDeviceTypeCheckToComputerModels < ActiveRecord::Migration[8.1]
  # Required so that PRAGMA foreign_keys = OFF/ON takes effect outside a transaction.
  disable_ddl_transaction!

  # Explicit column list used on both sides of INSERT/SELECT.
  # Declaring as a constant makes both up and down symmetric and self-documenting.
  COLUMNS = %w[id created_at device_type name updated_at].freeze

  def up
    execute "PRAGMA foreign_keys = OFF"

    # Create the replacement table with the CHECK constraint.
    execute <<~SQL
      CREATE TABLE computer_models_new (
        id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        created_at  DATETIME NOT NULL,
        device_type INTEGER NOT NULL DEFAULT 0
                    CHECK(device_type IN (0,1,2)),
        name        VARCHAR(40) NOT NULL,
        updated_at  DATETIME NOT NULL
      )
    SQL

    # Copy all rows using explicit column names on both sides (never SELECT *).
    col_list = COLUMNS.join(", ")
    execute "INSERT INTO computer_models_new (#{col_list}) SELECT #{col_list} FROM computer_models"

    # Replace the old table.
    execute "DROP TABLE computer_models"
    execute "ALTER TABLE computer_models_new RENAME TO computer_models"

    # Recreate indexes.
    execute "CREATE INDEX index_computer_models_on_device_type ON computer_models (device_type)"
    execute "CREATE UNIQUE INDEX index_computer_models_on_name ON computer_models (name)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"

    # Recreate the table without the CHECK constraint.
    execute <<~SQL
      CREATE TABLE computer_models_new (
        id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        created_at  DATETIME NOT NULL,
        device_type INTEGER NOT NULL DEFAULT 0,
        name        VARCHAR(40) NOT NULL,
        updated_at  DATETIME NOT NULL
      )
    SQL

    col_list = COLUMNS.join(", ")
    execute "INSERT INTO computer_models_new (#{col_list}) SELECT #{col_list} FROM computer_models"

    execute "DROP TABLE computer_models"
    execute "ALTER TABLE computer_models_new RENAME TO computer_models"

    execute "CREATE INDEX index_computer_models_on_device_type ON computer_models (device_type)"
    execute "CREATE UNIQUE INDEX index_computer_models_on_name ON computer_models (name)"

    execute "PRAGMA foreign_keys = ON"
  end
end
