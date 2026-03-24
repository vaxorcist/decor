# decor/db/migrate/20260323010000_add_owner_member_id_and_label_to_connection_members.rb
# version 1.0
# Session 38: Adds owner_member_id integer NOT NULL and label VARCHAR(100)
# to connection_members.
#
# owner_member_id is a per-group port numbering key. It is separate from the
# system id and lets each owner assign sequential port numbers within a group.
# A new unique index (connection_group_id, owner_member_id) enforces uniqueness
# within each group.
#
# label VARCHAR(100): optional free-text port label (e.g. "DSSI Node 6",
# "Session 1"). nullable — most ports will have no label.
#
# The existing unique index on (connection_group_id, computer_id) is preserved
# intact — it enforces the one-computer-per-group rule and is orthogonal to the
# new (connection_group_id, owner_member_id) index.
#
# Existing rows: owner_member_id is initialised to the row's system id.
# See migration 20260323000000 header for the reasoning (same approach).
#
# disable_ddl_transaction! required — PRAGMA foreign_keys is a no-op in a transaction.

class AddOwnerMemberIdAndLabelToConnectionMembers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE connection_members_new (
        id                  INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
        connection_group_id INTEGER  NOT NULL
                              REFERENCES connection_groups(id) ON DELETE CASCADE,
        computer_id         INTEGER  NOT NULL
                              REFERENCES computers(id),
        owner_member_id     INTEGER  NOT NULL DEFAULT 0,
        label               VARCHAR(100),
        created_at          DATETIME,
        updated_at          DATETIME
      )
    SQL

    # Copy existing rows; seed owner_member_id from the system id; label is NULL.
    execute <<~SQL
      INSERT INTO connection_members_new
             (id, connection_group_id, computer_id, owner_member_id, label, created_at, updated_at)
      SELECT  id, connection_group_id, computer_id, id,              NULL,  created_at, updated_at
      FROM    connection_members
    SQL

    execute "DROP TABLE connection_members"
    execute "ALTER TABLE connection_members_new RENAME TO connection_members"

    # Restore the original composite unique index (one computer per group).
    add_index :connection_members, %i[connection_group_id computer_id],
              unique: true,
              name:   "index_connection_members_on_group_and_computer"

    # Restore the single-column computer_id index (serves "groups a computer belongs to" queries).
    add_index :connection_members, :computer_id,
              name: "index_connection_members_on_computer_id"

    # New: unique index enforcing one owner_member_id per group.
    add_index :connection_members, %i[connection_group_id owner_member_id],
              unique: true,
              name:   "index_connection_members_on_group_and_ownermember"

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    execute "PRAGMA foreign_keys = OFF"

    execute <<~SQL
      CREATE TABLE connection_members_old (
        id                  INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
        connection_group_id INTEGER  NOT NULL
                              REFERENCES connection_groups(id) ON DELETE CASCADE,
        computer_id         INTEGER  NOT NULL
                              REFERENCES computers(id),
        created_at          DATETIME,
        updated_at          DATETIME
      )
    SQL

    execute <<~SQL
      INSERT INTO connection_members_old
             (id, connection_group_id, computer_id, created_at, updated_at)
      SELECT  id, connection_group_id, computer_id, created_at, updated_at
      FROM    connection_members
    SQL

    execute "DROP TABLE connection_members"
    execute "ALTER TABLE connection_members_old RENAME TO connection_members"

    add_index :connection_members, %i[connection_group_id computer_id],
              unique: true,
              name:   "index_connection_members_on_group_and_computer"

    add_index :connection_members, :computer_id,
              name: "index_connection_members_on_computer_id"

    execute "PRAGMA foreign_keys = ON"
  end
end
