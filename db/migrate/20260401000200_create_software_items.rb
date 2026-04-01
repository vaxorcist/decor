# decor/db/migrate/20260401000200_create_software_items.rb
# version 1.0
# Session 43: Part of the Software feature (Option C — full separation).
#   Creates the software_items table. Each row represents one software title
#   owned by an owner, optionally installed on a computer or peripheral.
#
#   FK design rationale:
#     owner_id      — NOT NULL; owner deletion cascades at Ruby level
#                     (Owner has_many :software_items, dependent: :destroy).
#                     No DB-level ON DELETE needed — Rails handles it.
#     computer_id   — nullable; "installed on" a computer or peripheral
#                     (peripherals are device_type=2 rows in the computers
#                     table, so one FK covers both device types).
#                     ON DELETE CASCADE: deleting a computer destroys all
#                     software installed on it (design decision, Session 43).
#                     Defense-in-depth alongside the Ruby dependent: :destroy.
#     software_name_id      — NOT NULL; the software title must exist.
#     software_condition_id — nullable; condition is optional.
#
#   barter_status integer matches the Component/Computer enum:
#     0 = no_barter, 1 = offered, 2 = wanted.
#
#   Raw SQL required for CHECK constraints.
#   disable_ddl_transaction! required for PRAGMA to take effect.

class CreateSoftwareItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE software_items (
        id                    INTEGER      PRIMARY KEY AUTOINCREMENT NOT NULL,
        owner_id              INTEGER      NOT NULL REFERENCES owners(id),
        computer_id           INTEGER      REFERENCES computers(id) ON DELETE CASCADE,
        software_name_id      INTEGER      NOT NULL REFERENCES software_names(id),
        software_condition_id INTEGER      REFERENCES software_conditions(id),
        barter_status         INTEGER      NOT NULL DEFAULT 0,
        version               VARCHAR(20)  CHECK(length(version) <= 20),
        description           VARCHAR(100) CHECK(length(description) <= 100),
        history               VARCHAR(200) CHECK(length(history) <= 200),
        created_at            DATETIME     NOT NULL,
        updated_at            DATETIME     NOT NULL
      )
    SQL

    # Indexes on FK columns for join and filter performance.
    execute "CREATE INDEX index_software_items_on_owner_id          ON software_items (owner_id)"
    execute "CREATE INDEX index_software_items_on_computer_id       ON software_items (computer_id)"
    execute "CREATE INDEX index_software_items_on_software_name_id  ON software_items (software_name_id)"
    execute "CREATE INDEX index_software_items_on_software_condition_id ON software_items (software_condition_id)"
    execute "CREATE INDEX index_software_items_on_barter_status     ON software_items (barter_status)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"
    execute "DROP TABLE IF EXISTS software_items"
    execute "PRAGMA foreign_keys = ON"
  end
end
