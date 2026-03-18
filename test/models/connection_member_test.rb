# decor/test/models/connection_member_test.rb
# version 1.0
# Session 32 (Part 1b): Model tests for ConnectionMember.
#
# Coverage:
#   - computer_id uniqueness scoped to connection_group_id
#     (same computer in same group → invalid; same computer in different group → valid)
#   - belongs_to :connection_group, :computer associations
#   - after_destroy :cleanup_undersized_group:
#     (a) 2-member group loses 1 member → count drops to 1 → group auto-destroys
#     (b) 3-member group loses 1 member → count stays at 2 → group survives
#
# Fixtures:
#   connection_members(:bob_pdp8_member)  — computer: bob_pdp8, group: bob_pdp8_vt100
#   connection_members(:bob_vt100_member) — computer: bob_vt100, group: bob_pdp8_vt100
#   connection_members(:alice_pdp11_member) — computer: alice_pdp11, group: alice_pdp11_vax
#   connection_members(:alice_vax_member)   — computer: alice_vax, group: alice_pdp11_vax
#
# Both fixture groups have exactly 2 members, making them ideal for testing
# the auto-destroy boundary. The 3-member test creates its own group inline
# using alice's three computers (alice_pdp11, alice_vax, unassigned_condition_test).

require "test_helper"

class ConnectionMemberTest < ActiveSupport::TestCase
  # -------------------------------------------------------------------------
  # Associations
  # -------------------------------------------------------------------------

  test "belongs to connection_group" do
    member = connection_members(:bob_pdp8_member)
    assert_respond_to member, :connection_group
    assert_equal connection_groups(:bob_pdp8_vt100), member.connection_group
  end

  test "belongs to computer" do
    member = connection_members(:bob_pdp8_member)
    assert_respond_to member, :computer
    assert_equal computers(:bob_pdp8), member.computer
  end

  # -------------------------------------------------------------------------
  # Uniqueness: computer_id scoped to connection_group_id
  # -------------------------------------------------------------------------

  test "invalid when the same computer appears twice in the same group" do
    # bob_pdp8 is already in bob_pdp8_vt100 via the bob_pdp8_member fixture
    duplicate = ConnectionMember.new(
      connection_group: connection_groups(:bob_pdp8_vt100),
      computer: computers(:bob_pdp8)
    )
    assert_not duplicate.valid?,
               "Adding the same computer to the same group a second time must be invalid"
    assert duplicate.errors[:computer_id].any?,
           "Uniqueness violation must be reported on :computer_id"
  end

  test "valid when the same computer appears in a different group" do
    # Uniqueness is scoped per group — the same device may be in multiple groups.
    # bob_pdp8 is in bob_pdp8_vt100; adding it to alice_pdp11_vax uses a different
    # connection_group_id, so the uniqueness constraint must not fire.
    # (Cross-owner integrity is enforced at the ConnectionGroup level, not here.)
    member = ConnectionMember.new(
      connection_group: connection_groups(:alice_pdp11_vax),
      computer: computers(:bob_pdp8)  # already in bob_pdp8_vt100, but not in this group
    )
    assert member.valid?,
           "Same computer in a different group must be valid at the member level: #{member.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # after_destroy :cleanup_undersized_group
  # (a) 2-member group: removing 1 → count becomes 1 → group auto-destroys
  # -------------------------------------------------------------------------

  test "auto-destroys parent group when member count falls below 2 (2→1)" do
    # bob_pdp8_vt100 has exactly 2 members. Destroying one drops the count to 1.
    # The after_destroy callback checks group.connection_members.count < 2
    # and calls group.destroy to clean up the now-undersized group.
    group = connection_groups(:bob_pdp8_vt100)
    group_id = group.id

    connection_members(:bob_pdp8_member).destroy

    assert_not ConnectionGroup.exists?(group_id),
               "Group must be auto-destroyed after member count drops from 2 to 1"
  end

  test "auto-destroys parent group when the second of a two-member group is removed" do
    # Alternate path: destroy alice_pdp11_member from alice_pdp11_vax.
    # After first removal (2→1) the after_destroy callback fires and destroys
    # the group; the second member (alice_vax_member) is deleted by delete_all
    # inside the group destroy — we never need to destroy it separately.
    group = connection_groups(:alice_pdp11_vax)
    group_id = group.id

    connection_members(:alice_pdp11_member).destroy

    assert_not ConnectionGroup.exists?(group_id),
               "Group must be auto-destroyed after the first member is removed from a 2-member group"
  end

  # -------------------------------------------------------------------------
  # after_destroy :cleanup_undersized_group
  # (b) 3-member group: removing 1 → count stays at 2 → group must survive
  # -------------------------------------------------------------------------

  test "does not destroy parent group when count drops from 3 to 2" do
    # Alice has three computers that can form a 3-member group:
    #   alice_pdp11, alice_vax, unassigned_condition_test (all owner: one)
    # We create the group inline, destroy one member, and verify the group survives.
    group = ConnectionGroup.create!(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_vax)),
        ConnectionMember.new(computer: computers(:unassigned_condition_test))
      ]
    )
    group_id = group.id
    assert_equal 3, group.connection_members.count,
                 "Test setup: group must have 3 members before removal"

    # Remove one member — count drops to 2, which is >= 2, so no auto-destroy
    group.connection_members.first.destroy

    assert ConnectionGroup.exists?(group_id),
           "Group must NOT be auto-destroyed when member count drops from 3 to 2"
    assert_equal 2, ConnectionGroup.find(group_id).connection_members.count,
                 "Group must have exactly 2 members remaining after the removal"
  end
end
