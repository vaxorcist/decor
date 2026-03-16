# decor/db/migrate/20260316100000_add_device_type_check_to_computers.rb
# version 1.0
#
# Adds CHECK(device_type IN (0, 1, 2)) constraint to computers.device_type.
#
# Background:
#   The device_type column was added in migration 20260303100000 with only
#   values 0 (computer) and 1 (appliance) in use. Session 25 introduces
#   value 2 (peripheral) for items such as terminals and word-processors
#   that attach to a host computer. The constraint now covers all three
#   valid values and prevents invalid integers from reaching the application
#   via direct database access or bulk imports.
#
# SQLite limitation:
#   SQLite cannot add a CHECK constraint to an existing column via ALTER TABLE.
#   A full table recreation is required. This migration follows the pattern
#   documented in RAILS_SPECIFICS.md: create new table, copy data, drop old
#   table, rename. PRAGMA foreign_keys must be OFF during recreation to avoid
#   FK violations on the intermediate tables.
#
# disable_ddl_transaction! is required because PRAGMA foreign_keys is a no-op
# inside a transaction (Rails wraps migrations in transactions by default).
#
# Enum mapping after this migration (defined in app/models/computer.rb):
#   0 = computer   (default)
#   1 = appliance
#   2 = peripheral (new — terminals, word-processors, etc.)
#
# Note: computer_models.device_type has the same enum but no CHECK constraint.
#   A separate migration should add CHECK(device_type IN (0,1,2)) there once
#   peripheral models are added via the admin interface.

class AddDeviceTypeCheckToComputers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Columns in schema.rb alphabetical order, id first.
  # Explicit column names on both sides of INSERT/SELECT prevent silent data
  # corruption when SQLite storage order differs from schema.rb column order.
  # See RAILS_SPECIFICS.md — "SQLite Table Recreation — Always Use Explicit
  # Column Names".
  COLUMNS = %w[
    id barter_status computer_condition_id computer_model_id
    created_at device_type history order_number
    owner_id run_status_id serial_number updated_at
  ].freeze

  def up
    execute "PRAGMA foreign_keys = OFF"

    # Create the replacement table with the CHECK constraint on device_type.
    # FK declarations are included inline so they are enforced once PRAGMA
    # foreign_keys is re-enabled.
    execute <<~SQL
      CREATE TABLE computers_new (
        id                    INTEGER  PRIMARY KEY AUTOINCREMENT,
        barter_status         INTEGER  NOT NULL DEFAULT 0,
        computer_condition_id INTEGER  REFERENCES computer_conditions(id),
        computer_model_id     INTEGER  NOT NULL REFERENCES computer_models(id),
        created_at            DATETIME NOT NULL,
        device_type           INTEGER  NOT NULL DEFAULT 0
                                       CHECK(device_type IN (0, 1, 2)),
        history               TEXT,
        order_number          VARCHAR(20),
        owner_id              INTEGER  NOT NULL REFERENCES owners(id),
        run_status_id         INTEGER  REFERENCES run_statuses(id),
        serial_number         VARCHAR(20) NOT NULL,
        updated_at            DATETIME NOT NULL
      )
    SQL

    col_list = COLUMNS.join(", ")
    execute "INSERT INTO computers_new (#{col_list}) SELECT #{col_list} FROM computers"

    execute "DROP TABLE computers"
    execute "ALTER TABLE computers_new RENAME TO computers"

    # Recreate all indexes that existed on the original table.
    execute "CREATE INDEX index_computers_on_barter_status         ON computers (barter_status)"
    execute "CREATE INDEX index_computers_on_computer_condition_id ON computers (computer_condition_id)"
    execute "CREATE INDEX index_computers_on_computer_model_id     ON computers (computer_model_id)"
    execute "CREATE INDEX index_computers_on_device_type           ON computers (device_type)"
    execute "CREATE INDEX index_computers_on_owner_id              ON computers (owner_id)"
    execute "CREATE INDEX index_computers_on_run_status_id         ON computers (run_status_id)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    # Remove the CHECK constraint by recreating the table without it.
    # Any device_type = 2 rows left in the database will remain; they will no
    # longer be constrained. The enum in computer.rb must be rolled back
    # separately to avoid referencing value 2 in application code.
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE computers_new (
        id                    INTEGER  PRIMARY KEY AUTOINCREMENT,
        barter_status         INTEGER  NOT NULL DEFAULT 0,
        computer_condition_id INTEGER  REFERENCES computer_conditions(id),
        computer_model_id     INTEGER  NOT NULL REFERENCES computer_models(id),
        created_at            DATETIME NOT NULL,
        device_type           INTEGER  NOT NULL DEFAULT 0,
        history               TEXT,
        order_number          VARCHAR(20),
        owner_id              INTEGER  NOT NULL REFERENCES owners(id),
        run_status_id         INTEGER  REFERENCES run_statuses(id),
        serial_number         VARCHAR(20) NOT NULL,
        updated_at            DATETIME NOT NULL
      )
    SQL

    col_list = COLUMNS.join(", ")
    execute "INSERT INTO computers_new (#{col_list}) SELECT #{col_list} FROM computers"

    execute "DROP TABLE computers"
    execute "ALTER TABLE computers_new RENAME TO computers"

    execute "CREATE INDEX index_computers_on_barter_status         ON computers (barter_status)"
    execute "CREATE INDEX index_computers_on_computer_condition_id ON computers (computer_condition_id)"
    execute "CREATE INDEX index_computers_on_computer_model_id     ON computers (computer_model_id)"
    execute "CREATE INDEX index_computers_on_device_type           ON computers (device_type)"
    execute "CREATE INDEX index_computers_on_owner_id              ON computers (owner_id)"
    execute "CREATE INDEX index_computers_on_run_status_id         ON computers (run_status_id)"

    execute "PRAGMA foreign_keys = ON"
  end
end
