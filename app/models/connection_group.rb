# decor/app/models/connection_group.rb
# version 1.0
# Session 31: Part 1 — Connections feature foundation.
# A ConnectionGroup represents one named connection between two or more devices
# (computers, appliances, or peripherals — all stored in the computers table).
# All participating devices must belong to the same owner as the group.
#
# Key invariants enforced by model validations:
#   1. A group must always have at least 2 member devices.
#   2. Every member device must belong to the same owner as the group.
#
# Cascade behaviour:
#   - When a group is deleted, all its connection_members rows are removed
#     immediately via dependent: :delete_all (no Ruby callbacks fired, direct
#     DB delete). This is intentional — there is no further cleanup to trigger
#     when the group itself is the source of deletion.
#   - When a Computer is deleted, its ConnectionMember rows are destroyed via
#     Computer's dependent: :destroy, which fires after_destroy on each
#     ConnectionMember. That callback checks whether the group has fallen below
#     2 members and, if so, destroys the group (which in turn uses delete_all
#     to clean up any remaining members of that group).
#
# accepts_nested_attributes_for is required for the minimum_two_members
# validation to work correctly: it allows in-memory member records to be
# counted by the validator before any DB writes occur.

class ConnectionGroup < ApplicationRecord
  belongs_to :owner
  belongs_to :connection_type, optional: true

  # delete_all: when a group is deleted, remove all member rows directly at the
  # DB level. No Ruby callbacks needed — there is nothing further to clean up
  # when the group itself is the source of the deletion.
  has_many :connection_members, dependent: :delete_all

  # Convenience association: access participating Computer objects directly.
  has_many :computers, through: :connection_members

  # Enables nested creation/update of members in a single operation, which is
  # required for the minimum_two_members validation to see in-memory records.
  # allow_destroy: true permits removing a member by passing _destroy: true.
  accepts_nested_attributes_for :connection_members, allow_destroy: true

  # Validation 1: a connection must always involve at least 2 devices.
  # Uses reject(&:marked_for_destruction?) so that members being removed in the
  # same operation are not counted toward the minimum.
  validate :minimum_two_members

  # Validation 2: every member device must belong to the same owner as the group.
  # This cross-table constraint cannot be expressed in SQLite and is enforced here.
  validate :all_members_belong_to_owner

  validates :label, length: { maximum: 100 }, allow_blank: true

  private

  # Counts active (not-being-destroyed) members and rejects the save if fewer
  # than 2 would remain after the operation.
  def minimum_two_members
    active = connection_members.reject(&:marked_for_destruction?)
    if active.size < 2
      errors.add(:connection_members, "must include at least 2 devices")
    end
  end

  # Checks that every in-memory or persisted member's computer belongs to the
  # same owner as this group. Skips members being destroyed and members whose
  # computer hasn't been set yet (those are caught by ConnectionMember's own
  # presence validation).
  def all_members_belong_to_owner
    return unless owner_id.present?

    connection_members.each do |member|
      next if member.marked_for_destruction?
      next if member.computer.blank?

      unless member.computer.owner_id == owner_id
        errors.add(:base, "All connected devices must belong to #{owner.user_name}")
      end
    end
  end
end
