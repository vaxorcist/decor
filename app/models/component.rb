# decor/app/models/component.rb
# version 1.5
# v1.5 (Session 28): Added serial_number uniqueness validation scoped to
#   component_type (mirrors the DB unique index added in migration 20260316110000).
#   allow_blank: true — components without a serial number are not subject to
#   this validation (multiple spare boards of the same type are permitted).
#   The constraint is global (not per-owner): a serial number identifies a specific
#   physical unit; no two owners can claim the same component type + serial number.
# v1.4 (Session 21): Added barter_status enum.
# v1.3 (Session 13): Added component_category enum (integral: 0, peripheral: 1).

class Component < ApplicationRecord
  belongs_to :owner
  belongs_to :computer, optional: true
  belongs_to :component_type
  belongs_to :component_condition, optional: true

  # Distinguishes between components that live physically inside a device
  # (integral) and those that connect externally (peripheral).
  #
  # integral  — installable, physically inside a device
  #             (boards, RAM, CPUs, expansion cards, etc.)
  # peripheral — connectable, attached to but not inside a device
  #             (terminals, external drives, keyboards, monitors, etc.)
  #
  # "Spare" is orthogonal to category: a component with computer_id IS NULL
  # is a spare. A spare board is an integral spare; a spare VT100 is a
  # peripheral spare. Both states are represented by category + presence of
  # computer_id together.
  enum :component_category, { integral: 0, peripheral: 1 }, prefix: true

  # Barter trade status for this item.
  # no_barter — not available for trade (the default for all records)
  # offered   — owner is offering this item for trade
  # wanted    — owner is looking for this item; the record need not represent a
  #             physically owned component (special status per design spec)
  # All barter values are only displayed to logged-in members.
  enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true

  # serial_number uniqueness: one owner cannot have two components of the same
  # type with the same serial number. Different owners may share the same
  # type+serial combination (owners often invent their own replacement numbering
  # schemes, so cross-owner collisions are expected and valid).
  # This validation mirrors the DB unique index on (owner_id, component_type_id,
  # serial_number). allow_blank skips the check when serial_number is nil or
  # empty — multiple unserialised spares belonging to the same owner and type
  # are permitted.
  validates :serial_number,
            uniqueness: { scope: [:owner_id, :component_type_id],
                          message: "has already been taken for this component type" },
            allow_blank: true

  # Search scope that searches across component type, owner name, computer model,
  # and description.
  # Supports SQL wildcards (% for any characters, _ for single character).
  # Case-insensitive search.
  scope :search, ->(query) do
    return all if query.blank?

    # SQL LIKE pattern — user can include their own wildcards or we wrap the whole thing
    pattern = query.include?("%") || query.include?("_") ? query : "%#{query}%"

    # Search in: component type name, owner username, computer model name, description
    joins(:owner, :component_type)
      .left_outer_joins(computer: :computer_model)
      .where(
        "LOWER(component_types.name) LIKE LOWER(?) OR
         LOWER(owners.user_name) LIKE LOWER(?) OR
         LOWER(computer_models.name) LIKE LOWER(?) OR
         LOWER(components.description) LIKE LOWER(?)",
        pattern, pattern, pattern, pattern
      )
      .distinct
  end
end
