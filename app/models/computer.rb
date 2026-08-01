# decor/app/models/computer.rb
# version 2.4
# v2.4 (Session C, Storage Locations feature, Part 3 of 6 — see
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan"): Added
#   belongs_to :storage_location, optional: true. New nullable
#   storage_location_id column (migration 20260803000100). Optional because
#   an owner is never required to assign a location to every device — the
#   dropdown on the form (_form.html.erb, this session) includes a blank
#   "No location assigned" option. When a StorageLocation is destroyed,
#   storage_location_id here is nullified automatically (StorageLocation
#   has_many :computers, dependent: :nullify — storage_location.rb v1.1),
#   not this model's own behaviour.
# v2.3 (Session 74): History-length limit feature. history was an
#   unqualified TEXT column (unbounded) — a violation of
#   PROGRAMMING_GENERAL.md's VARCHAR-length rule that had gone unnoticed.
#   Migration 20260721000100 converts the DB column to VARCHAR(500) with a
#   CHECK constraint (defense-in-depth per PROGRAMMING_GENERAL.md); this
#   validation is the matching model-level half of that pair, giving a
#   friendly validation error instead of a raw SQL exception if it's ever
#   exceeded (e.g. via CSV import, which bypasses the form's maxlength).
# v2.2 (Session 70): Owner Part Number feature — IMPLEMENTED.
#   New owner_part_number VARCHAR(20) column (migration 20260716000100).
#   Confirmed design (Ulli):
#     - owner_part_number defaults to "-" when blank (data-entry convenience —
#       the user is never forced to type a value). Implemented via
#       before_validation, NOT before_save — see RAILS_SPECIFICS.md
#       "before_validation vs before_save": a before_save callback would run
#       AFTER the presence validation and the blank value would be rejected
#       first.
#     - serial_number ALSO now defaults to "-" when blank (was previously a
#       hard validation error requiring the user to invent a value — this is
#       a genuine behaviour change, confirmed by Ulli). presence: true is
#       unchanged; the default callback runs before it so a blank input never
#       actually reaches the validator as blank.
#     - Uniqueness scope widened from (owner_id, computer_model_id) to
#       (owner_id, computer_model_id, owner_part_number) — the serial_number
#       uniqueness check now effectively covers all four columns together.
#       Confirmed: the existing computer_model_id dimension is KEPT (not
#       dropped in favour of a plain per-owner scope).
#   Matches the DB unique index added in migration 20260716000200
#   (index_computers_on_owner_model_opn_and_serial_number).
# v2.1 (Session 43): Added has_many :software_items, dependent: :destroy.
#   Deleting a computer destroys all software installed on it (design decision).
#   The DB FK also carries ON DELETE CASCADE as defense-in-depth (mirrors the
#   components → computers FK pattern). Positioned after has_many :components.
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

  # Storage Locations feature, Session C. Optional — an owner is never
  # required to assign a physical location to a device. Private data: never
  # displayed to anyone but the owning owner/admin — see computers/show.html.erb
  # and computers/index.html.erb / _computer.html.erb for the "own-view only"
  # display guards added this session.
  belongs_to :storage_location, optional: true

  has_many :components, dependent: :destroy

  # Software items installed on this computer or peripheral.
  # dependent: :destroy — deleting a hardware item destroys all software
  # installed on it (user decision, Session 43). The DB FK mirrors this with
  # ON DELETE CASCADE as a safety net for direct DB operations.
  # Note: peripherals (device_type=2) live in this same table, so this
  # association covers software installed on peripherals too.
  has_many :software_items, dependent: :destroy

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

  # Default owner_part_number and serial_number to "-" when left blank.
  # MUST be before_validation, not before_save — see RAILS_SPECIFICS.md
  # "before_validation vs before_save": presence validations below run
  # BEFORE before_save callbacks, so a before_save default would see the
  # blank value rejected first. before_validation runs first, so the
  # presence check below always sees a filled-in value.
  before_validation :default_owner_part_number
  before_validation :default_serial_number

  # Validations
  validates :serial_number, presence: true
  validates :owner_part_number, presence: true, length: { maximum: 20 }

  # serial_number uniqueness: one owner cannot have two devices of the same
  # model with the same Owner Part Number AND the same DEC Serial Number
  # combination. Different models owned by the same owner may repeat a
  # serial/owner-part-number combination (e.g. a VT220 "unknown"/"-" and a
  # VT320 "unknown"/"-" are distinct physical devices). This mirrors the DB
  # unique index on (owner_id, computer_model_id, owner_part_number,
  # serial_number).
  #
  # Widened Session 70 (Owner Part Number feature) from a 2-column scope
  # (owner_id, computer_model_id) to this 3-column scope — combined with the
  # validated serial_number attribute itself, the full uniqueness check now
  # covers all four columns.
  validates :serial_number,
            uniqueness: { scope: [:owner_id, :computer_model_id, :owner_part_number],
                          message: "combination already exists for this model and Owner Part Number" }

  validates :order_number, length: { maximum: 20 }, allow_blank: true

  # History-length limit — Session 74. Matches the DB CHECK constraint added
  # by migration 20260721000100 (VARCHAR(500)). allow_blank: true — history
  # is optional; this only bounds it when present.
  validates :history, length: { maximum: 500 }, allow_blank: true

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

  private

  # Owner Part Number — data-entry convenience. The user is never forced to
  # invent a value; leaving the field blank stores "-" instead. Editable
  # afterward like any other field.
  def default_owner_part_number
    self.owner_part_number = "-" if owner_part_number.blank?
  end

  # DEC Serial Number — same convenience, confirmed Session 70. Previously
  # a blank serial_number was a hard validation error; it now silently
  # becomes "-" instead.
  def default_serial_number
    self.serial_number = "-" if serial_number.blank?
  end
end
