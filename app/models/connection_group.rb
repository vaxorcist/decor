# decor/app/models/connection_group.rb
# version 1.1
# v1.1 (Session 36): Added reject_if: :all_blank to accepts_nested_attributes_for.
#   Without this, an "Add member" row left blank by the user (computer_id absent)
#   would attempt to build a ConnectionMember with no computer_id, failing
#   belongs_to :computer presence validation. reject_if: :all_blank silently
#   discards any nested-attributes hash where all values are blank — standard
#   Rails idiom for optional nested rows. Zero behaviour change for valid rows.
# v1.0 (Session 31): Part 1 — Connections feature foundation.

class ConnectionGroup < ApplicationRecord
  belongs_to :owner
  belongs_to :connection_type, optional: true

  # delete_all: when a group is deleted, remove all member rows directly at the
  # DB level. No Ruby callbacks needed — there is nothing further to clean up
  # when the group itself is the source of the deletion.
  has_many :connection_members, dependent: :delete_all

  # Convenience association: access participating Computer objects directly.
  has_many :computers, through: :connection_members

  # reject_if: :all_blank — discard nested-attributes hashes where every value
  # is blank (e.g. a blank dropdown row the user added but did not fill in).
  # allow_destroy: true — permits removing an existing member by passing
  # _destroy: "1" in the nested attributes hash.
  accepts_nested_attributes_for :connection_members,
                                 allow_destroy: true,
                                 reject_if:     :all_blank

  # Validation 1: a connection must always involve at least 2 devices.
  validate :minimum_two_members

  # Validation 2: every member device must belong to the same owner as the group.
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
