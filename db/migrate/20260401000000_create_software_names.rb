# decor/db/migrate/20260401000000_create_software_names.rb
# version 1.0
# Session 43: Part of the Software feature (Option C — full separation).
#   Creates the software_names admin-managed lookup table, analogous to
#   component_types. Stores the canonical name of a software title (e.g. VMS,
#   RT-11, RSTS/E) together with an optional description.
#
#   Raw SQL is required (instead of the Rails DSL create_table block) because
#   SQLite ignores VARCHAR(n) length limits at runtime unless an explicit
#   CHECK constraint is also declared. The Rails migration DSL has no way to
#   emit CHECK constraints for SQLite.
#
#   disable_ddl_transaction! is mandatory: PRAGMA statements are silently
#   no-ops inside a transaction, and Rails wraps migrations in transactions
#   by default.

class CreateSoftwareNames < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE software_names (
        id          INTEGER      PRIMARY KEY AUTOINCREMENT NOT NULL,
        name        VARCHAR(40)  NOT NULL CHECK(length(name) <= 40),
        description VARCHAR(100) CHECK(length(description) <= 100),
        created_at  DATETIME     NOT NULL,
        updated_at  DATETIME     NOT NULL
      )
    SQL

    # Uniqueness enforced at both DB level (index) and model level (validation).
    execute "CREATE UNIQUE INDEX index_software_names_on_name ON software_names (name)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"
    execute "DROP TABLE IF EXISTS software_names"
    execute "PRAGMA foreign_keys = ON"
  end
end
