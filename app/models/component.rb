# decor/app/models/component.rb
# version 1.8
# v1.8 (Session 77): Added order_number (DEC Part Number) to the `search`
#   scope's LIKE clause. Reported: the Components filter's Search box gave
#   no indication of which fields it queried, and once clarified (v77
#   _filters.html.erb text), the user asked that DEC Part Number be
#   searchable too — it previously was NOT included (search only covered
#   component type name, owner username, computer/peripheral model name,
#   and description). No column/schema change — order_number already
#   exists on this table; only the scope's WHERE clause and placeholder
#   count changed. See components/_filters.html.erb v1.4 for the matching
#   help-text update.
# v1.7 (Session 74): History-length limit feature. history was an
#   unqualified TEXT column (unbounded) — same violation as computer.rb.
#   Migration 20260721000100 converts the DB column to VARCHAR(500) with a
#   CHECK constraint; this validation is the matching model-level half.
#   Note: no form field currently exposes Component#history at all
#   (components/_form.html.erb only has :description) — this validation
#   guards any programmatic write path (e.g. CSV import) even though the UI
#   doesn't touch it today.
# v1.6 (Session 70): Owner Part Number feature — IMPLEMENTED.
#   New owner_part_number VARCHAR(20) column (migration 20260716000100).
#   Confirmed design (Ulli):
#     - owner_part_number defaults to "-" when blank (data-entry convenience).
#     - serial_number ALSO now defaults to "-" when blank and is NOW REQUIRED
#       (presence: true) — the previous allow_blank: true is REMOVED. This
#       resolves the Computer/Component asymmetry flagged during Session 69
#       design consultation: both models now behave the same way for both
#       fields.
#     - Both default assignments use before_validation, NOT before_save — see
#       RAILS_SPECIFICS.md "before_validation vs before_save": a before_save
#       callback runs AFTER presence validations, so a blank value would be
#       rejected before the default ever had a chance to fill it in.
#     - Uniqueness scope widened from (owner_id, component_type_id) to
#       (owner_id, component_type_id, owner_part_number) — the serial_number
#       uniqueness check now effectively covers all four columns together.
#       Confirmed: the existing component_type_id dimension is KEPT.
#   Matches the DB unique index added in migration 20260716000200
#   (index_components_on_owner_type_opn_and_serial_number).
#
#   IMPORTANT — spares behaviour change (Option B, confirmed Session 70):
#   Session 28 intentionally allowed multiple unserialized spares of the same
#   component_type for the same owner (that's what allow_blank: true was
#   for). Removing allow_blank AND uniformly defaulting both new/changed
#   fields to "-" means: a SECOND spare of the same type for the same owner
#   with no distinguishing Owner Part Number or DEC Serial Number will now be
#   REJECTED by the uniqueness validation below (and by the matching DB
#   index) at save time. Ulli explicitly chose this over auto-assigning a
#   unique placeholder (Option A) — going forward, the user must supply a
#   real distinguishing value themselves for a second such spare. Existing
#   pre-migration collisions were already resolved by a one-time
#   "SPARE-#{id}" backfill in migration 20260716000100 — this is a one-time
#   data fix, not an ongoing mechanism.
# v1.5 (Session 28): Added serial_number uniqueness validation scoped to
#   component_type (mirrors the DB unique index added in migration 20260316110000).
#   allow_blank: true — components without a serial number are not subject to
#   this validation (multiple spare boards of the same type are permitted).
#   The constraint is global (not per-owner): a serial number identifies a specific
#   physical unit; no two owners can claim the same component type + serial number.
#   [Superseded by v1.6 above — allow_blank removed, scope widened.]
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

  # Default owner_part_number and serial_number to "-" when left blank.
  # MUST be before_validation, not before_save — see RAILS_SPECIFICS.md
  # "before_validation vs before_save". Applies to both fields identically.
  before_validation :default_owner_part_number
  before_validation :default_serial_number

  # serial_number is now REQUIRED (Session 70 — allow_blank removed). Every
  # component has a serial_number of at least "-" after the before_validation
  # default above runs.
  validates :serial_number, presence: true, length: { maximum: 20 }
  validates :owner_part_number, presence: true, length: { maximum: 20 }

  # History-length limit — Session 74. Matches the DB CHECK constraint added
  # by migration 20260721000100 (VARCHAR(500)). allow_blank: true — history
  # is optional; this only bounds it when present. No form currently writes
  # to this column, but the validation guards any programmatic write path.
  validates :history, length: { maximum: 500 }, allow_blank: true

  # serial_number uniqueness: one owner cannot have two components of the same
  # type with the same Owner Part Number AND the same DEC Serial Number
  # combination. Different owners may repeat the same type+owner-part-number+
  # serial combination (owners often invent their own numbering schemes, so
  # cross-owner collisions are expected and valid).
  #
  # Widened Session 70 (Owner Part Number feature) from a 2-column scope
  # (owner_id, component_type_id) to this 3-column scope — combined with the
  # validated serial_number attribute itself, the full uniqueness check now
  # covers all four columns. allow_blank REMOVED — see the class-header
  # comment above for the spares behaviour change this causes going forward.
  validates :serial_number,
            uniqueness: { scope: [:owner_id, :component_type_id, :owner_part_number],
                          message: "combination already exists for this component type and Owner Part Number" }

  # Search scope that searches across component type, owner name, computer model,
  # order_number (DEC Part Number), and description.
  # Supports SQL wildcards (% for any characters, _ for single character).
  # Case-insensitive search.
  scope :search, ->(query) do
    return all if query.blank?

    # SQL LIKE pattern — user can include their own wildcards or we wrap the whole thing
    pattern = query.include?("%") || query.include?("_") ? query : "%#{query}%"

    # Search in: component type name, owner username, computer model name,
    # order_number (DEC Part Number — added Session 77), description
    joins(:owner, :component_type)
      .left_outer_joins(computer: :computer_model)
      .where(
        "LOWER(component_types.name) LIKE LOWER(?) OR
         LOWER(owners.user_name) LIKE LOWER(?) OR
         LOWER(computer_models.name) LIKE LOWER(?) OR
         LOWER(components.order_number) LIKE LOWER(?) OR
         LOWER(components.description) LIKE LOWER(?)",
        pattern, pattern, pattern, pattern, pattern
      )
      .distinct
  end

  private

  # Owner Part Number — data-entry convenience. The user is never forced to
  # invent a value; leaving the field blank stores "-" instead.
  def default_owner_part_number
    self.owner_part_number = "-" if owner_part_number.blank?
  end

  # DEC Serial Number — same convenience, confirmed Session 70. Previously
  # a blank serial_number was permitted outright (allow_blank: true); it now
  # silently becomes "-" instead, and the uniqueness check applies to it.
  def default_serial_number
    self.serial_number = "-" if serial_number.blank?
  end
end
