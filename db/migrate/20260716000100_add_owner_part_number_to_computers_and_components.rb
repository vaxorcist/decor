# decor/db/migrate/20260716000100_add_owner_part_number_to_computers_and_components.rb
# version 1.0
# Session 70: Owner Part Number feature — Migration 1 of 2 (data-cleaning step).
#
# Per PROGRAMMING_GENERAL.md "Check Production Data Before Adding Constraints"
# (3-Step Safe Process), constraints are added in a SEPARATE migration
# (20260716000200) that runs AFTER this one has cleaned the data. This
# migration only adds the new nullable columns and backfills values — it does
# NOT add NOT NULL or the new unique indexes yet.
#
# Confirmed design (Ulli, Session 69/70):
#   - New VARCHAR(20) owner_part_number column on both computers and components,
#     defaulting to "-" going forward (enforced at the model level via
#     before_validation — see computer.rb / component.rb).
#   - components.serial_number (currently allow_blank: true) also becomes
#     NOT NULL, defaulting to "-" — same treatment as owner_part_number.
#   - computers.serial_number was already NOT NULL/presence-validated; no
#     computer row can be blank, so no serial_number backfill is needed there.
#   - New combined uniqueness: (owner, model/type, owner_part_number,
#     serial_number) for both tables — keeps the existing model/type scope
#     dimension from migration 20260316120000 / 20260316110000.
#
# Spares collision (the real reason this needs a two-step migration):
#   Component intentionally allows multiple unserialized spares of the same
#   component_type for the same owner (Session 28 design — see component.rb
#   history). If both new/backfilled columns were uniformly set to "-" for
#   every component, every such group of spares would collide on the new
#   4-column uniqueness constraint the moment migration 2 tries to add it.
#   Fix (confirmed placeholder format: "SPARE-#{component.id}"): BEFORE the
#   blanket "-" backfill, find every (owner_id, component_type_id) group that
#   has 2+ components with a blank/dash serial_number, and give EVERY member
#   of that group a distinct id-based owner_part_number instead of leaving
#   any of them "-". component.id is already globally unique, so this cannot
#   collide with anything, and needs no per-group counter.
#
#   Going forward this session chose Option B (no auto-assign): once the
#   constraint is live, a second unserialized spare of the same type for the
#   same owner will be REJECTED at save time unless the user supplies a real
#   Owner Part Number or DEC Serial Number themselves. This migration only
#   fixes the one-time backfill of EXISTING data — it does not change future
#   save behaviour (that's the model validation added in migration 2 /
#   computer.rb / component.rb).
#
# Order of operations in this migration matters:
#   1. Add both columns (nullable — NOT NULL comes in migration 2).
#   2. Backfill blank/nil components.serial_number to "-" FIRST, so the
#      collision-detection query in step 3 can group on its final value.
#   3. Detect (owner_id, component_type_id) groups with 2+ dash-serial
#      components; assign each member of a colliding group a unique
#      "SPARE-#{id}" owner_part_number.
#   4. Blanket-backfill owner_part_number to "-" for every component NOT
#      touched by step 3, and for every computer (no collision risk there —
#      Computer#serial_number is already unique per (owner, computer_model),
#      so uniformly defaulting owner_part_number to "-" cannot create a new
#      collision on the computers table).
#
# add_column is a safe, non-recreating operation in SQLite — only migration 2
# (which adds NOT NULL and rebuilds the unique indexes) requires the full
# table-recreation pattern from RAILS_SPECIFICS.md.

class AddOwnerPartNumberToComputersAndComponents < ActiveRecord::Migration[8.1]
  def up
    add_column :computers,  :owner_part_number, :string, limit: 20
    add_column :components, :owner_part_number, :string, limit: 20

    # Step 2: backfill blank/nil component serial numbers to "-" first.
    # Computer#serial_number is already NOT NULL/presence-validated — no
    # computer row can be blank, so no equivalent backfill is needed there.
    execute <<~SQL
      UPDATE components SET serial_number = '-' WHERE serial_number IS NULL OR TRIM(serial_number) = ''
    SQL

    # Step 3: resolve spares collisions BEFORE the blanket owner_part_number
    # backfill below. Uses the Component AR model directly (find_each +
    # update_column) — same pattern PROGRAMMING_GENERAL.md documents under
    # "Check Production Data Before Adding Constraints" for data-cleaning
    # migrations. update_column skips validations/callbacks deliberately:
    # the model's presence/uniqueness validations for these two columns
    # don't exist yet at this point in the migration sequence.
    colliding_groups = Component
      .where(serial_number: "-")
      .group(:owner_id, :component_type_id)
      .having("COUNT(*) > 1")
      .count
      .keys # => [[owner_id, component_type_id], ...] for every colliding group

    colliding_groups.each do |owner_id, component_type_id|
      Component
        .where(owner_id: owner_id, component_type_id: component_type_id, serial_number: "-")
        .find_each do |component|
          component.update_column(:owner_part_number, "SPARE-#{component.id}")
        end
    end

    # Step 4: blanket-backfill everything not touched by step 3.
    execute "UPDATE components SET owner_part_number = '-' WHERE owner_part_number IS NULL"
    execute "UPDATE computers  SET owner_part_number = '-' WHERE owner_part_number IS NULL"
  end

  def down
    remove_column :components, :owner_part_number
    remove_column :computers,  :owner_part_number
  end
end
