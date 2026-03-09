# decor/db/migrate/20260309100001_add_barter_status_to_components.rb
# version 1.0
# Adds barter_status integer column to the components table.
#
# Values (mirrors Component enum):
#   0 = no_barter  — not available for trade (default)
#   1 = offered    — owner is offering this item for trade
#   2 = wanted     — owner is looking for this item (may not be in collection)
#
# DEFAULT 0 NOT NULL: every existing row receives 0 (no_barter) automatically;
# no data migration needed.
#
# See 20260309100000_add_barter_status_to_computers.rb for design rationale
# on why a plain add_column is sufficient (no table recreation needed).

class AddBarterStatusToComponents < ActiveRecord::Migration[8.1]
  def change
    # null: false with a default — every existing row receives 0 automatically.
    add_column :components, :barter_status, :integer, default: 0, null: false

    # Index supports fast filter queries on barter_status.
    add_index :components, :barter_status
  end
end
