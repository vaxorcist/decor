# decor/app/models/computer.rb
# version 1.6
# v1.6 (Session 21): Added barter_status enum.
#   0 = no_barter (default) — not available for trade
#   1 = offered             — owner is offering this item for trade
#   2 = wanted              — owner is looking for this item (need not be in collection)
#   Prefix: barter_status_ → predicates: barter_status_no_barter?, barter_status_offered?, barter_status_wanted?
#   Visibility: barter_status values are only shown to logged-in members (enforced in
#   controllers and views, not at the model layer).
# v1.5 (Session 13): Added device_type enum (computer: 0, appliance: 1).

class Computer < ApplicationRecord
  belongs_to :owner
  belongs_to :computer_model
  belongs_to :computer_condition, optional: true
  belongs_to :run_status, optional: true
  has_many :components, dependent: :destroy

  # Distinguishes general-purpose computers from autonomous "appliance"
  # devices (routers, switches, terminal servers, printers, etc.) that
  # operate independently without a host computer.
  # "appliance" is a working placeholder; the UI label will be finalised later.
  enum :device_type, { computer: 0, appliance: 1 }, prefix: true

  # Barter trade status for this item.
  # no_barter — not available for trade (the default for all records)
  # offered   — owner is offering this item for trade
  # wanted    — owner is looking for this item; the record need not represent a
  #             physically owned machine (special status per design spec)
  # All barter values are only displayed to logged-in members.
  enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true

  # Validations
  validates :serial_number, presence: true
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
