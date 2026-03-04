# decor/db/migrate/20260304120000_add_cascade_delete_components_computer.rb
# version 1.1
# Adds ON DELETE CASCADE to the components → computers foreign key at the
# database level. The Rails-layer dependent: :destroy (computer.rb v1.4,
# Session 12) already handles this in normal operation. The DB-level cascade
# is defence-in-depth: it ensures components are deleted even if a computer
# record is removed by raw SQL, a bulk operation, or any path that bypasses
# the Rails model layer.
#
# SQLite cannot modify FK constraints on existing tables via ALTER TABLE.
# Full table recreation is required — the same pattern used in prior migrations
# (see 20260225120000_component_conditions_and_type_cleanup.rb).
#
# disable_ddl_transaction! is required because PRAGMA foreign_keys is a no-op
# inside a transaction (Rails wraps migrations in transactions by default).
#
# v1.1 fix: INSERT must use explicit column names on both sides, not SELECT *.
# schema.rb lists columns alphabetically, but SQLite stores them in the order
# they were added by successive migrations. SELECT * returns columns in storage
# order; positional INSERT into the new table (with potentially different order)
# causes data to land in the wrong columns, triggering NOT NULL violations even
# when the source data is clean.

class AddCascadeDeleteComponentsComputer < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Explicit column list — used in both up and down to guarantee name-based
  # mapping regardless of storage order in the source table.
  COLUMNS = %w[
    id
    component_category
    component_condition_id
    component_type_id
    computer_id
    created_at
    description
    history
    order_number
    owner_id
    serial_number
    updated_at
  ].freeze

  def up
    execute "PRAGMA foreign_keys = OFF"

    # Create replacement table with ON DELETE CASCADE on computer_id.
    # All other columns, constraints, and FK relationships preserved exactly
    # as they appear in schema.rb (version: 2026_03_03_110000).
    execute <<~SQL
      CREATE TABLE components_new (
        id                     INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
        component_category     INTEGER  DEFAULT 0 NOT NULL,
        component_condition_id INTEGER,
        component_type_id      INTEGER  NOT NULL,
        computer_id            INTEGER,
        created_at             DATETIME NOT NULL,
        description            TEXT,
        history                TEXT,
        order_number           VARCHAR(20),
        owner_id               INTEGER  NOT NULL,
        serial_number          VARCHAR(20),
        updated_at             DATETIME NOT NULL,
        FOREIGN KEY (component_condition_id) REFERENCES component_conditions(id),
        FOREIGN KEY (component_type_id)      REFERENCES component_types(id),
        FOREIGN KEY (computer_id)            REFERENCES computers(id) ON DELETE CASCADE,
        FOREIGN KEY (owner_id)               REFERENCES owners(id)
      )
    SQL

    # Copy data by name, not position — immune to column order differences
    # between the original SQLite storage order and the new table definition.
    col_list = COLUMNS.join(", ")
    execute "INSERT INTO components_new (#{col_list}) SELECT #{col_list} FROM components"

    execute "DROP TABLE components"
    execute "ALTER TABLE components_new RENAME TO components"

    # Recreate all indexes from the original table.
    execute "CREATE INDEX index_components_on_component_category     ON components (component_category)"
    execute "CREATE INDEX index_components_on_component_condition_id ON components (component_condition_id)"
    execute "CREATE INDEX index_components_on_component_type_id      ON components (component_type_id)"
    execute "CREATE INDEX index_components_on_computer_id            ON components (computer_id)"
    execute "CREATE INDEX index_components_on_owner_id               ON components (owner_id)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE components_new (
        id                     INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
        component_category     INTEGER  DEFAULT 0 NOT NULL,
        component_condition_id INTEGER,
        component_type_id      INTEGER  NOT NULL,
        computer_id            INTEGER,
        created_at             DATETIME NOT NULL,
        description            TEXT,
        history                TEXT,
        order_number           VARCHAR(20),
        owner_id               INTEGER  NOT NULL,
        serial_number          VARCHAR(20),
        updated_at             DATETIME NOT NULL,
        FOREIGN KEY (component_condition_id) REFERENCES component_conditions(id),
        FOREIGN KEY (component_type_id)      REFERENCES component_types(id),
        FOREIGN KEY (computer_id)            REFERENCES computers(id),
        FOREIGN KEY (owner_id)               REFERENCES owners(id)
      )
    SQL

    col_list = COLUMNS.join(", ")
    execute "INSERT INTO components_new (#{col_list}) SELECT #{col_list} FROM components"

    execute "DROP TABLE components"
    execute "ALTER TABLE components_new RENAME TO components"

    execute "CREATE INDEX index_components_on_component_category     ON components (component_category)"
    execute "CREATE INDEX index_components_on_component_condition_id ON components (component_condition_id)"
    execute "CREATE INDEX index_components_on_component_type_id      ON components (component_type_id)"
    execute "CREATE INDEX index_components_on_computer_id            ON components (computer_id)"
    execute "CREATE INDEX index_components_on_owner_id               ON components (owner_id)"

    execute "PRAGMA foreign_keys = ON"
  end
end
