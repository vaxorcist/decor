# decor/db/migrate/20260303100000_add_device_type_to_computers.rb
# version 1.0
#
# Adds device_type integer column to the computers table.
#
# Purpose:
#   Allows the computers table to store both traditional computers and
#   "appliances" — autonomous devices (routers, switches, terminal servers,
#   printers, etc.) that operate independently without a host computer.
#
# Enum mapping (defined in app/models/computer.rb):
#   0 = computer   (default — all existing rows are computers)
#   1 = appliance  (placeholder name until final UI label is decided)
#
# All existing rows default to 0 (computer) — no data migration needed.

class AddDeviceTypeToComputers < ActiveRecord::Migration[8.1]
  def change
    # Add device_type as a non-null integer with default 0 (computer).
    # The null: false + default: 0 combination means:
    #   - Existing rows all get 0 (computer) immediately.
    #   - New rows without an explicit device_type also get 0.
    add_column :computers, :device_type, :integer, null: false, default: 0

    # Index for filtering by device_type (e.g. list only appliances, or
    # order computers before appliances on the index page).
    add_index :computers, :device_type
  end
end
