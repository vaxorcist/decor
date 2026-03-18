# decor/db/migrate/20260319020000_create_connection_members.rb
# version 1.0
# Session 31: Part 1 — Connections feature foundation.
# Creates the connection_members join table. Each row records one device's
# participation in one connection group. A group with N connected devices has
# N rows here.
#
# Design decisions:
#   - connection_group_id FK: on_delete: :cascade at DB level. When a group is
#     deleted (either explicitly by the owner or automatically when falling below
#     2 members), its member rows are removed immediately. This is defense-in-depth
#     alongside Rails dependent: :delete_all on ConnectionGroup.
#   - computer_id FK: no on_delete. Computer deletion is handled by Rails via
#     Computer has_many :connection_members, dependent: :destroy — this fires the
#     after_destroy callback on ConnectionMember that checks whether the now-
#     undersized group should be automatically destroyed. A DB-level cascade would
#     bypass that callback and leave orphaned groups.
#   - UNIQUE index on (connection_group_id, computer_id): prevents a device from
#     being added to the same group twice. This composite index also efficiently
#     serves "find all members of a group" queries (leftmost column = group id),
#     so the connection_group references column is declared with index: false to
#     avoid a redundant single-column index.
#   - Index on computer_id: serves "find all groups a computer belongs to" queries
#     (added automatically by t.references :computer).

class CreateConnectionMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :connection_members do |t|
      # Connection group this device belongs to.
      # on_delete: :cascade — member rows are removed when the group is destroyed.
      # index: false — the composite unique index below covers group_id lookups.
      t.references :connection_group,
                   null: false,
                   index: false,
                   foreign_key: { on_delete: :cascade }

      # The participating device (computer, appliance, or peripheral — all stored
      # in the computers table via device_type enum).
      # No on_delete: Rails must handle this via dependent: :destroy to allow the
      # after_destroy callback to fire the group-cleanup logic.
      t.references :computer, null: false, foreign_key: true

      t.timestamps precision: nil
    end

    # Composite unique index: one device can appear in a given group at most once.
    # Also serves as the primary index for "find all members of group X" queries.
    add_index :connection_members,
              [:connection_group_id, :computer_id],
              unique: true,
              name: "index_connection_members_on_group_and_computer"
  end
end
