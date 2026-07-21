# decor/db/migrate/20260721000100_limit_history_length_on_computers_and_components.rb - version 1.0
# Session 74: History-length limit feature. Both computers.history and
#   components.history were unqualified "t.text" — unbounded TEXT, in
#   violation of PROGRAMMING_GENERAL.md's mandatory VARCHAR(n)-with-explicit-
#   length rule (TEXT requires prior approval; neither of these had it).
#   Ulli confirmed a 500-character maximum for both. software_items.history
#   is untouched — it's already VARCHAR(200), added correctly in Session 43.
#
#   SQLite cannot ALTER TABLE to add a length-enforcing CHECK constraint to
#   an existing column (RAILS_SPECIFICS.md "SQLite ALTER TABLE Limitations"),
#   so both tables are fully recreated here, per the project's established
#   pattern: explicit column lists on both sides of the INSERT (never
#   SELECT *), PRAGMA foreign_keys OFF/ON around the swap, indexes and FK
#   REFERENCES clauses reproduced exactly as they exist in db/schema.rb
#   (version 2026_07_16_000200) — nothing else about either table's shape
#   changes, only history's type/length.
#
#   Step 1 of PROGRAMMING_GENERAL.md's "Check Production Data Before Adding
#   Constraints" 3-step process: guarded with a pre-check that raises with an
#   exact violation count rather than silently truncating real history text
#   if any existing row is already longer than 500 characters. If this ever
#   fires, resolve the offending rows manually (trim, or confirm truncation
#   is acceptable) before re-running this migration — do not remove the
#   guard to force it through.
#
#   Irreversible: `down` intentionally raises. Reversing would mean
#   round-tripping VARCHAR(500) back to unbounded TEXT, which is possible,
#   but there's no current need for it and writing a speculative down
#   migration risks bit-rotting silently untested. Revisit if ever needed.
class LimitHistoryLengthOnComputersAndComponents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # --- Step 1: guard against pre-existing violations ---------------------
    over_limit_computers  = execute("SELECT COUNT(*) AS c FROM computers WHERE history IS NOT NULL AND LENGTH(history) > 500").first["c"]
    over_limit_components = execute("SELECT COUNT(*) AS c FROM components WHERE history IS NOT NULL AND LENGTH(history) > 500").first["c"]

    if over_limit_computers.to_i.positive? || over_limit_components.to_i.positive?
      raise "Found #{over_limit_computers} computer/peripheral row(s) and " \
            "#{over_limit_components} component row(s) with history longer " \
            "than 500 characters. Resolve manually (trim the text or confirm " \
            "truncation is acceptable) before re-running this migration."
    end

    execute "PRAGMA foreign_keys = OFF"

    # --- computers -----------------------------------------------------------
    execute <<~SQL
      CREATE TABLE computers_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL REFERENCES owners (id),
        computer_model_id INTEGER NOT NULL REFERENCES computer_models (id),
        computer_condition_id INTEGER REFERENCES computer_conditions (id),
        run_status_id INTEGER REFERENCES run_statuses (id),
        device_type INTEGER NOT NULL DEFAULT 0,
        barter_status INTEGER NOT NULL DEFAULT 0,
        serial_number VARCHAR(20) NOT NULL,
        owner_part_number VARCHAR(20) NOT NULL,
        order_number VARCHAR(20),
        history VARCHAR(500),
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        CHECK (history IS NULL OR LENGTH(history) <= 500)
      )
    SQL

    computers_columns = %w[
      id owner_id computer_model_id computer_condition_id run_status_id
      device_type barter_status serial_number owner_part_number order_number
      history created_at updated_at
    ]
    computers_col_list = computers_columns.join(", ")
    execute "INSERT INTO computers_new (#{computers_col_list}) SELECT #{computers_col_list} FROM computers"

    execute "DROP TABLE computers"
    execute "ALTER TABLE computers_new RENAME TO computers"

    execute "CREATE INDEX index_computers_on_barter_status ON computers (barter_status)"
    execute "CREATE INDEX index_computers_on_computer_condition_id ON computers (computer_condition_id)"
    execute "CREATE INDEX index_computers_on_computer_model_id ON computers (computer_model_id)"
    execute "CREATE INDEX index_computers_on_device_type ON computers (device_type)"
    execute "CREATE UNIQUE INDEX index_computers_on_owner_model_opn_and_serial_number ON computers (owner_id, computer_model_id, owner_part_number, serial_number)"
    execute "CREATE INDEX index_computers_on_owner_id ON computers (owner_id)"
    execute "CREATE INDEX index_computers_on_run_status_id ON computers (run_status_id)"

    # --- components ------------------------------------------------------------
    execute <<~SQL
      CREATE TABLE components_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL REFERENCES owners (id),
        computer_id INTEGER REFERENCES computers (id) ON DELETE CASCADE,
        component_type_id INTEGER NOT NULL REFERENCES component_types (id),
        component_condition_id INTEGER REFERENCES component_conditions (id),
        component_category INTEGER NOT NULL DEFAULT 0,
        barter_status INTEGER NOT NULL DEFAULT 0,
        serial_number VARCHAR(20) NOT NULL,
        owner_part_number VARCHAR(20) NOT NULL,
        order_number VARCHAR(20),
        order_number_verified BOOLEAN NOT NULL DEFAULT 0,
        description TEXT,
        history VARCHAR(500),
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        CHECK (history IS NULL OR LENGTH(history) <= 500)
      )
    SQL

    components_columns = %w[
      id owner_id computer_id component_type_id component_condition_id
      component_category barter_status serial_number owner_part_number
      order_number order_number_verified description history created_at updated_at
    ]
    components_col_list = components_columns.join(", ")
    execute "INSERT INTO components_new (#{components_col_list}) SELECT #{components_col_list} FROM components"

    execute "DROP TABLE components"
    execute "ALTER TABLE components_new RENAME TO components"

    execute "CREATE INDEX index_components_on_barter_status ON components (barter_status)"
    execute "CREATE INDEX index_components_on_component_category ON components (component_category)"
    execute "CREATE INDEX index_components_on_component_condition_id ON components (component_condition_id)"
    execute "CREATE INDEX index_components_on_component_type_id ON components (component_type_id)"
    execute "CREATE INDEX index_components_on_computer_id ON components (computer_id)"
    execute "CREATE UNIQUE INDEX index_components_on_owner_type_opn_and_serial_number ON components (owner_id, component_type_id, owner_part_number, serial_number)"
    execute "CREATE INDEX index_components_on_owner_id ON components (owner_id)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
