# decor/db/migrate/20260511000200_add_order_number_verified_to_components.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Adds order_number_verified boolean to the components table.
#
# Semantics:
#   true  — the order_number was accepted from the component_suggestions typeahead
#            (Phase 2 will set this via a hidden field in the form)
#   false — the order_number was typed freely; not validated against the suggestions
#            table (or no order_number was entered at all)
#
# Default: false — existing rows are safe; new rows typed without using the
# typeahead remain false.
#
# NOT NULL: avoids a three-value boolean; every component has a known verification
# state from the moment it is created.

class AddOrderNumberVerifiedToComponents < ActiveRecord::Migration[8.1]
  def change
    add_column :components, :order_number_verified, :boolean, null: false, default: false
  end
end
