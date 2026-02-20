# decor/db/migrate/20260220093615_rename_description_to_order_number_on_computers.rb - version 1.0
# Renames the 'description' column to 'order_number' on the computers table.
# Step 1: Truncates any existing values exceeding 20 characters (no real user data in production).
# Step 2: Renames the column using SQLite's native RENAME COLUMN (supported since SQLite 3.25).

class RenameDescriptionToOrderNumberOnComputers < ActiveRecord::Migration[8.1]
  def up
    # Truncate existing values that exceed the new 20-character limit.
    # Uses update_all with SQL SUBSTR for efficiency — no Ruby object instantiation needed.
    Computer.where("LENGTH(description) > 20").update_all(
      "description = SUBSTR(description, 1, 20)"
    )

    # Rename the column — supported directly by SQLite 3.25+, no table recreation needed.
    rename_column :computers, :description, :order_number
  end

  def down
    # Reversible: simply rename back. Truncated data cannot be restored.
    rename_column :computers, :order_number, :description
  end
end
