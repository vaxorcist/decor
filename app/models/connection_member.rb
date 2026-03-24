# decor/app/models/connection_member.rb
# version 1.1
# v1.1 (Session 38): Added owner_member_id and label.
#   - before_validation :auto_assign_owner_member_id (on: :create) — assigns the
#     next available port ID within the group if left blank. Handles both the case
#     of new groups (multiple members built simultaneously in memory) and adding a
#     port to an existing group (queries DB for current max).
#   - validates :owner_member_id — presence, integer > 0, unique within group.
#   - validates :label — max 100 characters, optional.
# v1.0 (Session 31): Initial model.

class ConnectionMember < ApplicationRecord
  # ── Associations ────────────────────────────────────────────────────────────

  belongs_to :connection_group
  belongs_to :computer

  # ── Validations ─────────────────────────────────────────────────────────────

  # One computer per group — the primary structural constraint.
  validates :computer_id, uniqueness: { scope:   :connection_group_id,
                                        message: "is already a port in this connection" }

  validates :owner_member_id,
            presence:     true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness:   { scope:   :connection_group_id,
                            message: "is already used in this connection" }

  validates :label, length: { maximum: 100 }, allow_blank: true

  # ── Callbacks ───────────────────────────────────────────────────────────────

  before_validation :auto_assign_owner_member_id, on: :create

  # If destroying this member leaves fewer than 2 in the group, destroy the
  # group too. This fires only when a computer is deleted (has_many
  # :connection_members, dependent: :destroy on Computer), not when the group
  # itself is deleted (dependent: :delete_all skips callbacks).
  after_destroy :cleanup_undersized_group

  # ── Private methods ──────────────────────────────────────────────────────────

  private

  # Auto-assigns owner_member_id on create when left blank.
  # Assigns one higher than the maximum already in use within this group.
  #
  # Two sources are checked:
  #   1. In-memory siblings — handles the case where a new group is being built
  #      with multiple members simultaneously (none persisted yet). Each member's
  #      callback runs sequentially; earlier members have already had their IDs
  #      assigned, so the max of in-memory siblings grows correctly.
  #   2. DB persisted rows — handles adding a new port to an existing group.
  #
  # Taking the max of both ensures correctness in all cases.
  def auto_assign_owner_member_id
    # Guard: skip only when an explicit positive value has already been set.
    # owner_member_id.present? is NOT sufficient — 0.present? is true in Ruby,
    # so a freshly-built record (DB default = 0) would never get auto-assigned.
    return if owner_member_id.to_i > 0
    return unless connection_group

    # In-memory sibling IDs (excludes self to avoid counting our own blank value).
    mem_max = connection_group.connection_members
                               .reject { |m| m.equal?(self) }
                               .filter_map(&:owner_member_id)
                               .max || 0

    # Persisted DB IDs (0 if group is not yet saved).
    db_max = if connection_group.new_record?
               0
    else
               ConnectionMember
                 .where(connection_group_id: connection_group.id)
                 .maximum(:owner_member_id) || 0
    end

    self.owner_member_id = [mem_max, db_max].max + 1
  end

  def cleanup_undersized_group
    group = connection_group
    return unless group
    group.destroy if group.connection_members.count < 2
  end
end
