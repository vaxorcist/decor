# decor/db/migrate/20260303110000_add_device_type_to_computer_models.rb
# version 1.0
# Adds device_type integer column to computer_models so that models can be
# classified as either computer models (0) or appliance models (1).
# Mirrors the device_type enum already present on the computers table.
# All existing rows default to 0 (computer) — no data migration needed.

class AddDeviceTypeToComputerModels < ActiveRecord::Migration[8.1]
  def change
    # null: false with default: 0 means existing rows are silently backfilled
    # to 0 (computer) by SQLite during the ALTER TABLE.
    add_column :computer_models, :device_type, :integer, null: false, default: 0
    add_index  :computer_models, :device_type
  end
end
