# decor/db/migrate/20260309100000_add_barter_status_to_computers.rb
# version 1.0
# Adds barter_status integer column to the computers table.
#
# Values (mirrors Computer enum):
#   0 = no_barter  — not available for trade (default)
#   1 = offered    — owner is offering this item for trade
#   2 = wanted     — owner is looking for this item (may not be in collection)
#
# DEFAULT 0 NOT NULL: every existing row receives 0 (no_barter) automatically;
# no data migration needed.
#
# A plain add_column is sufficient — SQLite allows adding a column with a
# DEFAULT value to an existing table without table recreation.
# Table recreation (disable_ddl_transaction! + raw SQL) is only required when
# adding CHECK constraints or named constraints, which are not needed here
# because the enum validation is enforced at the Rails model layer.

class AddBarterStatusToComputers < ActiveRecord::Migration[8.1]
  def change
    # null: false with a default — every existing row receives 0 automatically.
    add_column :computers, :barter_status, :integer, default: 0, null: false

    # Index supports fast filter queries on barter_status (e.g., WHERE barter_status IN (0,1)).
    add_index :computers, :barter_status
  end
end
