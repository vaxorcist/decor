# decor/db/migrate/20260225120000_component_conditions_and_type_cleanup.rb
# version 1.0
#
# This migration does five things in a single atomic pass:
#
#   1. Renames the conditions table → computer_conditions (with matching index rename)
#   2. Creates the new component_conditions table
#   3. Recreates computers:
#        - condition_id (FK → conditions) → computer_condition_id (FK → computer_conditions)
#        - order_number TEXT       → VARCHAR(20) + CHECK(length <= 20)
#        - serial_number VARCHAR   → VARCHAR(20) + CHECK(length <= 20)
#   4. Recreates components:
#        - Drops condition_id (FK → conditions, now irrelevant)
#        - Adds component_condition_id FK → component_conditions (nullable, optional)
#        - Adds serial_number VARCHAR(20) + CHECK (nullable)
#        - Adds order_number  VARCHAR(20) + CHECK (nullable)
#   5. Type cleanup across component_types, computer_models, owners, run_statuses:
#        - Tightens VARCHAR columns to specific lengths with CHECK constraints
#
# WHY disable_ddl_transaction!:
#   SQLite's PRAGMA foreign_keys is a no-op inside a transaction. Rails wraps
#   migrations in a transaction by default. We must opt out so the PRAGMA calls
#   actually take effect. The trade-off: if this migration fails mid-way, the
#   database will be in a partial state. Always take a backup before running.
#
# BACKUP REMINDER (run before bin/rails db:migrate):
#   cp storage/development.sqlite3 storage/development.sqlite3.bak
#   cp storage/test.sqlite3 storage/test.sqlite3.bak
#
# This migration has no down method. Reversing a multi-table rename + column
# rename + type change on SQLite is not safely automatable. Roll back via backup.

