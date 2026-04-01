# decor/app/models/software_item.rb
# version 1.0
# Session 43: Part of the Software feature (Option C — full separation).
#   Represents a software title owned by an owner, optionally installed on
#   a computer or peripheral.
#
#   "Installed on" semantics:
#     computer_id is nullable. A nil computer_id means the software is owned
#     but not currently installed on any hardware item. Peripherals (device_type=2)
#     live in the computers table, so one FK covers both device types.
#
#   Deletion cascade:
#     Owner deleted  → software_item destroyed (Owner has_many, dependent: :destroy).
#     Computer deleted → software_item destroyed (Computer has_many, dependent:
#                        :destroy, plus DB-level ON DELETE CASCADE as defense-in-depth).
#
#   barter_status matches the Computer/Component enum exactly:
#     no_barter: 0 — not available for trade (DB default)
#     offered:   1 — owner is offering this item for trade
#     wanted:    2 — owner is seeking this title; record need not represent
#                    physically owned media (same semantics as Computer/Component).

class SoftwareItem < ApplicationRecord
  belongs_to :owner
  belongs_to :computer,          optional: true
  belongs_to :software_name
  belongs_to :software_condition, optional: true

  # Barter trade status — identical enum definition to Computer and Component.
  # All barter values are only displayed to logged-in members.
  enum :barter_status, { no_barter: 0, offered: 1, wanted: 2 }, prefix: true

  # version: e.g. "V5.5", "V05.05". Optional — not all software has a known
  # version, and version is not a primary identifier.
  validates :version,     length: { maximum: 20  }, allow_blank: true

  # description and history are short free-text fields (VARCHAR in the DB,
  # unlike the TEXT columns on components — explicit lengths per design spec).
  validates :description, length: { maximum: 100 }, allow_blank: true
  validates :history,     length: { maximum: 200 }, allow_blank: true

  # Search scope — searches across software name, owner username, and version.
  # Supports SQL wildcards (% for any characters, _ for single character).
  # Case-insensitive.
  scope :search, ->(query) do
    return all if query.blank?

    pattern = query.include?("%") || query.include?("_") ? query : "%#{query}%"

    joins(:owner, :software_name)
      .where(
        "LOWER(software_names.name) LIKE LOWER(?) OR
         LOWER(owners.user_name)    LIKE LOWER(?) OR
         LOWER(software_items.version) LIKE LOWER(?)",
        pattern, pattern, pattern
      )
      .distinct
  end
end
