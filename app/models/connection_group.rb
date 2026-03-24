# decor/app/models/connection_group.rb
# version 1.2
# v1.2 (Session 38): Added owner_group_id.
#   - before_validation :auto_assign_owner_group_id (on: :create) — assigns the
#     next available ID for this owner if the field is left blank.
#   - validates :owner_group_id — presence, integer > 0, unique within owner.
# v1.1 (Session 36): Added reject_if: :all_blank to accepts_nested_attributes_for.
#   Without this, a blank dropdown row fails belongs_to presence validation before
#   the minimum_two_members group-level validator runs, producing a confusing error.
# v1.0 (Session 31): Initial model — associations, nested attributes, two custom validators.

class ConnectionGroup < ApplicationRecord
  # ── Associations ────────────────────────────────────────────────────────────

  belongs_to :owner
  belongs_to :connection_type, optional: true

  # delete_all: no after_destroy callbacks needed when the group itself is the
  # source of deletion. (When a computer is deleted, Ruby destroy fires on each
  # member so that member.after_destroy → group auto-cleanup can run.)
  has_many :connection_members, dependent: :delete_all
  has_many :computers, through: :connection_members

  # ── Nested attributes ────────────────────────────────────────────────────────

  # reject_if: :all_blank — silently discards member rows where every attribute
  # is blank (e.g. an unfilled "Add port" dropdown row). Without this, Rails
  # tries to build a ConnectionMember with no computer_id, failing belongs_to
  # presence validation before minimum_two_members can run.
  accepts_nested_attributes_for :connection_members,
                                 allow_destroy: true,
                                 reject_if:     :all_blank

  # ── Validations ─────────────────────────────────────────────────────────────

  validates :owner_group_id,
            presence:     true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness:   { scope: :owner_id,
                            message: "is already used for another connection of this owner" }

  validates :label, length: { maximum: 100 }, allow_blank: true

  validate :minimum_two_members
  validate :all_members_belong_to_owner
  validate :no_duplicate_computers

  # ── Callbacks ───────────────────────────────────────────────────────────────

  # Auto-assigns owner_group_id on create when the caller leaves it blank.
  # Assigns one higher than the highest value already used by this owner.
  # The before_validation hook runs before uniqueness validation, so the
  # auto-assigned value is available for the validator to check.
  before_validation :auto_assign_owner_group_id, on: :create

  # ── Private methods ──────────────────────────────────────────────────────────

  private

  def auto_assign_owner_group_id
    # Guard: skip only when an explicit positive value has already been set.
    # owner_group_id.present? is NOT sufficient — 0.present? is true in Ruby,
    # so a freshly-built record (DB default = 0) would never get auto-assigned.
    return if owner_group_id.to_i > 0
    return unless owner

    max = owner.connection_groups.maximum(:owner_group_id) || 0
    self.owner_group_id = max + 1
  end

  # A connection must have at least 2 active (not marked for destruction) members.
  def minimum_two_members
    active = connection_members.reject(&:marked_for_destruction?)
    errors.add(:connection_members, "must have at least 2 ports") if active.size < 2
  end

  # All member devices must belong to the same owner as the group.
  # Checked per-member; stops at the first violation.
  def all_members_belong_to_owner
    return unless owner

    connection_members.each do |member|
      next if member.marked_for_destruction?
      next if member.computer_id.blank?

      unless owner.computers.exists?(id: member.computer_id)
        errors.add(:base, "All ports must be devices belonging to this owner")
        break
      end
    end
  end

  # No two active members may reference the same computer.
  # Rails' per-member uniqueness validator only checks against the DB, so it
  # cannot catch two new members with the same computer_id built in memory at
  # the same time. Without this group-level check the DB unique constraint fires
  # and raises ActiveRecord::RecordNotUnique instead of a friendly error.
  def no_duplicate_computers
    active = connection_members.reject(&:marked_for_destruction?)
    ids    = active.map(&:computer_id).compact
    if ids.length != ids.uniq.length
      errors.add(:base, "The same device cannot appear more than once in a connection")
    end
  end
end
