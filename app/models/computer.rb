# decor/app/models/computer.rb
# version 1.8
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

  # Classifies the item stored in the computers table.
  # computer   — a general-purpose programmable machine
  # appliance  — an autonomous device that operates without a host computer
  #              (routers, switches, terminal servers, printers, etc.)
  # peripheral — a device that attaches to and requires a host computer
  #              (terminals, word-processors, storage controllers, etc.)
  # A CHECK(device_type IN (0,1,2)) constraint enforces valid values at the
  # database level (migration 20260316100000).
  enum :device_type, { computer: 0, appliance: 1, peripheral: 2 }, prefix: true

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
