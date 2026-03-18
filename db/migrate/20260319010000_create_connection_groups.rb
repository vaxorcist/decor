# decor/db/migrate/20260319010000_create_connection_groups.rb
# version 1.0
# Session 31: Part 1 — Connections feature foundation.
# Creates the connection_groups table. Each group represents one named connection
# event (e.g. "PDP-8 terminal setup") and belongs to one owner. The actual devices
# participating in the connection are stored in connection_members.
#
# Design decisions:
#   - owner_id: NOT NULL — every group must have an owner. All member devices
#     must belong to the same owner (enforced by model validation).
#   - connection_type_id: nullable — the type of connection is optional. Owners
#     may not always know or care to record whether a cable is RS-232 or Ethernet.
#   - label: nullable VARCHAR(100) — optional free-text name for the connection
#     (e.g. "Lab terminal chain", "Network cluster").
#   - No on_delete on owner FK: Rails handles deletion order via dependent: :destroy
#     on Owner, destroying computers (and their members) before connection_groups.
#   - No on_delete on connection_type FK: deletion of a connection_type that has
#     groups is blocked (restrict_with_error on ConnectionType model).

class CreateConnectionGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :connection_groups do |t|
      # Owner of this connection. All participating devices must belong to this owner.
      t.references :owner, null: false, foreign_key: true

      # Optional connection type (e.g. RS-232 Serial, Ethernet).
      # nullable — owner may leave it unspecified.
      t.references :connection_type, null: true, foreign_key: true

      # Optional descriptive name for this connection group.
      t.string :label, limit: 100

      t.timestamps precision: nil
    end
  end
end
