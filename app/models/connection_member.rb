# decor/app/models/connection_member.rb
# version 1.0
# Session 31: Part 1 — Connections feature foundation.
# Each row records one device's participation in one connection group.
# The after_destroy callback implements the "auto-destroy undersized group"
# requirement: when a Computer is deleted, its ConnectionMember rows are
# destroyed via Computer's dependent: :destroy; if that leaves the group
# with fewer than 2 members, the group is destroyed automatically.
#
# Important: ConnectionGroup uses dependent: :delete_all (not :destroy) when
# deleting its members, so this callback is NOT triggered during group deletion.
# This deliberately breaks the potential recursive loop:
#   group.destroy → delete_all (no callback) → done
#   computer.destroy → member.destroy → callback → group.destroy → delete_all → done

class ConnectionMember < ApplicationRecord
  belongs_to :connection_group
  belongs_to :computer

  validates :computer_id,
            uniqueness: {
              scope: :connection_group_id,
              message: "is already a member of this connection group"
            }

  # After a member is destroyed (only via Computer's dependent: :destroy —
  # group deletion uses delete_all and does not reach this callback),
  # check whether the group still has at least 2 members. Destroy the group
  # if it has fallen below the minimum.
  #
  # Uses find_by(id:) rather than self.connection_group to re-query the DB
  # for the actual post-deletion state, guarding against the case where
  # the group was already destroyed by a concurrent member's after_destroy
  # (e.g. owner deletion destroying multiple computers in sequence).
  after_destroy :cleanup_undersized_group

  private

  def cleanup_undersized_group
    # Re-fetch the group from DB — it may already be gone if a sibling
    # member's after_destroy destroyed it first (e.g. during owner deletion).
    group = ConnectionGroup.find_by(id: connection_group_id)
    return unless group

    # If fewer than 2 members remain, the group is no longer a valid connection.
    # Destroy the group; this triggers delete_all on any remaining member rows.
    group.destroy if group.connection_members.count < 2
  end
end