class ComponentConditionsAndTypeCleanup < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Suspend FK enforcement for the duration of the table operations.
    # Individual tables are temporarily in an inconsistent state while we
    # rename, drop, and recreate them. FK checks would cause false failures.
    execute "PRAGMA foreign_keys = OFF"

    # -------------------------------------------------------------------------
    # Step 1: Rename conditions → computer_conditions
    # -------------------------------------------------------------------------
    # SQLite keeps the old index name after a table rename. Drop and recreate
    # with the correct name so schema.rb reflects the new table name cleanly.
    execute "ALTER TABLE conditions RENAME TO computer_conditions"
    execute "DROP INDEX IF EXISTS \"index_conditions_on_name\""
    execute "CREATE UNIQUE INDEX \"index_computer_conditions_on_name\" ON computer_conditions (name)"

    # -------------------------------------------------------------------------
    # Step 2: Create component_conditions (new table)
    # -------------------------------------------------------------------------
    # Intentional design: the value column is named "condition" (not "name")
    # to distinguish it from the conditions/computer_conditions lookup pattern.
    # No UI yet — admin UI planned for a later session.
    execute <<~SQL
      CREATE TABLE component_conditions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        condition VARCHAR(40) NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        CHECK(length(condition) <= 40)
      )
    SQL
    execute "CREATE UNIQUE INDEX \"index_component_conditions_on_condition\" ON component_conditions (condition)"

    # -------------------------------------------------------------------------
    # Step 3: Recreate computers
    # -------------------------------------------------------------------------
    # Column rename: condition_id → computer_condition_id
    # FK now references computer_conditions (renamed table) instead of conditions.
    # Type changes: order_number TEXT → VARCHAR(20), serial_number VARCHAR → VARCHAR(20)
    execute <<~SQL
      CREATE TABLE computers_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        computer_model_id INTEGER NOT NULL,
        computer_condition_id INTEGER,
        created_at DATETIME NOT NULL,
        history TEXT,
        order_number VARCHAR(20),
        owner_id INTEGER NOT NULL,
        run_status_id INTEGER,
        serial_number VARCHAR(20) NOT NULL,
        updated_at DATETIME NOT NULL,
        FOREIGN KEY (computer_model_id) REFERENCES computer_models(id),
        FOREIGN KEY (computer_condition_id) REFERENCES computer_conditions(id),
        FOREIGN KEY (owner_id) REFERENCES owners(id),
        FOREIGN KEY (run_status_id) REFERENCES run_statuses(id),
        CHECK(length(order_number) <= 20),
        CHECK(length(serial_number) <= 20)
      )
    SQL
    # Copy all rows; map old condition_id to the new computer_condition_id column.
    execute <<~SQL
      INSERT INTO computers_new
        (id, computer_model_id, computer_condition_id, created_at, history,
         order_number, owner_id, run_status_id, serial_number, updated_at)
      SELECT
        id, computer_model_id, condition_id, created_at, history,
        order_number, owner_id, run_status_id, serial_number, updated_at
      FROM computers
    SQL
    execute "DROP TABLE computers"
    execute "ALTER TABLE computers_new RENAME TO computers"
    execute "CREATE INDEX \"index_computers_on_computer_model_id\" ON computers (computer_model_id)"
    execute "CREATE INDEX \"index_computers_on_computer_condition_id\" ON computers (computer_condition_id)"
    execute "CREATE INDEX \"index_computers_on_owner_id\" ON computers (owner_id)"
    execute "CREATE INDEX \"index_computers_on_run_status_id\" ON computers (run_status_id)"

    # -------------------------------------------------------------------------
    # Step 4: Recreate components
    # -------------------------------------------------------------------------
    # Drops condition_id (old FK to conditions — no longer needed).
    # Adds component_condition_id FK → component_conditions (nullable, optional).
    # Adds serial_number and order_number (both VARCHAR(20), nullable).
    execute <<~SQL
      CREATE TABLE components_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        component_type_id INTEGER NOT NULL,
        computer_id INTEGER,
        component_condition_id INTEGER,
        created_at DATETIME NOT NULL,
        description TEXT,
        history TEXT,
        order_number VARCHAR(20),
        owner_id INTEGER NOT NULL,
        serial_number VARCHAR(20),
        updated_at DATETIME NOT NULL,
        FOREIGN KEY (component_type_id) REFERENCES component_types(id),
        FOREIGN KEY (computer_id) REFERENCES computers(id),
        FOREIGN KEY (component_condition_id) REFERENCES component_conditions(id),
        FOREIGN KEY (owner_id) REFERENCES owners(id),
        CHECK(length(order_number) <= 20),
        CHECK(length(serial_number) <= 20)
      )
    SQL
    # condition_id is intentionally omitted — new components use component_condition_id.
    # component_condition_id starts as NULL for all existing components.
    execute <<~SQL
      INSERT INTO components_new
        (id, component_type_id, computer_id, created_at, description,
         history, owner_id, updated_at)
      SELECT
        id, component_type_id, computer_id, created_at, description,
        history, owner_id, updated_at
      FROM components
    SQL
    execute "DROP TABLE components"
    execute "ALTER TABLE components_new RENAME TO components"
    execute "CREATE INDEX \"index_components_on_component_type_id\" ON components (component_type_id)"
    execute "CREATE INDEX \"index_components_on_computer_id\" ON components (computer_id)"
    execute "CREATE INDEX \"index_components_on_component_condition_id\" ON components (component_condition_id)"
    execute "CREATE INDEX \"index_components_on_owner_id\" ON components (owner_id)"

    # -------------------------------------------------------------------------
    # Step 5: Recreate component_types — name VARCHAR → VARCHAR(40) NOT NULL
    # -------------------------------------------------------------------------
    execute <<~SQL
      CREATE TABLE component_types_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at DATETIME NOT NULL,
        name VARCHAR(40) NOT NULL,
        updated_at DATETIME NOT NULL,
        CHECK(length(name) <= 40)
      )
    SQL
    execute <<~SQL
      INSERT INTO component_types_new (id, created_at, name, updated_at)
      SELECT id, created_at, name, updated_at FROM component_types
    SQL
    execute "DROP TABLE component_types"
    execute "ALTER TABLE component_types_new RENAME TO component_types"
    execute "CREATE UNIQUE INDEX \"index_component_types_on_name\" ON component_types (name)"

    # -------------------------------------------------------------------------
    # Step 6: Recreate computer_models — name VARCHAR → VARCHAR(40) NOT NULL
    # -------------------------------------------------------------------------
    execute <<~SQL
      CREATE TABLE computer_models_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at DATETIME NOT NULL,
        name VARCHAR(40) NOT NULL,
        updated_at DATETIME NOT NULL,
        CHECK(length(name) <= 40)
      )
    SQL
    execute <<~SQL
      INSERT INTO computer_models_new (id, created_at, name, updated_at)
      SELECT id, created_at, name, updated_at FROM computer_models
    SQL
    execute "DROP TABLE computer_models"
    execute "ALTER TABLE computer_models_new RENAME TO computer_models"
    execute "CREATE UNIQUE INDEX \"index_computer_models_on_name\" ON computer_models (name)"

    # -------------------------------------------------------------------------
    # Step 7: Recreate owners — tighten VARCHAR lengths + add CHECK constraints
    # -------------------------------------------------------------------------
    # Changes (all CHECK-enforced):
    #   user_name:            VARCHAR → VARCHAR(15)  (matches model validation)
    #   real_name:            VARCHAR → VARCHAR(40)
    #   country_visibility:   VARCHAR → VARCHAR(20)
    #   email_visibility:     VARCHAR → VARCHAR(20)
    #   real_name_visibility: VARCHAR → VARCHAR(20)
    # All other columns preserved exactly as-is (country, email, password_digest,
    # website, reset_password_token are left as unconstrained VARCHAR).
    execute <<~SQL
      CREATE TABLE owners_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin BOOLEAN NOT NULL DEFAULT 0,
        country VARCHAR,
        country_visibility VARCHAR(20),
        created_at DATETIME NOT NULL,
        email VARCHAR,
        email_visibility VARCHAR(20),
        password_digest VARCHAR,
        real_name VARCHAR(40),
        real_name_visibility VARCHAR(20),
        reset_password_sent_at DATETIME,
        reset_password_token VARCHAR,
        updated_at DATETIME NOT NULL,
        user_name VARCHAR(15),
        website VARCHAR,
        CHECK(length(country_visibility) <= 20),
        CHECK(length(email_visibility) <= 20),
        CHECK(length(real_name) <= 40),
        CHECK(length(real_name_visibility) <= 20),
        CHECK(length(user_name) <= 15)
      )
    SQL
    execute <<~SQL
      INSERT INTO owners_new
        (id, admin, country, country_visibility, created_at, email, email_visibility,
         password_digest, real_name, real_name_visibility, reset_password_sent_at,
         reset_password_token, updated_at, user_name, website)
      SELECT
        id, admin, country, country_visibility, created_at, email, email_visibility,
        password_digest, real_name, real_name_visibility, reset_password_sent_at,
        reset_password_token, updated_at, user_name, website
      FROM owners
    SQL
    execute "DROP TABLE owners"
    execute "ALTER TABLE owners_new RENAME TO owners"
    execute "CREATE INDEX \"index_owners_on_country\" ON owners (country)"
    execute "CREATE INDEX \"index_owners_on_country_visibility\" ON owners (country_visibility)"
    execute "CREATE UNIQUE INDEX \"index_owners_on_email\" ON owners (email)"
    execute "CREATE INDEX \"index_owners_on_email_visibility\" ON owners (email_visibility)"
    execute "CREATE INDEX \"index_owners_on_real_name_visibility\" ON owners (real_name_visibility)"
    execute "CREATE UNIQUE INDEX \"index_owners_on_reset_password_token\" ON owners (reset_password_token)"
    execute "CREATE UNIQUE INDEX \"index_owners_on_user_name\" ON owners (user_name)"

    # -------------------------------------------------------------------------
    # Step 8: Recreate run_statuses — name VARCHAR → VARCHAR(40) (nullable kept)
    # -------------------------------------------------------------------------
    # Note: name is nullable in the original schema (no null: false). Preserved.
    execute <<~SQL
      CREATE TABLE run_statuses_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at DATETIME NOT NULL,
        name VARCHAR(40),
        updated_at DATETIME NOT NULL,
        CHECK(length(name) <= 40)
      )
    SQL
    execute <<~SQL
      INSERT INTO run_statuses_new (id, created_at, name, updated_at)
      SELECT id, created_at, name, updated_at FROM run_statuses
    SQL
    execute "DROP TABLE run_statuses"
    execute "ALTER TABLE run_statuses_new RENAME TO run_statuses"
    execute "CREATE UNIQUE INDEX \"index_run_statuses_on_name\" ON run_statuses (name)"

    # Re-enable FK enforcement now that all tables are in their final state.
    execute "PRAGMA foreign_keys = ON"
  end
end
