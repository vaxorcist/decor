# decor/db/migrate/20260316120000_add_unique_index_to_computers_serial_number.rb
# version 1.0
# Session 28: Add a unique database index on (owner_id, computer_model_id, serial_number)
# to enforce that no single owner can register two devices of the same model with
# the same serial number.
#
# Design notes:
#   - Scope is (owner, model, serial) — not (owner, serial). The same serial
#     number on different models is valid: a VT220 and a VT320 may both have
#     serial "unknown" for the same owner because they are physically different
#     devices. Only the combination of owner + model + serial must be unique.
#   - owner_id first: matches OwnerImportService query pattern which always
#     scopes by owner first, allowing the index to satisfy that query efficiently.
#   - serial_number is NOT NULL (enforced by presence: true validation and the
#     existing DB NOT NULL constraint), so NULL handling is not a concern here.
#   - add_index requires no table recreation in SQLite — safe to apply to the
#     existing computers table.

class AddUniqueIndexToComputersSerialNumber < ActiveRecord::Migration[8.1]
  def change
    add_index :computers,
              [:owner_id, :computer_model_id, :serial_number],
              unique: true,
              name: "index_computers_on_owner_model_and_serial_number"
  end
end
