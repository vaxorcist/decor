# decor/db/migrate/20260319000000_create_connection_types.rb
# version 1.0
# Session 31: Part 1 — Connections feature foundation.
# Creates the connection_types lookup table, admin-managed like component_types.
# Each ConnectionType names a category of physical or logical connection
# (e.g. "RS-232 Serial", "Ethernet", "UNIBUS") with an optional longer label.

class CreateConnectionTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :connection_types do |t|
      # Short canonical name, e.g. "RS-232 Serial" — displayed in dropdowns.
      # NOT NULL; unique index enforces uniqueness at DB level.
      t.string :name, limit: 40, null: false

      # Optional longer human-readable description of the connection type.
      t.string :label, limit: 100

      t.timestamps precision: nil
    end

    # Unique index on name — prevents duplicate connection type names.
    add_index :connection_types, :name, unique: true
  end
end
