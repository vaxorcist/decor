# decor/db/migrate/20260401000100_create_software_conditions.rb
# version 1.0
# Session 43: Part of the Software feature (Option C — full separation).
#   Creates the software_conditions admin-managed lookup table, analogous to
#   component_conditions. Stores condition labels specific to software
#   (Complete, Incomplete, Subset) together with an optional description.
#
#   Note: component_conditions uses column name "condition" (historical).
#   software_conditions uses "name" — cleaner convention for a new table.
#
#   Raw SQL required for CHECK constraints (see 20260401000000 for rationale).
#   disable_ddl_transaction! required for PRAGMA to take effect.

class CreateSoftwareConditions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE software_conditions (
        id          INTEGER      PRIMARY KEY AUTOINCREMENT NOT NULL,
        name        VARCHAR(40)  NOT NULL CHECK(length(name) <= 40),
        description VARCHAR(100) CHECK(length(description) <= 100),
        created_at  DATETIME     NOT NULL,
        updated_at  DATETIME     NOT NULL
      )
    SQL

    execute "CREATE UNIQUE INDEX index_software_conditions_on_name ON software_conditions (name)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"
    execute "DROP TABLE IF EXISTS software_conditions"
    execute "PRAGMA foreign_keys = ON"
  end
end
