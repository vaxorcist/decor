# decor/db/migrate/20260323000000_add_owner_group_id_to_connection_groups.rb
# version 1.0
# Session 38: Adds owner_group_id integer NOT NULL to connection_groups.
#
# owner_group_id is a per-owner numbering key for connection groups.
# It is separate from the system id and lets each owner assign their own
# sequential group numbers. The unique index (owner_id, owner_group_id)
# enforces uniqueness within each owner's set of groups.
#
# SQLite cannot add a NOT NULL column to an existing table via ALTER TABLE,
# so full table recreation is required (see RAILS_SPECIFICS.md).
#
# disable_ddl_transaction! is required because PRAGMA foreign_keys = OFF/ON
# is a no-op inside a transaction.
#
# Existing rows: owner_group_id is initialised to the row's system id.
# This satisfies NOT NULL and the per-owner unique index (system ids are
# globally unique, so they are certainly unique per owner). Owners can
# renumber their groups after migration.
#
# The connection_members table has an FK pointing to connection_groups.
# With PRAGMA foreign_keys = OFF the rename-and-recreate steps are safe
# because FK references are name-based in SQLite, not pointer-based.

class AddOwnerGroupIdToConnectionGroups < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Explicit column list — never use SELECT * in SQLite table recreation
  # (see RAILS_SPECIFICS.md — SQLite Table Recreation rule).
  COLUMNS = %w[id owner_id connection_type_id label created_at updated_at].freeze

  def up
    execute "PRAGMA foreign_keys = OFF"

    # Create new table with owner_group_id column.
    execute <<~SQL
      CREATE TABLE connection_groups_new (
        id                 INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
        owner_id           INTEGER  NOT NULL
                             REFERENCES owners(id),
        connection_type_id INTEGER
                             REFERENCES connection_types(id),
        label              VARCHAR(100),
        owner_group_id     INTEGER  NOT NULL DEFAULT 0,
        created_at         DATETIME,
        updated_at         DATETIME
      )
    SQL

    # Copy existing rows; seed owner_group_id from the system id.
    # Explicit column names on both sides — immune to storage-order differences.
    execute <<~SQL
      INSERT INTO connection_groups_new
             (id, owner_id, connection_type_id, label, owner_group_id, created_at, updated_at)
      SELECT  id, owner_id, connection_type_id, label, id,            created_at, updated_at
      FROM    connection_groups
    SQL

    execute "DROP TABLE connection_groups"
    execute "ALTER TABLE connection_groups_new RENAME TO connection_groups"

    # Restore standard single-column indexes (were created by original migration).
    add_index :connection_groups, :owner_id,
              name: "index_connection_groups_on_owner_id"
    add_index :connection_groups, :connection_type_id,
              name: "index_connection_groups_on_connection_type_id"

    # New: unique index enforcing one owner_group_id value per owner.
    add_index :connection_groups, %i[owner_id owner_group_id],
              unique: true,
              name:   "index_connection_groups_on_owner_and_ownergroup"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"

    # Recreate without owner_group_id.
    execute <<~SQL
      CREATE TABLE connection_groups_old (
        id                 INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
        owner_id           INTEGER  NOT NULL REFERENCES owners(id),
        connection_type_id INTEGER  REFERENCES connection_types(id),
        label              VARCHAR(100),
        created_at         DATETIME,
        updated_at         DATETIME
      )
    SQL

    execute <<~SQL
      INSERT INTO connection_groups_old
             (id, owner_id, connection_type_id, label, created_at, updated_at)
      SELECT  id, owner_id, connection_type_id, label, created_at, updated_at
      FROM    connection_groups
    SQL

    execute "DROP TABLE connection_groups"
    execute "ALTER TABLE connection_groups_old RENAME TO connection_groups"

    add_index :connection_groups, :owner_id,
              name: "index_connection_groups_on_owner_id"
    add_index :connection_groups, :connection_type_id,
              name: "index_connection_groups_on_connection_type_id"

    execute "PRAGMA foreign_keys = ON"
  end
end
