# decor/app/models/computer.rb
# version 2.0
# v2.0 (Session 41): Appliances → Peripherals merger Phase 1.
#   Removed appliance: 1 from device_type enum. Enum is now hash form
#   { computer: 0, peripheral: 2 } to preserve non-contiguous integer
#   values — peripheral records in the DB carry device_type=2 and must
#   not be renumbered. DB data migration (device_type=1 → 2) was run
#   manually before this session.
# v1.9 (Session 31): Added has_many :connection_members (dependent: :destroy)
#   and has_many :connection_groups (through: :connection_members).
#   dependent: :destroy (not :delete_all) is intentional: Ruby destroy fires
#   after_destroy on each ConnectionMember, which implements the auto-cleanup
#   logic that destroys a ConnectionGroup when it falls below 2 members.
# v1.8 (Session 28): Added serial_number uniqueness validation scoped to
#   (owner_id, computer_model_id). This mirrors the DB unique index added in
#   migration 20260316120000. Scope rationale: the same serial "unknown" on a
#   VT220 and a VT320 belonging to the same owner is valid because they are
#   physically different devices (different model). Only owner + model + serial
#   together must be unique.
# v1.7 (Session 25): Added peripheral: 2 to device_type enum.
# v1.6 (Session 21): Added barter_status enum.
# v1.5 (Session 13): Added device_type enum (computer: 0, appliance: 1).

class Computer < ApplicationRecord
  belongs_to :owner
  belongs_to :computer_model
  belongs_to :computer_condition, optional: true
  belongs_to :run_status, optional: true
  has_many :components, dependent: :destroy

  # Connections: a computer or peripheral may participate in one or more
  # connection groups. Each group records which devices are physically or
  # logically connected to each other.
  #
  # dependent: :destroy — must use Ruby destroy (not delete_all) so that
  # ConnectionMember's after_destroy callback fires and can auto-destroy any
  # ConnectionGroup that falls below the 2-member minimum.
  has_many :connection_members, dependent: :destroy
  has_many :connection_groups, through: :connection_members

  # Classifies the item stored in the computers table.
  # computer   — a general-purpose programmable machine
  # peripheral — a device that attaches to and requires a host computer
  #              (terminals, word-processors, storage controllers, routers, etc.)
  #
  # Hash form is required because value 1 (formerly appliance) was removed in
  # Session 41, leaving a gap in the sequence. Rails needs the explicit mapping
  # { computer: 0, peripheral: 2 } to preserve the DB integer values.
  # Do NOT renumber peripheral to 1 — that would corrupt all existing DB records.
  #
  # A CHECK(device_type IN (0,1,2)) constraint exists at the DB level
  # (migration 20260316100000). Value 1 is no longer used by the application
  # but the constraint is harmless and does not need updating.
  enum :device_type, { computer: 0, peripheral: 2 }, prefix: true

  # Barter trade status for this item.
  # no_barter — not available for trade (the default for all records)
  # offered   — owner is offering this item for trade
  # wanted    — owner is looking for this item; the record need not represent a
  #             physically owned machine (special status per design spec)
  # All barter values are only displayed to logged-in members.
  enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true

  # Validations
  validates :serial_number, presence: true

  # serial_number uniqueness: one owner cannot have two devices of the same model
  # with the same serial number. Different models owned by the same owner may share
  # a serial (e.g. a VT220 "unknown" and a VT320 "unknown" are distinct physical
  # devices). This mirrors the DB unique index on (owner_id, computer_model_id,
  # serial_number).
  validates :serial_number,
            uniqueness: { scope: [:owner_id, :computer_model_id],
                          message: "has already been taken for this model" }

  validates :order_number, length: { maximum: 20 }, allow_blank: true

  # Search scope that searches across model name, owner name, serial number,
  # order_number, history, condition, and run status.
  # Supports SQL wildcards (% for any characters, _ for single character).
  # Case-insensitive search.
  scope :search, ->(query) do
    return all if query.blank?

    # SQL LIKE pattern — user can include their own wildcards or we wrap the whole thing
    pattern = query.include?("%") || query.include?("_") ? query : "%#{query}%"

    # Search in: computer model name, owner username, serial number,
    # order_number, history, condition name, run status name
    joins(:owner, :computer_model)
      .left_outer_joins(:computer_condition, :run_status)
      .where(
        "LOWER(computer_models.name) LIKE LOWER(?) OR
         LOWER(owners.user_name) LIKE LOWER(?) OR
         LOWER(computers.serial_number) LIKE LOWER(?) OR
         LOWER(computers.order_number) LIKE LOWER(?) OR
         LOWER(computers.history) LIKE LOWER(?) OR
         LOWER(computer_conditions.name) LIKE LOWER(?) OR
         LOWER(run_statuses.name) LIKE LOWER(?)",
        pattern, pattern, pattern, pattern, pattern, pattern, pattern
      )
      .distinct
  end
end
