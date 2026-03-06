# decor/db/migrate/20260303100001_add_component_category_to_components.rb
# version 1.0
#
# Adds component_category integer column to the components table.
#
# Purpose:
#   Distinguishes between components that are physically inside a device
#   (integral) and those that connect externally (peripheral, e.g. a VT100
#   terminal, external drive, keyboard).
#
#   "Spare" status remains implicit: a component with computer_id IS NULL
#   is a spare, regardless of its category. A spare can be either integral
#   (an unattached board waiting to be installed) or peripheral (an
#   unattached terminal waiting to be connected).
#
# Enum mapping (defined in app/models/component.rb):
#   0 = integral    (default — installable, physically inside a device)
#   1 = peripheral  (connectable — attached to but not inside a device)
#
# All existing rows default to 0 (integral) — the large majority of
# components in the database are internal boards, cards, and RAM modules.
# Users can correct any peripheral records after the migration.

class AddComponentCategoryToComponents < ActiveRecord::Migration[8.1]
  def change
    # Add component_category as a non-null integer with default 0 (integral).
    # Existing rows all get 0; new rows without an explicit category also get 0.
    add_column :components, :component_category, :integer, null: false, default: 0

    # Index for filtering by category (e.g. list only peripherals for a device).
    add_index :components, :component_category
  end
end
